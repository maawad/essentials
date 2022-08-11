#!/bin/bash

SCRIPT_NAME=reorder_tc_runtime_bench
# srun -p daisy --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> pareto/${SCRIPT_NAME}.log
srun -p mario --gpus=v100:1 ./scripts/${SCRIPT_NAME}.sh &> pareto/${SCRIPT_NAME}.log
