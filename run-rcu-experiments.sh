#!/bin/bash

session="ncu-experiments"

tmux new-session -d -s $session

window=0
tmux rename-window -t $session:$window 'ncu_sssp'
tmux send-keys -t $session:$window 'source slurm_run_sssp.sh' C-m

window=1
tmux new-window -t $session:$window -n 'ncu_tc'
tmux send-keys -t $session:$window 'source slurm_run_tc.sh' C-m

window=2
tmux new-window -t $session:$window -n 'ncu_pr'
tmux send-keys -t $session:$window 'source slurm_run_pr.sh' C-m

window=3
tmux new-window -t $session:$window -n 'ncu_spmv'
tmux send-keys -t $session:$window 'source slurm_run_spmv.sh' C-m



