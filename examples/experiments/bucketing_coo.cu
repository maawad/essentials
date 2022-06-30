#include <iostream>  //todo: fix issue in bght
#include "bcht.hpp"

int main(int argc, char** argv) {
  // --
  // Define types
  // Specify the types that will be used for
  // - vertex ids (vertex_t)
  // - edge offsets (edge_t)
  // - edge weights (weight_t)

  using vertex_t = int;
  using edge_t = int;
  using weight_t = float;

  using pair_type = bght::pair<vertex_t, edge_t>;
}