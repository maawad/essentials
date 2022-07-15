
import argparse
import sys
import collections
import json
import altair as alt
import pandas as pd


from os import listdir
from os.path import isfile, isdir, join, splitext
from pprint import pp
import matplotlib.pyplot as plt


def extract_data_from_json(json_file_path, queries):
    # print(json_file_path)
    print(json_file_path)
    file = open(json_file_path)
    loaded_json = json.load(file)
    results = [0] * len(queries)

    for field in loaded_json['benchmarks'][0]['states'][0]['summaries']:
        for q in queries:
            if(field['name'] == q):
                queries[q] = float(field['data'][0]['value']) * 100
    return queries


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-id', '--input-dir', default='./json')
    parser.add_argument('-od', '--output-dir', default='./figures')
    parser.add_argument('-my', '--min-y', default=-1, type=int)
    parser.add_argument('-xy', '--max-y', default=-1, type=int)
    parser.add_argument('-alg', '--algorithms', default='tc')

    args = parser.parse_args()
    print("Reading results from: ", args.input_dir)

    graph_algorithms = [d for d in listdir(args.input_dir)
                        if isdir(join(args.input_dir, d))]
    width = 20
    height = 4
    metrics = ['L1HitRate',
               'L2HitRate',
               'LoadEff']
    results_dfs = {}
    results_dfs['L1HitRate'] = pd.DataFrame()
    results_dfs['L2HitRate'] = pd.DataFrame()
    results_dfs['HBWPeak'] = pd.DataFrame()
    results_dfs['LoadEff'] = pd.DataFrame()
    #
    graphs_order = {}
    sort_by = 'avg_deg'
    # average degree
    if sort_by == 'avg_deg':
        graphs_order['coAuthorsCiteseer'] = 7
        graphs_order['coAuthorsDBLP'] = 6
        graphs_order['delaunay_n22'] = 5.1
        graphs_order['delaunay_n23'] = 5.2
        graphs_order['delaunay_n24'] = 5.3
        graphs_order['great-britain_osm'] = 1
        graphs_order['hollywood-2009'] = 50
        graphs_order['rgg_n_2_22_s0'] = 14
        graphs_order['rgg_n_2_23_s0'] = 15.1
        graphs_order['rgg_n_2_24_s0'] = 15.2
        graphs_order['roadNet-CA'] = 2.1
        graphs_order['road_usa'] = 2.2
        graphs_order['soc-LiveJournal1'] = 14.2326482686
        graphs_order['ljournal-2008'] = 14.7343241471
    elif sort_by == 'std_dev_deg':
        graphs_order['coAuthorsCiteseer'] = 10.631268501281739
        graphs_order['coAuthorsDBLP'] = 9.797412872314454
        graphs_order['delaunay_n22'] = 1.3363832235336304
        graphs_order['delaunay_n23'] = 1.3359977006912232
        graphs_order['delaunay_n24'] = 1.3290655612945557
        graphs_order['great-britain_osm'] = 0.5356237888336182
        graphs_order['hollywood-2009'] = 271.6954040527344
        graphs_order['rgg_n_2_22_s0'] = 3.8282036781311037
        graphs_order['rgg_n_2_23_s0'] = 3.8572041988372804
        graphs_order['rgg_n_2_24_s0'] = 3.86275577545166
        graphs_order['roadNet-CA'] = 0.9984461665153503
        graphs_order['road_usa'] = 0.8779882192611694
        graphs_order['soc-LiveJournal1'] = 50.55318832397461
        graphs_order['ljournal-2008'] = 14.7343241471

    reorder_algorithms_ = {}
    for metric in metrics:
        metric_df = pd.DataFrame()
        for graph_algo in graph_algorithms:
            if args.algorithms == 'all' or graph_algo == args.algorithms:
                cur_dir = join(args.input_dir, graph_algo)
                reorder_algorithms = [d for d in listdir(cur_dir)
                                      if isdir(join(cur_dir, d))]
                reorder_algorithms_ = reorder_algorithms
                for reorder_algo in reorder_algorithms:
                    json_dir = join(cur_dir, reorder_algo)
                    graphs = [f for f in listdir(json_dir)
                              if isfile(join(json_dir, f))]
                    graphs.sort(key=lambda x: graphs_order[splitext(x)[0]])
                    graphs_results = {}
                    for graph in graphs:
                        graph_name = splitext(graph)[0]
                        graphs_results[graph_name] = extract_data_from_json(
                            join(json_dir, graph), {metric: 0})[metric]

                    # print(graphs_results)
                    df = pd.DataFrame.from_dict(
                        graphs_results, orient='index', columns=[reorder_algo])
                    # .items(), columns = ['datasets', reorder_algo]
                    # print(df)
                    metric_df[reorder_algo] = df
                metric_df.rename_axis('dataset').reset_index()
                results_dfs[metric] = metric_df.rename_axis(
                    'dataset').reset_index()

                # alt.Chart(graphs_results).mark_points().encode(x=[''])
                # plt.title(graph_algo.upper() + ' ' + metric)

                # pp(reorder_algo_results, depth=2)
                # plt.legend()
                # plt.savefig(graph_algo + '_' + metric +
                #             '_' + 'by_' + sort_by + '.png')
    #     print(json_dir)
    #     print(graphs)

    # print(graph_algo)
    # print(reorder_algorithms)
    # pp(results_dfs)
    # results_dfs.reset_index(inplace=True)
    # print(L1HitRate_df)
    for i, metric in zip(range(0, len(metrics)), metrics):
        chart = alt.Chart(results_dfs[metric]).transform_fold(as_=["Reorder Algorithm", metric], fold=reorder_algorithms_).mark_line(point=alt.OverlayMarkDef(filled=False, fill='white')).encode(
            alt.X('dataset'), alt.Y(metric + ':Q', title=metric + " (%)"),  color='Reorder Algorithm:N')
        chart_fname = args.algorithms + '_' + metric + '_' + 'by_' + sort_by + '.svg'
        print(chart_fname)
        chart.save(chart_fname)

        # chart = alt.Chart(results_dfs[metric]).mark_point().encode(
        #     alt.X('index'), alt.Y('gorder'),  alt.Color('Origin', type='nominal'))
        # chart_fname = args.algorithms + '_' + metric + '_' + 'by_' + sort_by + '.svg'
        # print(chart_fname)
        # chart.save(chart_fname)
