#!/bin/bash
#!/bin/bash

# How to build:
# cmake  -DESSENTIALS_BUILD_BENCHMARKS=ON -DNVBench_ENABLE_CUPTI=ON ..

# How to run:
# srun -p daisy --gpus=1 ./scripts/reorder_tc_bench.sh

# Input
DATASETS_DIR="/data/gunrock/gunrock_dataset/luigi-8TB/large"
BUILD_DIR="./build/bin"
ALGORITHM="tc"
BENCHMARK_EXE=${ALGORITHM}
DATASETS_NAMES=("rgg_n_2_24_s0" "rgg_n_2_23_s0" "rgg_n_2_22_s0"
                "hollywood-2009" "coAuthorsCiteseer" "coAuthorsDBLP"
                "delaunay_n24"  "delaunay_n23"  "delaunay_n22"
                "great-britain_osm" "road_usa")
# "roadNet-CA" missing dataset
#  "soc-LiveJournal1" "ljournal-2008"
DATASETS_NAMES=("delaunay_n10")

NCU_ARGS=""
NCU_ARGS="${NCU_ARGS} --section ComputeWorkloadAnalysis --section InstructionStats --section LaunchStats --section MemoryWorkloadAnalysis --section MemoryWorkloadAnalysis_Chart --section MemoryWorkloadAnalysis_Deprecated --section MemoryWorkloadAnalysis_Tables --section Occupancy --section SchedulerStats --section SourceCounters --section SpeedOfLight --section SpeedOfLight_RooflineChart --section WarpStateStats"
NCU_ARGS="${NCU_ARGS} --replay kernel"
NCU_ARGS="${NCU_ARGS} --cache-control all"
NCU_ARGS="${NCU_ARGS} --profile-from-start no"
NCU_ARGS="${NCU_ARGS} --apply-rules yes --check-exit-code yes --page raw --csv"


dataset="delaunay_n10"
INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.mtx
EXEC_PATH=${BUILD_DIR}/${BENCHMARK_EXE}

echo ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH}
ncu ${NCU_ARGS} ${EXEC_PATH} -m ${INPUT_GRAPH}




# Output
# JSON_DIR="json/"${ALGORITHM}

# ORDERS=("rand" "hub" "chub" "deg" "gorder" "edgeW3")

# EXEC_PATH=${BUILD_DIR}/${BENCHMARK_EXE}

# for dataset in "${DATASETS_NAMES[@]}"
# do
#     for order in "${ORDERS[@]}"
#     do
#         mkdir -p ${JSON_DIR}/${order}

#         INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.${order}.mtx
#         OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.json

#         echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
#         ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}
#     done

#     # Algorithms with different naming pattern
#     order="write_reorder2"
#     mkdir -p ${JSON_DIR}/${order}
#     INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${order}_${dataset}.mtx
#     OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.json
#     echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
#     ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}


#     order="RCM"
#     mkdir -p ${JSON_DIR}/${order}
#     INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.mtx.${order}.mtx
#     OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.json
#     echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
#     ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}
# done