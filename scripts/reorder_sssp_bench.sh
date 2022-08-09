#!/bin/bash

# How to build:
# cmake  -DESSENTIALS_BUILD_BENCHMARKS=ON -DNVBench_ENABLE_CUPTI=ON ..

# How to run:
# srun -p wario --gpus=1 ./scripts/reorder_tc_bench.sh

# Input
DATASETS_DIR="/data/gunrock/gunrock_dataset/luigi-8TB/large"
BUILD_DIR="./build/bin"
ALGORITHM="sssp"
# BENCHMARK_EXE=${ALGORITHM}'_bench'
BENCHMARK_EXE=${ALGORITHM}
# DATASETS_NAMES=("rgg_n_2_23_s0" "rgg_n_2_22_s0"
#                 "hollywood-2009" "coAuthorsCiteseer" "coAuthorsDBLP"
#                 "delaunay_n24"  "delaunay_n23"  "delaunay_n22"
#                 "great-britain_osm" "road_usa" "arabic-2005"
#                 "soc-LiveJournal1" "ljournal-2008")

# "rgg_n_2_24_s0"
# "roadNet-CA" missing dataset
# DATASETS_NAMES=("delaunay_n10")
DATASETS_NAMES=("delaunay_n22" "road_usa" "rgg_n_2_23_s0" "soc-LiveJournal1" "ljournal-2008" "rgg_n_2_24_s0")
# Output
JSON_DIR="csv/"${ALGORITHM}

ORDERS=("rand" "hub" "chub" "deg" "gorder" "edgeW3")

NCU_ARGS=""
NCU_ARGS="${NCU_ARGS} --section MemoryWorkloadAnalysis --section MemoryWorkloadAnalysis_Tables"
NCU_ARGS="${NCU_ARGS} --replay kernel"
NCU_ARGS="${NCU_ARGS} --cache-control all"
NCU_ARGS="${NCU_ARGS} --kernel-name block_mapped_kernel"
NCU_ARGS="${NCU_ARGS} --apply-rules yes --check-exit-code yes --page raw --csv"


EXEC_PATH=${BUILD_DIR}/${BENCHMARK_EXE}

for dataset in "${DATASETS_NAMES[@]}"
do
    for order in "${ORDERS[@]}"
    do
        mkdir -p ${JSON_DIR}/${order}

        INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.${order}.mtx
        OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.csv

        echo "ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH} --csv ${OUTPUT_FILE}"
        ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH} &> ${OUTPUT_FILE}
    done

    # Algorithms with different naming pattern
    order="write_reorder2"
    mkdir -p ${JSON_DIR}/${order}
    INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${order}_${dataset}.mtx
    OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.csv
    echo "ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH} --csv ${OUTPUT_FILE}"
    ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH} &> ${OUTPUT_FILE}


    order="RCM"
    mkdir -p ${JSON_DIR}/${order}
    INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.mtx.${order}.mtx
    OUTPUT_FILE=${JSON_DIR}/${order}/${dataset}.csv
    echo "ncu ${NCU_ARGS}  ${EXEC_PATH} ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
    ncu ${NCU_ARGS} ${EXEC_PATH} ${INPUT_GRAPH} &> ${OUTPUT_FILE}
done