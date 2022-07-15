
import argparse
from multiprocessing.spawn import prepare
import sys
import collections
import json
import altair as alt
from matplotlib import scale
import pandas as pd
import numpy as np
import subprocess


from os import listdir
from os.path import isfile, isdir, join, splitext
from pprint import pp
import matplotlib.pyplot as plt


def vl2img(vl_json_in, fileformat):
    """Pipes the vega-lite json through vl2vg then vg2xxx to generate an image
        Returns: output of vg2xxx"""

    # TODO would prefer to do this properly with pipes
    # using | and shell=True is safe though given no arguments
    executables = {"svg": "vg2svg", "png": "vg2png", "pdf": "vg2pdf"}
    try:
        exe = executables[fileformat]
    except KeyError as e:
        print(e.output)
    try:
        return subprocess.check_output("vl2vg | %s" % exe, shell=True, input=vl_json_in)
    except subprocess.CalledProcessError as e:
        print(e.output)


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


def compute_sectors_total(csv):
    # L1
    hits = csv['l1tex__t_sectors_pipe_lsu_mem_local_op_ld_lookup_hit.sum'][1:].str.replace(
        ',', '').astype(float)
    hits += csv['l1tex__t_sectors_pipe_lsu_mem_global_op_ld_lookup_hit.sum'][1:].str.replace(
        ',', '').astype(float)
    hits += csv['l1tex__t_sectors_pipe_tex_mem_surface_op_ld_lookup_hit.sum'][1:].str.replace(
        ',', '').astype(float)
    hits += csv['l1tex__t_sectors_pipe_tex_mem_texture_lookup_hit.sum'][1:].str.replace(
        ',', '').astype(float)
    total = np.sum(hits)

    # L2
    hits = csv['lts__t_sectors_srcunit_tex_op_read_lookup_hit.sum'][1:].str.replace(
        ',', '').astype(float)
    total += np.sum(hits)

    # Dram
    hits = csv['dram__sectors_read.sum'][1:].str.replace(',', '').astype(float)
    total += np.sum(hits)
    return total


def extract_data_from_csv(csv_file_path, queries):
    print(csv_file_path)
    skip = 3
    if 'spmv' in csv_file_path or 'pr' in csv_file_path:
        skip = 2
    csv = pd.read_csv(csv_file_path, skiprows=skip)
    # while skip < 20:
    #     try:
    #         csv = pd.read_csv(csv_file_path, skiprows=skip)
    #     except:
    #         skip += 1
    #         print("Trying to read the file again")
    # print("Reading file..")
    for q in queries:
        if q == 'L1ReadHitRate':
            hits = csv['l1tex__t_sectors_pipe_lsu_mem_local_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_lsu_mem_global_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_tex_mem_surface_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_tex_mem_texture_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)

            misses = csv['l1tex__t_sectors_pipe_lsu_mem_local_op_ld_lookup_miss.sum'][1:].str.replace(
                ',', '').astype(float)
            misses += csv['l1tex__t_sectors_pipe_lsu_mem_global_op_ld_lookup_miss.sum'][1:].str.replace(
                ',', '').astype(float)
            misses += csv['l1tex__t_sectors_pipe_tex_mem_surface_op_ld_lookup_miss.sum'][1:].str.replace(
                ',', '').astype(float)
            misses += csv['l1tex__t_sectors_pipe_tex_mem_texture_lookup_miss.sum'][1:].str.replace(
                ',', '').astype(float)
            total_hits = np.sum(hits)
            total_misses = np.sum(misses)
            queries[q] = total_hits / (total_hits + total_misses) * 100.0

        if q == 'L2ReadHitRate':
            hits = csv['lts__t_sectors_srcunit_tex_op_read_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            misses = csv['lts__t_sectors_srcunit_tex_op_read_lookup_miss.sum'][1:].str.replace(
                ',', '').astype(float)
            total_hits = np.sum(hits)
            total_misses = np.sum(misses)
            queries[q] = total_hits / (total_hits + total_misses) * 100.0

        if q == 'L1Sectors':
            hits = csv['l1tex__t_sectors_pipe_lsu_mem_local_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_lsu_mem_global_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_tex_mem_surface_op_ld_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            hits += csv['l1tex__t_sectors_pipe_tex_mem_texture_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            total_hits = np.sum(hits)
            total_sectors = compute_sectors_total(csv)
            # print("total_hits: ", total_hits)
            # print("total_sectors: ", total_sectors)
            # print("ratio: ", total_hits / total_sectors * 100)

            queries[q] = total_hits / total_sectors * 100.0

        if q == 'L2Sectors':
            hits = csv['lts__t_sectors_srcunit_tex_op_read_lookup_hit.sum'][1:].str.replace(
                ',', '').astype(float)
            total_hits = np.sum(hits)
            total_sectors = compute_sectors_total(csv)
            queries[q] = total_hits / total_sectors * 100.0

        if q == 'DRAMSectors':
            hits = csv['dram__sectors_read.sum'][1:].str.replace(
                ',', '').astype(float)
            total_hits = np.sum(hits)
            total_sectors = compute_sectors_total(csv)
            queries[q] = total_hits / total_sectors * 100.0

    return queries


def figure1(parser):

    graph_algorithms = [d for d in listdir(args.input_dir)
                        if isdir(join(args.input_dir, d))]

    metrics = ['L1Sectors',
               'L2Sectors',
               'DRAMSectors']

    pretty_reorder_algo = {'hub': 'hub', 'deg': 'deg', 'RCM': 'RCM',
                           'rand': 'rand', 'write_reorder2': 'BOBA', 'gorder': 'Gorder'}
    pretty_metrics = ['L1',
                      'L2',
                      'DRAM']
    # metrics = ['L1ReadHitRate']

    # metrics = ['L1ReadHitRate',
    #            'L2HitRate',
    #            'LoadEff']
    results_dfs = {}
    for metric in metrics:
        results_dfs[metric] = pd.DataFrame()

    graphs_order = {}
    sort_by = 'n_edges'
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
        graphs_order['arabic-2005'] = 76.43082427978516  # todo fix this
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
        graphs_order['arabic-2005'] = 76.43082427978516  # todo fix this
    elif sort_by == 'n_edges':
        graphs_order['coAuthorsCiteseer'] = 1628268
        graphs_order['coAuthorsDBLP'] = 1955352
        graphs_order['delaunay_n22'] = 25165738
        graphs_order['delaunay_n23'] = 50331568
        graphs_order['delaunay_n24'] = 100663202
        graphs_order['great-britain_osm'] = 16313034
        graphs_order['hollywood-2009'] = 112751422
        graphs_order['rgg_n_2_22_s0'] = 60718396
        graphs_order['rgg_n_2_23_s0'] = 127002786
        graphs_order['rgg_n_2_24_s0'] = 281891617
        graphs_order['roadNet-CA'] = 5533214
        graphs_order['road_usa'] = 57708624
        graphs_order['soc-LiveJournal1'] = 68475391
        graphs_order['ljournal-2008'] = 79023142
        graphs_order['arabic-2005'] = 631153669

    for metric in metrics:
        metric_df = pd.DataFrame()
        for graph_algo in graph_algorithms:
            if args.algorithms == 'all' or graph_algo == args.algorithms:
                cur_dir = join(args.input_dir, graph_algo)
                reorder_algorithms = [d for d in listdir(cur_dir)
                                      if isdir(join(cur_dir, d))]
                reorder_algorithms.remove('chub')
                reorder_algorithms.remove('edgeW3')

                for reorder_algo in reorder_algorithms:
                    json_dir = join(cur_dir, reorder_algo)
                    graphs = [f for f in listdir(json_dir)
                              if isfile(join(json_dir, f))]
                    graphs.sort(key=lambda x: graphs_order[splitext(x)[0]])
                    # print(graphs)
                    graphs_results = {}
                    for graph in graphs:
                        graph_name = splitext(graph)[0]
                        graphs_results[graph_name] = extract_data_from_csv(
                            join(json_dir, graph), {metric: 0})[metric]

                    # print(graphs_results)
                    df = pd.DataFrame.from_dict(
                        graphs_results, orient='index', columns=[reorder_algo])
                    metric_df[pretty_reorder_algo[reorder_algo]] = df
                metric_df.rename_axis('dataset').reset_index()
                results_dfs[metric] = metric_df.rename_axis(
                    'dataset').reset_index()

    longform = pd.DataFrame()
    for metric, pmetric in zip(metrics, pretty_metrics):
        tmp = results_dfs[metric].melt(
            'dataset', var_name='Reorder Algorithm', value_name='Percentage of hits')
        tmp['Level'] = pmetric
        # if metric == metrics[0]:
        longform = longform.append(tmp)

    chart = alt.Chart(longform).mark_bar().encode(alt.X('dataset', sort=None, stack=None), alt.Y(
        'Percentage of hits', scale=alt.Scale(domain=[0, 100])),
        color=alt.Color('Level', sort=pretty_metrics), order=alt.Order('color_pretty_metrics_index:Q'),
        column='Reorder Algorithm')
    # .configure_axis(labelFontSize=15,
    # titleFontSize=20).configure_legend(titleFontSize=20,
    # labelFontSize=15).configure_title(fontSize=50)

    chart_fname = args.algorithms + '_' + 'by_' + sort_by + '.svg'
    chart.save(chart_fname, scale_factor=2.0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-id', '--input-dir', default='./csv')
    parser.add_argument('-od', '--output-dir', default='./figures')
    parser.add_argument('-my', '--min-y', default=-1, type=int)
    parser.add_argument('-xy', '--max-y', default=-1, type=int)
    parser.add_argument('-alg', '--algorithms', default='tc')

    args = parser.parse_args()
    print("Reading results from: ", args.input_dir)

    figure1(parser)
