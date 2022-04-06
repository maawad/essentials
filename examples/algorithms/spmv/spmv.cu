#include <gunrock/algorithms/spmv.hxx>
#include <gunrock/algorithms/generate/random.hxx>
#include <gunrock/graph/reorder.hxx>
#include <sys/time.h>

using namespace gunrock;
using namespace memory;

/*double getTime() {                                                         struct timeval tv;                                                      gettimeofday(&tv, 0);                                                   return tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
  } */ 
void test_spmv(int num_arguments, char** argument_array) {
  if (num_arguments != 3) {
    std::cerr << "usage: ./bin/<program-name> reorder filename.mtx" << std::endl;
    exit(1);
  }

  // --
  // Define types
  // Specify the types that will be used for
  // - vertex ids (vertex_t)
  // - edge offsets (edge_t)
  // - edge weights (weight_t)

  using vertex_t = int;
  using edge_t = int;
  using weight_t = float;

  // --
  // IO

  // Filename to be read
  std::string filename = argument_array[2];
  std::string reorder = argument_array[1];
  // Load the matrix-market dataset into csr format.
  // See `format` to see other supported formats.
  io::matrix_market_t<vertex_t, edge_t, weight_t> mm;

  using csr_t =
      format::csr_t<memory_space_t::device, vertex_t, edge_t, weight_t>;
  csr_t csr;
  using coo_t = format::coo_t<memory_space_t::device, vertex_t, edge_t, weight_t>;
  coo_t coo = mm.load(filename);
  coo_t coo2 = coo;

  auto context =
    std::shared_ptr<cuda::multi_context_t>(new cuda::multi_context_t(0));
  graph::reorder::random(coo2,coo,context);
  auto t1 = getTime();
  if(reorder == "reorder")
    graph::reorder::uniquify(coo, coo2, std::shared_ptr<cuda::multi_context_t>(new cuda::multi_context_t(0)));
  //graph::reorder::uniquify2(coo, coo2);
  // graph::reorder::random(coo, coo2);
  //graph::reorder::degree(coo, coo2);
  auto t2 = getTime();
  printf("reorder:%f \n",t2-t1);

  auto tt = getTime();
  csr.from_coo(reorder == "reorder" ? coo2: coo);
  auto tt2 = getTime();
  printf("Building CSR:%f \n",tt2-tt);
  

  // --
  // Build graph

  // Convert the dataset you loaded into an `essentials` graph.
  // `memory_space_t::device` -> the graph will be created on the GPU.
  // `graph::view_t::csr`     -> your input data is in `csr` format.
  //
  // Note that `graph::build::from_csr` expects pointers, but the `csr` data
  // arrays are `thrust` vectors, so we need to unwrap them w/ `.data().get()`.
  auto b1 = getTime();
  auto G = graph::build::from_csr<memory_space_t::device, graph::view_t::csr>(
      csr.number_of_rows, csr.number_of_columns, csr.number_of_nonzeros,
      csr.row_offsets.data().get(), csr.column_indices.data().get(),
      csr.nonzero_values.data().get());

  // --
  // Params and memory allocation
  vertex_t n_vertices = G.get_number_of_vertices();
  thrust::device_vector<weight_t> x(n_vertices);
  thrust::device_vector<weight_t> y(n_vertices);

  gunrock::generate::random::uniform_distribution(x);
  auto b2 = getTime();
  printf("build Graph:%f \n",b2-b1);
  // --
  // GPU Run
  float gpu_elapsed = gunrock::spmv::run(G, x.data().get(), y.data().get());
  
  gunrock::print::head(y, 40, "GPU y-vector");
  std::cout << "GPU Elapsed Time : " << gpu_elapsed << " (ms)" << std::endl;
  
  
}

// Main method, wrapping test function
int main(int argc, char** argv) {
  test_spmv(argc, argv);
}