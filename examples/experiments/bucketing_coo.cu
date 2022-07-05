#include <iostream>  //todo: fix issue in bght
#include <limits>
#include <stdlib.h>

#include "iht.hpp"
#include <cuco/static_multimap.cuh>

#include <thrust/transform.h>
#include <thrust/device_vector.h>
#include <thrust/execution_policy.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/tuple.h>

#include <gunrock/formats/formats.hxx>   // formats (csr, coo)
#include <gunrock/memory.hxx>            // memory space
#include <gunrock/io/matrix_market.hxx>  // matrix_market support
#include <gunrock/util/timer.hxx>

using namespace gunrock;
using namespace memory;

int test_bucketing(int num_arguments, char** argument_array) {
  if (num_arguments != 3) {
    std::cerr << "usage: ./bin/<program-name> filename.mtx load-factor (0 to 1)"
              << std::endl;
    exit(1);
  }
  // --
  // Define types
  // Specify the types that will be used for
  // - vertex ids (vertex_t)
  // - edge offsets (edge_t)
  // - edge weights (weight_t)

  using vertex_t = uint32_t;
  using edge_t = uint32_t;
  using weight_t = float;

  using pair_type = bght::pair<vertex_t, edge_t>;
  using cuco_pair_type = cuco::pair_type<vertex_t, edge_t>;
  std::string filename = argument_array[1];
  float load_factor = std::atof(argument_array[2]);

  // Load the matrix-market dataset into csr format.
  // See `format` to see other supported formats.
  io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
  using coo_t =
      format::coo_t<memory_space_t::device, vertex_t, edge_t, weight_t>;
  coo_t coo = mm.load(filename);

  auto n_edges = coo.number_of_nonzeros;

  std::cout << "Graph: " << filename << std::endl;
  std::cout << "Load factor: " << load_factor << std::endl;
  std::cout << "Number of edges: " << n_edges << std::endl;

  thrust::device_vector<pair_type> coo_as_pairs(n_edges);

  auto to_pair = [=] __device__(const auto& t) {
    return pair_type(thrust::get<0>(t), thrust::get<1>(t));
  };

  // todo: fix policy
  thrust::transform(thrust::device,
                    thrust::make_zip_iterator(thrust::make_tuple(
                        coo.row_indices.begin(), coo.column_indices.begin())),
                    thrust::make_zip_iterator(thrust::make_tuple(
                        coo.row_indices.end(), coo.column_indices.end())),
                    coo_as_pairs.begin(), to_pair);

  // hash table types
  using hash = bght::MurmurHash3_32<vertex_t>;
  using key_equal = bght::equal_to<vertex_t>;
  using allocator = bght::cuda_allocator<char>;
  static constexpr int bucket_size = 16;
  static constexpr int threshold = 14;
  using hash_map =
      bght::iht<vertex_t, vertex_t, hash, key_equal, cuda::thread_scope_device,
                allocator, bucket_size, threshold>;

  using cuco_map = cuco::static_multimap<vertex_t, vertex_t>;

  std::size_t capacity = static_cast<double>(n_edges) / load_factor;

  auto sentinel_key = std::numeric_limits<vertex_t>::max();
  auto sentinel_value = std::numeric_limits<vertex_t>::max();
  // hash_map map(capacity, cuco::sentinel::empty_key{sentinel_key},
  //              cuco::sentinel::empty_value{sentinel_value});
  hash_map map(capacity, sentinel_key, sentinel_value);
  util::timer_t timer;
  timer.begin();
  auto success{true};
  success = map.insert(coo_as_pairs.begin(), coo_as_pairs.end());
  auto elapsed = timer.end();
  if (success) {
    std::cout << "Rate: "
              << static_cast<double>(n_edges) / (elapsed * 0.001) * 1e-6
              << " MEdge/s" << std::endl;
    std::cout << "Elapsed: " << elapsed << " ms" << std::endl;
    std::cout << "succesuflly built the multimap with load factor = "
              << load_factor << std::endl;
    cudaDeviceSynchronize();
  } else {
    std::cout << "failed to build the multimap with load factor = "
              << load_factor << std::endl;
  }
}

// Main method, wrapping test function
int main(int argc, char** argv) {
  test_bucketing(argc, argv);
}