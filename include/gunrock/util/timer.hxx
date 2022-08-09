/**
 * @file timer.hxx
 * @author Muhammad Osama (mosama@ucdavis.edu)
 * @brief Simple timer utility for device side code.
 * @version 0.1
 * @date 2020-10-05
 *
 * @copyright Copyright (c) 2020
 *
 */

#pragma once

#include <chrono>
#include <gunrock/error.hxx>

namespace gunrock {
namespace util {

void flush_cache() {
  const bool flush_l2_cache = true;
  if (flush_l2_cache) {
    int current_device = 0;
    error::throw_if_exception(cudaGetDevice(&current_device));

    int l2_cache_bytes = 0;
    error::throw_if_exception(cudaDeviceGetAttribute(
        &l2_cache_bytes, cudaDevAttrL2CacheSize, current_device));

    if (l2_cache_bytes > 0) {
      const int memset_value = 0;
      int* l2_cache_buffer = nullptr;
      error::throw_if_exception(cudaMalloc(&l2_cache_buffer, l2_cache_bytes));
      error::throw_if_exception(
          cudaMemset(l2_cache_buffer, memset_value, l2_cache_bytes));
      error::throw_if_exception(cudaFree(l2_cache_buffer));
    }
  }
}
struct timer_t {
  float time;

  timer_t() {
    cudaEventCreate(&start_);
    cudaEventCreate(&stop_);
    cudaEventRecord(start_);
  }

  ~timer_t() {
    cudaEventDestroy(start_);
    cudaEventDestroy(stop_);
  }

  // Alias of each other, start the timer.
  void begin() { cudaEventRecord(start_); }
  void start() { this->begin(); }

  // Alias of each other, stop the timer.
  float end() {
    cudaEventRecord(stop_);
    cudaEventSynchronize(stop_);
    cudaEventElapsedTime(&time, start_, stop_);

    return milliseconds();
  }
  float stop() { return this->end(); }

  float seconds() { return time * 1e-3; }
  float milliseconds() { return time; }

 private:
  cudaEvent_t start_, stop_;
};

struct cpu_timer_t {
  float time;

  cpu_timer_t() : time{0.0f}, start_{}, stop_{} {}

  ~cpu_timer_t() {}

  // Alias of each other, start the timer.
  void begin() { start_ = std::chrono::high_resolution_clock::now(); }
  void start() { this->begin(); }

  // Alias of each other, stop the timer.
  float end() {
    stop_ = std::chrono::high_resolution_clock::now();
    time = static_cast<float>(
               std::chrono::duration_cast<std::chrono::microseconds>(stop_ -
                                                                     start_)
                   .count()) /
           1000.f;
    return milliseconds();
  }
  float stop() { return this->end(); }

  float seconds() { return time * 1e-3; }
  float milliseconds() { return time; }

 private:
  using time_t =
      typename std::chrono::time_point<std::chrono::high_resolution_clock>;
  time_t start_, stop_;
};

}  // namespace util
}  // namespace gunrock