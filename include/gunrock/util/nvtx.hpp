#pragma once

#include "nvToolsExt.h"

const uint32_t ___colors[] = {0xff00ff00, 0xff0000ff, 0xffffff00, 0xffff00ff,
                           0xff00ffff, 0xffff0000, 0xffffffff};
const int ___num_colors = sizeof(___colors) / sizeof(uint32_t);

namespace gunrock {
namespace util {

#define USE_NVTX
#ifdef USE_NVTX
#define PUSH_RANGE(name, cid)                          \
  {                                                    \
    int color_id = cid;                                \
    color_id = color_id % ___num_colors;                  \
    nvtxEventAttributes_t eventAttrib = {0};           \
    eventAttrib.version = NVTX_VERSION;                \
    eventAttrib.size = NVTX_EVENT_ATTRIB_STRUCT_SIZE;  \
    eventAttrib.colorType = NVTX_COLOR_ARGB;           \
    eventAttrib.color = ___colors[color_id];              \
    eventAttrib.messageType = NVTX_MESSAGE_TYPE_ASCII; \
    eventAttrib.message.ascii = name;                  \
    nvtxRangePushEx(&eventAttrib);                     \
  }
#define POP_RANGE nvtxRangePop();
#else
#define PUSH_RANGE(name, cid)
#define POP_RANGE
#endif

}  // namespace util

}  // namespace gunrock