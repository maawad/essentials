#!/bin/bash

dataset="arabic-2005"
# dataset="hollywood-2009"

nsys profile -o ${dataset}_orig ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.mtx
nsys profile -o ${dataset}_rand ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.rand.mtx
nsys profile -o ${dataset}_rcm ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.mtx.RCM.mtx
nsys profile -o ${dataset}_gorder ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.gorder.mtx
nsys profile -o ${dataset}_write_reorder2 ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/write_reorder2_${dataset}.mtx
nsys profile -o ${dataset}_write_reorder_rand ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/write_reorderRand_${dataset}.mtx
nsys profile -o ${dataset}_edgeW3 ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.edgeW3.mtx
nsys profile -o ${dataset}_edgeW2 ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.edgeW2.mtx
nsys profile -o ${dataset}_chub ./build/bin/mgpu_boba -m /data/gunrock/gunrock_dataset/luigi-8TB/large/${dataset}/${dataset}.chub.mtx
