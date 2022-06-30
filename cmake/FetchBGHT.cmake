include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message(STATUS "Cloning External Project: BGHT")
get_filename_component(FC_BASE "../externals"
                REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
set(FETCHCONTENT_BASE_DIR ${FC_BASE})

FetchContent_Declare(
  bght
    GIT_REPOSITORY https://github.com/owensgroup/BGHT.git
    GIT_TAG        main
)

FetchContent_GetProperties(BGHT)
if(NOT BGHT_POPULATED)
  FetchContent_Populate(
    bght
  )
endif()

# Exposing BGHT's source and include directory
message(PROJECT_SOURCE_DIR="${bght_SOURCE_DIR}")
set(BGHT_INCLUDE_DIR "${bght_SOURCE_DIR}/include")