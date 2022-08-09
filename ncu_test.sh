ncu --section MemoryWorkloadAnalysis --section MemoryWorkloadAnalysis_Tables --replay application --cache-control all --profile-from-start no --apply-rules yes --check-exit-code yes --page raw --csv ./build/bin/sssp /data/gunrock/gunrock_dataset/luigi-8TB/large/rgg_n_2_23_s0/rgg_n_2_23_s0.mtx
# &> test.csv

# compute-sanitizer
# --section ComputeWorkloadAnalysis
#  --section InstructionStats --section LaunchStats --section MemoryWorkloadAnalysis --section MemoryWorkloadAnalysis_Chart --section MemoryWorkloadAnalysis_Deprecated --section MemoryWorkloadAnalysis_Tables --section Occupancy --section SchedulerStats --section SourceCounters --section SpeedOfLight --section SpeedOfLight_RooflineChart --section WarpStateStats