#!/bin/bash

SCRIPT_NAME=reorder_spmv_bench
srun -p wario --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> csv/${SCRIPT_NAME}.log
