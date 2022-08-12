#!/bin/bash

SCRIPT_NAME=reorder_tc_bench
srun -p daisy --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> csv/${SCRIPT_NAME}.log
# srun -p mario --gpus=v100:1 ./scripts/${SCRIPT_NAME}.sh &> csv/${SCRIPT_NAME}.log
