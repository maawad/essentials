include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Cloning External Project: BGHT")
get_filename_component(FC_BASE "../externals"
                REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
set(FETCHCONTENT_BASE_DIR ${FC_BASE})

FetchContent_Declare(
  bght
    GIT_REPOSITORY https://github.com/owensgroup/BGHT.git
    GIT_TAG        essentials
)

FetchContent_GetProperties(BGHT)
if(NOT BGHT_POPULATED)
  FetchContent_Populate(
    bght
  )
endif()

# Exposing BGHT's source and include directory
set(BGHT_INCLUDE_DIR "${bght_SOURCE_DIR}/include")


FetchContent_Declare(
  cuco
    GIT_REPOSITORY https://github.com/NVIDIA/cuCollections.git
    GIT_TAG        dev
)

FetchContent_GetProperties(cuco)
if(NOT CUCO_POPULATED)
  FetchContent_Populate(
    cuco
  )
endif()

# Exposing cuCollections's source and include directory
set(CUCO_INCLUDE_DIR "${cuco_SOURCE_DIR}/include")