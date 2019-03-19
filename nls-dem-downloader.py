#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Command line script for downloading KM2 and KM10 Digital Elevation Model dataset via NLS ATOM feed.

Usage: python nls-dem-downloader.py -h

config.json contains NLS API key and map tile keys as lists for HSL and WALTTI areas. The script uses map tile keys
to parse the full KM2 product list for needed files.

Installation:
Requires Python 3.5 or later and requests

   pip install requests

More info about the NLS Atom feed API:
https://www.maanmittauslaitos.fi/en/e-services/open-data-file-download-service/open-data-file-updating-service-interface

@author: Juuso Korhonen
"""

import argparse
import json
import logging
import os
import sys
import time
from xml.etree import ElementTree

import requests


def request_product_url_to_etree(url):
    try:
        logging.info('Requesting product list from NLS API: {}'.format(url))
        r = requests.get(url, timeout=300)
        r.raise_for_status()
    except requests.exceptions.RequestException as e:
        logging.critical('Error while requesting URL {url}: {error}'.format(url=url, error=e))
        sys.exit(1)
    feed_tree = ElementTree.fromstring(r.content)
    return feed_tree


def get_products(feed):
    tiles = {}

    logging.info('Parsing XML...')
    for entry in feed.findall(prep('entry')):
        title = entry.find(prep('title')).text[:-4]
        href = entry.find(prep('link')).attrib['href']
        tiles[title] = href

    for link in feed.findall(prep('link')):
        rel = link.attrib['rel']
        if rel == 'next':
            new_url = link.attrib['href']
            new_url.replace('&amp;', '&')
            logging.info('Found "rel=next". Requesting next product list...')
            new_feed = request_product_url_to_etree(new_url)
            tiles.update(get_products(new_feed))

    return tiles


def parse_products(tiles, search_keys):
    logging.info('Searching downloaded product list for search keys...')

    tiles_set = set(tiles)
    print(tiles_set)
    search_keys = set(search_keys)

    found = search_keys & tiles_set
    not_found = search_keys - tiles_set
    logging.info('Found {found_count} tiles: {tile_list}'.format(found_count=len(found), tile_list=str(found)))

    if not_found:
        logging.info('{not_found_count} tiles not found: {tile_list}'.format(not_found_count=len(not_found),
                                                                             tile_list=str(not_found)))

    return found


def download_files(found, tiles, output_dir):
    if not found:
        logging.warning('No tiles to be downloaded.')
    else:
        logging.info('Starting download of {total} files.'.format(total=len(found)))
        for idx, key in enumerate(found, start=1):
            url = tiles[key]
            logging.info('Downloading: {key} [{idx}/{total}]: {url}'.format(key=key, idx=idx, total=len(found),
                                                                            url=url))
            response = requests.get(url)
            if response.status_code == 200:
                filepath = os.path.join(output_dir, key + '.tif')
                with open(filepath, 'wb') as f:
                    f.write(response.content)
            else:
                logging.error('Error downloading file {}. HTTP status code: {}'.format(url, response.status_code))
        logging.info('Download finished.')


def load_conf(args):
    with open(args.config_json, 'r') as f:
        config = json.load(f)

    api_token = config['API_TOKEN']

    if args.km10:
        dataset = 'korkeusmalli/hila_10m'
        search_keys = config['KM10'][args.area_key]
    elif args.orto:
        dataset = 'orto/ortokuva'
        search_keys = config['KM2'][args.area_key]
    else:
        dataset = 'korkeusmalli/hila_2m'
        search_keys = config['KM2'][args.area_key]

    product_url = 'https://tiedostopalvelu.maanmittauslaitos.fi/tp/feed/mtp/{0}?format=image/tiff&api_key={1}'.format(
        dataset, api_token)

    return search_keys, product_url, args.output_dir


def parse_args():
    description = '''
    Download NLS KM2 or KM10 Digital Elevation Model dataset via NLS ATOM feed. More info:
    https://www.maanmittauslaitos.fi/en/e-services/open-data-file-download-service/open-data-file-updating-service-interface

    Example
    '''
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("config_json", type=str,
                        help="config.json containing API key and predefined tiles for different areas")
    parser.add_argument("area_key", type=str, help="'HSL', 'WALTTI' etc.")
    parser.add_argument("output_dir", type=str, help="Output directory")

    parser.add_argument("-v", "--verbose", help="Write script output to stdout",
                        action="store_true")
    parser.add_argument("-km10", "--km10", help="Download KM10 tiles instead of default KM2 tiles",
                        action="store_true")
    parser.add_argument("-orto", "--orto", help="Download orto tiles instead of default KM2 tiles",
                        action="store_true")

    return parser.parse_args()


def prep(s):
    return '{http://www.w3.org/2005/Atom}' + s


def main():
    logging.basicConfig(filename='mml-atom_downloader.log', level=logging.INFO, format='%(asctime)s %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    logging.getLogger('requests').setLevel(logging.ERROR)
    # Parse command line arguments
    args = parse_args()
    if args.verbose:
        logging.getLogger().addHandler(logging.StreamHandler())

    # Read parameters from conf.json file
    search_keys, product_url, output_dir = load_conf(args)
    print('Script started, logging into mml-atom_downloader.log...')

    # Call and parse NLS Atom feed and get DL URLs for all tiles of KM2 data product
    all_tiles = get_products(request_product_url_to_etree(product_url))

    # Parse product list for desired tiles
    found_tiles = parse_products(all_tiles, search_keys)

    # Download found tiles to output_dir
    download_files(found_tiles, all_tiles, output_dir)

    logging.info('Finished executing nls-dem-downloader.py.')


if __name__ == "__main__":
    main()
