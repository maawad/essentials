#!/bin/bash

# How to build:
# cmake  -DESSENTIALS_BUILD_BENCHMARKS=ON -DNVBench_ENABLE_CUPTI=ON ..

# How to run:
# srun -p wario --gpus=1 ./scripts/reorder_tc_bench.sh

# Input
DATASETS_DIR="/data/gunrock/gunrock_dataset/luigi-8TB/large"
BUILD_DIR="./build/bin"
BENCHMARK_EXE="tc_bench"
DATASETS_NAMES=("rgg_n_2_24_s0" "rgg_n_2_23_s0" "rgg_n_2_22_s0"
                    "hollywood-2009" "coAuthorsCiteseer" "coAuthorsDBLP"
                    "delaunay_n24"  "delaunay_n23"  "delaunay_n22"
                    "great-britain_osm" "road_usa" "roadNet-CA")
# DATASETS_NAMES=("delaunay_n10")

# Output
JSON_DIR="json/"${BENCHMARK_EXE}

ORDERS=("rand" "hub" "chub" "deg" "gorder" "edgeW3")

EXEC_PATH=${BUILD_DIR}/${BENCHMARK_EXE}

for dataset in "${DATASETS_NAMES[@]}"
do
    for order in "${ORDERS[@]}"
    do
        mkdir -p ${JSON_DIR}/${order}

        INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.${order}.mtx
        OUTPUT_FILE=${JSON_DIR}/${order}/${BENCHMARK_EXE}_${dataset}.json

        echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
        ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}
    done

    # Algorithms with different naming pattern
    order="write_reorder2"
    mkdir -p ${JSON_DIR}/${order}
    INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${order}_${dataset}.mtx
    OUTPUT_FILE=${JSON_DIR}/${order}/${BENCHMARK_EXE}_${dataset}.json
    echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
    ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}


    order="RCM"
    mkdir -p ${JSON_DIR}/${order}
    INPUT_GRAPH=${DATASETS_DIR}/${dataset}/${dataset}.mtx.${order}.mtx
    OUTPUT_FILE=${JSON_DIR}/${order}/${BENCHMARK_EXE}_${dataset}.json
    echo "${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}"
    ${EXEC_PATH} -m ${INPUT_GRAPH} --json ${OUTPUT_FILE}
done