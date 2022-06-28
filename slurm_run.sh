SCRIPT_NAME=reorder_tc_bench
srun -p wario --gpus=1 ./scripts/${SCRIPT_NAME}.sh &> json/${SCRIPT_NAME}.log
