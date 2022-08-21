#include <vector>

#include <gunrock/algorithms/tc.hxx>
#include <gunrock/util/timer.hxx>

#include <cxxopts.hpp>

using namespace gunrock;
using namespace memory;

#define cuda_try(call)                                        \
  do {                                                        \
    cudaError_t err = call;                                   \
    if (err != cudaSuccess) {                                 \
      printf("CUDA error at %s %d: %s\n", __FILE__, __LINE__, \
             cudaGetErrorString(err));                        \
      std::terminate();                                       \
    }                                                         \
  } while (0)

template <class T>
struct managed_allocator {
  typedef std::size_t size_type;
  typedef std::ptrdiff_t difference_type;

  typedef T value_type;
  typedef T* pointer;
  typedef const T* const_pointer;
  typedef T& reference;
  typedef const T& const_reference;

  template <class U>
  struct rebind {
    typedef managed_allocator<U> other;
  };
  managed_allocator() = default;
  template <class U>
  constexpr managed_allocator(const managed_allocator<U>&) noexcept {}
  T* allocate(std::size_t n) {
    void* p = nullptr;
    cuda_try(cudaMallocManaged(&p, n * sizeof(T)));
    return static_cast<T*>(p);
  }
  void deallocate(T* p, std::size_t) noexcept { cuda_try(cudaFree(p)); }
};

struct parameters_t {
  std::string filename;
  cxxopts::Options options;
  bool validate;
  bool reduce_all_triangles;

  /**
   * @brief Construct a new parameters object and parse command line arguments.
   *
   * @param argc Number of command line arguments.
   * @param argv Command line arguments.
   */
  parameters_t(int argc, char** argv)
      : options(argv[0], "Traingle Counting example") {
    // Add command line options
    options.add_options()("help", "Print help")(
        "validate", "CPU validation",
        cxxopts::value<bool>()->default_value("false"))(
        "m,market", "Matrix file", cxxopts::value<std::string>())(
        "r,reduce",
        "Compute a single triangle count for the entire graph (default = "
        "false)",
        cxxopts::value<bool>()->default_value("false"));

    // Parse command line arguments
    auto result = options.parse(argc, argv);

    if (result.count("help") || (result.count("market") == 0)) {
      std::cout << options.help({""}) << std::endl;
      std::exit(0);
    }
    filename = result["market"].as<std::string>();
    validate = result["validate"].as<bool>();
    reduce_all_triangles = result["reduce"].as<bool>();
  }
};

__global__ void average_neighbors(uint32_t* row_offsets,
                                  uint32_t* column_indices,
                                  uint32_t n_vertices,
                                  uint32_t* output,
                                  uint32_t gpu_offset_start,
                                  uint32_t gpu_offset_end) {
  auto vertex_index = threadIdx.x + blockIdx.x * blockDim.x;
  vertex_index += gpu_offset_start;

  if (vertex_index < gpu_offset_end) {
    auto row_start = row_offsets[vertex_index];
    auto row_end = row_offsets[vertex_index + 1];
    auto n_neighbors = row_end - row_start;

    uint32_t sum = 0;
    for (uint32_t n = 0; n < n_neighbors; n++) {
      sum += column_indices[row_start + n];
    }
    output[vertex_index] = sum;
  }
}

void test_tc(int num_arguments, char** argument_array) {
  // --
  // Define types

  using vertex_t = uint32_t;
  using edge_t = uint32_t;
  using weight_t = float;
  using count_t = vertex_t;

  using csr_t =
      format::csr_t<memory_space_t::device, vertex_t, edge_t, weight_t>;
  csr_t csr;

  // --
  // IO
  parameters_t params(num_arguments, argument_array);

  if (util::is_market(params.filename)) {
    io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
    auto mmatrix = mm.load(params.filename);
    if (!mm_is_symmetric(mm.code)) {
      // std::cerr << "Error: input matrix must be symmetric" << std::endl;
      // exit(1);
    }
    csr.from_coo(mmatrix);
  } else if (util::is_binary_csr(params.filename)) {
    csr.read_binary(params.filename);
  } else {
    std::cerr << "Unknown file format: " << params.filename << std::endl;
    exit(1);
  }

  // --
  // Build graph

  auto G = graph::build::from_csr<memory_space_t::device,
                                  graph::view_t::csr>(
      csr.number_of_rows,               // rows
      csr.number_of_columns,            // columns
      csr.number_of_nonzeros,           // nonzeros
      csr.row_offsets.data().get(),     // row_offsets
      csr.column_indices.data().get(),  // column_indices
      csr.nonzero_values.data().get()   // values
  );

  // --
  // Params and memory allocation

  vertex_t n_vertices = G.get_number_of_vertices();

  using allocator_type = managed_allocator<vertex_t>;

  thrust::device_vector<vertex_t, allocator_type> mgpu_row_offsets(
      csr.row_offsets);
  thrust::device_vector<vertex_t, allocator_type> mgpu_column_indices(
      csr.column_indices);
  thrust::device_vector<vertex_t, allocator_type> output(n_vertices, 0);

  uint32_t num_gpus = 4;
  auto vertices_per_gpu = n_vertices / num_gpus;

  auto mgpu_row_offsets_raw = mgpu_row_offsets.data();
  auto mgpu_column_indices_raw = mgpu_column_indices.data();
  auto output_raw = output.data();

  cuda_try(cudaDeviceSynchronize());

  // enable peer access
  for (int i = 0; i < num_gpus; i++) {
    cudaSetDevice(i);
    for (int j = 0; j < num_gpus; j++) {
      if (i == j)
        continue;
      cudaDeviceEnablePeerAccess(j, 0);
    }
  }

  std::cout << "Launching kernels..." << std::endl;
  float total_time = 0;
  std::size_t num_experiments = 100;
  for (std::size_t exp = 0; exp < num_experiments; exp++) {
    std::vector<std::thread> threads;

    // std::cout << "Experiment " << exp << std::endl;
    cuda_try(cudaDeviceSynchronize());

    util::timer_t timer;
    timer.begin();
    for (uint32_t gpu_idx = 0; gpu_idx < num_gpus; gpu_idx++) {
      std::thread t([=] {
        // set gpu
        // std::cout << "Setting GPU " << gpu_idx << std::endl;
        cuda_try(cudaSetDevice(gpu_idx));

        // offsets
        auto v_start = vertices_per_gpu * gpu_idx;
        auto v_end = std::min(vertices_per_gpu * (gpu_idx + 1), n_vertices);
        auto v_size = v_end - v_start;
        // std::cout << gpu_idx << ": " << v_start << std::endl;
        // std::cout << gpu_idx << ": " << v_end << std::endl;
        // std::cout << gpu_idx << ": " << v_size << std::endl;
        // std::cout << gpu_idx << ": " << n_vertices << std::endl;

        // launch kernel
        const uint32_t block_size = 128;
        const uint32_t num_blocks = (v_size + block_size - 1) / block_size;
        average_neighbors<<<num_blocks, block_size>>>(
            mgpu_row_offsets_raw, mgpu_column_indices_raw, n_vertices,
            output_raw, v_start, v_end);
        cuda_try(cudaDeviceSynchronize());
      });
      threads.push_back(std::move(t));
    }

    // join
    for (auto& t : threads) {
      t.join();
    }
    cuda_try(cudaDeviceSynchronize());
    auto elapsed = timer.end();
    total_time += elapsed;
  }

  std::cout << "Elapsed (ms): " << total_time / float(num_experiments)
            << std::endl;
}

int main(int argc, char** argv) {
  test_tc(argc, argv);
}
