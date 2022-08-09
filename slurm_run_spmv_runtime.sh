#!/bin/bash

SCRIPT_NAME=reorder_spmv_runtime_bench
srun -p wario --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> pareto/${SCRIPT_NAME}.log
