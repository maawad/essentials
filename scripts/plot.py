
import argparse
import sys
import collections
import json

from os import listdir
from os.path import isfile, isdir, join, splitext


def extract_data_from_json(json_file_path, queries):
    file = open(json_file_path)
    loaded_json = json.load(file)
    results = [0] * len(queries)
    for field in loaded_json['benchmarks'][0]['states'][0]['summaries']:
        for q in queries:
            if(field['name'] == q):
                queries[q] = field['data'][0]['value']

    return queries


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-id', '--input-dir', default='./json')
    parser.add_argument('-od', '--output-dir', default='./figures')
    parser.add_argument('-my', '--min-y', default=-1, type=int)
    parser.add_argument('-xy', '--max-y', default=-1, type=int)

    args = parser.parse_args()
    print("Reading results from: ", args.input_dir)

    graph_algorithms = [d for d in listdir(args.input_dir)
                        if isdir(join(args.input_dir, d))]

    for graph_algo in graph_algorithms:
        cur_dir = join(args.input_dir, graph_algo)
        reorder_algorithms = [d for d in listdir(cur_dir)
                              if isdir(join(cur_dir, d))]
        json_inputs = dict()

        for reorder_algo in reorder_algorithms:
            json_dir = join(cur_dir, reorder_algo)
            graphs = [f for f in listdir(json_dir)
                      if isfile(join(json_dir, f))]
            for graph in graphs:
                print(extract_data_from_json(
                    join(json_dir, graph), {'HBWPeak': 0}))
            print(json_dir)
            print(graphs)

        print(graph_algo)
        print(reorder_algorithms)
