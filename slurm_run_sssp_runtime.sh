#!/bin/bash

SCRIPT_NAME=reorder_sssp_runtime_bench
srun -p daisy --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> pareto/${SCRIPT_NAME}.log
