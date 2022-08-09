#include <vector>

#include <gunrock/algorithms/tc.hxx>
#include "tc_cpu.hxx"

#include <cxxopts.hpp>

#include <nlohmann/json.hpp>

using namespace gunrock;
using namespace memory;

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

  float sort_time{0.0f};
  float convert_time{0.0f};
  if (util::is_market(params.filename)) {
    io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
    auto mmatrix = mm.load(params.filename);
    if (!mm_is_symmetric(mm.code)) {
      std::cerr << "Error: input matrix must be symmetric" << std::endl;
      // exit(1);
    }
    util::timer_t sort_timer;
    sort_timer.begin();
    mmatrix.sort();
    sort_time = sort_timer.end();

    util::timer_t convert_timer;
    convert_timer.begin();
    csr.from_coo(mmatrix, single_source);
    convert_time = convert_timer.stop();
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

  // --
  // GPU Run
  const int num_experiments = 10;
  double gpu_elapsed = 0.0;
  std::size_t total_triangles_ = 0;

  for (auto exp = 0; exp < num_experiments; exp++) {
    std::size_t total_triangles = 0;
    thrust::device_vector<count_t> triangles_count(n_vertices, 0);
    util::flush_cache();
    auto exp_gpu_elapsed =
        tc::run(G, params.reduce_all_triangles, triangles_count.data().get(),
                &total_triangles);

    total_triangles_ = total_triangles;
    gpu_elapsed += exp_gpu_elapsed;
    // std::cout << exp << " :" << exp_gpu_elapsed << std::endl;
  }
  gpu_elapsed /= double(num_experiments);

  using json = nlohmann::json;

  std::string app_name = "tc";
  std::string graph_name = std::filesystem::path(params.filename).stem();
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
  record["num-triangles"] = total_triangles_;
  output << record << "\n";
  std::cout << record << "\n";

  return;
  // --
  // Log

  // print::head(triangles_count, 40, "Per-vertex triangle count");
  // if (params.reduce_all_triangles) {
  //   std::cout << "Total Graph Traingles : " << total_triangles << std::endl;
  // }
  // std::cout << "GPU Elapsed Time : " << gpu_elapsed << " (ms)" << std::endl;

  // // --
  // // CPU validation
  // if (params.validate) {
  //   std::vector<count_t> reference_triangles_count(n_vertices, 0);
  //   std::size_t reference_total_triangles = 0;

  //   float cpu_elapsed =
  //       tc_cpu::run(csr, reference_triangles_count,
  //       reference_total_triangles);
  //   uint32_t n_errors = 0;
  //   if (total_triangles != reference_total_triangles) {
  //     std::cout << "Error: Total TC mismatch: " << total_triangles
  //               << "! = " << reference_total_triangles << std::endl;
  //     n_errors++;
  //   }
  //   n_errors += util::compare(
  //       triangles_count.data().get(), reference_triangles_count.data(),
  //       n_vertices, [](const auto x, const auto y) { return x != y; }, true);
  //   std::cout << "CPU Elapsed Time : " << cpu_elapsed << " (ms)" <<
  //   std::endl; std::cout << "Number of errors : " << n_errors << std::endl;
  // }
}

int main(int argc, char** argv) {
  test_tc(argc, argv);
}
