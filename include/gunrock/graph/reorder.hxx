#pragma once
#include <gunrock/cuda/cuda.hxx>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/generate.h>
#include <thrust/reduce.h>
#include <thrust/functional.h>
#include <thrust/random.h>
#include <stdio.h>
#include <gunrock/formats/coo.hxx>

namespace gunrock {
namespace graph {
namespace reorder {

struct is_pad {
  __host__ __device__ bool operator()(const int& x) const { return x == -1; }
};

template <typename coo_device_t>
void uniquify(coo_device_t& G,
              coo_device_t& rG,
              std::shared_ptr<cuda::multi_context_t> context) {
  std::shared_ptr<cuda::standard_context_t> scontext =
      std::shared_ptr<cuda::standard_context_t>(context->get_context(0));
  int M = G.number_of_nonzeros;
  int N = G.number_of_rows;
  int MM = 2 * M;
  thrust::device_vector<int> dkeys(N);
  thrust::device_vector<int> zp(MM, -1);
  auto I = thrust::raw_pointer_cast(G.row_indices.data());
  auto J = thrust::raw_pointer_cast(G.column_indices.data());

  auto rI = thrust::raw_pointer_cast(rG.row_indices.data());
  auto rJ = thrust::raw_pointer_cast(rG.column_indices.data());

  int* pk = thrust::raw_pointer_cast(dkeys.data());
  int* p = thrust::raw_pointer_cast(zp.data());

  auto make_keys = [=] __device__(int const& tid, int const& bid) {
    if (tid < M)
      pk[I[tid]] = pk[I[tid]] > tid ? tid : pk[I[tid]];
    else {
      pk[J[tid - M]] = pk[J[tid - M]] > tid ? tid : pk[J[tid - M]];
    }
  };

  auto make_zperm = [=] __device__(int const& tid, int const& bid) {
    p[pk[tid]] = tid;
  };

  using namespace cuda::launch_box;
  using launch_t =
      launch_box_t<launch_params_dynamic_grid_t<fallback, dim3_t<256>, 3>>;
  launch_t l;

  l.launch_blocked(*scontext, make_keys, (std::size_t)M);
  scontext->synchronize();

  l.launch_blocked(*scontext, make_zperm, (std::size_t)N);
  scontext->synchronize();

  zp.erase(thrust::remove_if(zp.begin(), zp.end(), is_pad()), zp.end());

  auto z = thrust::raw_pointer_cast(zp.data());

  thrust::device_vector<int> iz(N);
  auto izp = thrust::raw_pointer_cast(iz.data());

  auto inverse = [=] __device__(int const& tid, int const& bid) {
    izp[z[tid]] = tid;
  };
  auto permute = [=] __device__(int const& tid, int const& bi) {
    rI[tid] = izp[rI[tid]];
    rJ[tid] = izp[rJ[tid]];
  };

  l.launch_blocked(*scontext, inverse, (std::size_t)N);
  scontext->synchronize();

  l.launch_blocked(*scontext, permute, (std::size_t)N);
  scontext->synchronize();
}
}  // namespace reorder
}  // namespace graph
}  // namespace gunrock