#!/bin/bash

SCRIPT_NAME=reorder_pr_bench
srun -p daisy --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> csv/${SCRIPT_NAME}.log