#include <gunrock/algorithms/pr.hxx>

#include <nlohmann/json.hpp>

using namespace gunrock;
using namespace memory;

void test_pr(int num_arguments, char** argument_array) {
  if (num_arguments != 2) {
    std::cerr << "usage: ./bin/<program-name> filename.mtx" << std::endl;
    exit(1);
  }

  // --
  // Define types

  using vertex_t = int;
  using edge_t = int;
  using weight_t = float;

  using csr_t =
      format::csr_t<memory_space_t::device, vertex_t, edge_t, weight_t>;
  csr_t csr;

  // --
  // IO

  std::string filename = argument_array[1];

  float sort_time{0.0f};
  float convert_time{0.0f};
  vertex_t single_source = 0;  // rand() % n_vertices;

  if (util::is_market(filename)) {
    io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
    auto mmatrix = mm.load(filename);
    util::timer_t sort_timer;
    sort_timer.begin();
    mmatrix.sort();
    sort_time = sort_timer.end();

    util::timer_t convert_timer;
    convert_timer.begin();
    csr.from_coo(mmatrix, single_source);
    convert_time = convert_timer.stop();
  } else if (util::is_binary_csr(filename)) {
    csr.read_binary(filename);
  } else {
    std::cerr << "Unknown file format: " << filename << std::endl;
    exit(1);
  }

  // --
  // Build graph

  auto G = graph::build::from_csr<memory_space_t::device, graph::view_t::csr>(
      csr.number_of_rows,               // rows
      csr.number_of_columns,            // columns
      csr.number_of_nonzeros,           // nonzeros
      csr.row_offsets.data().get(),     // row_offsets
      csr.column_indices.data().get(),  // column_indices
      csr.nonzero_values.data().get()   // values
  );  // supports row_indices and column_offsets (default = nullptr)

  // --
  // Params and memory allocation

  srand(time(NULL));

  weight_t alpha = 0.85;
  weight_t tol = 1e-6;

  vertex_t n_vertices = G.get_number_of_vertices();
  thrust::device_vector<weight_t> p(n_vertices);

  // --
  // GPU Run

  const int num_experiments = 10;
  double gpu_elapsed = 0.0;
  for (auto exp = 0; exp < num_experiments; exp++) {
    thrust::device_vector<weight_t> p(n_vertices);
    util::flush_cache();
    auto this_run = gunrock::pr::run(G, alpha, tol, p.data().get());
    gpu_elapsed += this_run;
  }
  gpu_elapsed /= float(num_experiments);

  using json = nlohmann::json;

  std::string app_name = "pr";
  std::string graph_name = std::filesystem::path(filename).stem();
  std::string output_dir = "pareto/";
  std::string fname =
      output_dir + app_name + std::string("_") + graph_name + ".json";
  std::fstream output(fname, std::ios::app);

  json record;
  record["graph_name"] = graph_name;
  record["M"] = G.get_number_of_edges();
  record["N"] = G.get_number_of_vertices();
  record["run-time"] = gpu_elapsed;
  record["sort-time"] = sort_time;
  record["convert-time"] = convert_time;
  output << record << "\n";
  std::cout << record << "\n";

  return;
  // --
  // Log + Validate
  // print::head(p, 40, "GPU rank");

  // std::cout << "GPU Elapsed Time : " << gpu_elapsed << " (ms)" << std::endl;
}

int main(int argc, char** argv) {
  test_pr(argc, argv);
}