#!/bin/bash

# Description:
# Chains together km2-dem-downloader.py and gdal_create_optimized_dem.sh
# Check the afromentioned files for more documentation.

# Usage:
#
#    bash download_and_optimize_dem_data.sh <area-code> [optional_clipper_file]
#
# Test script by running it without command line arguments. Test downloads 4 tiles map tiles from NLS API and clips it with test-clipper.json.
# Test run takes about ~2 min. Test requires you to update the NLS ATOM Feeed API token in config.example.json
#
# Area-code values can be found config.example.json, for example "HSL", "WALTTI", "TEST".

set -e
SECONDS=0
noclip=false

if [ "$#" = 0 ]; then
	echo "Test run activated"
    dataset="TEST"
	clipper="test-clipper.geojson"
elif [ "$#" = 1 ]; then
    dataset=$1
	noclip=true
elif [ "$#" = 2 ]; then
	dataset=$1
	clipper=$2
	echo "Clipping dataset: $dataset to extent of clipper: $clipper."
else
   	echo "Too many args."
	exit 1
fi

output_dir="output-$dataset-$(date +"%Y%m%d_%H%M")"
dem_data_dl_dir="km2-data-$(date +"%Y%m%d_%H%M")"
file_paths="km2_tif_file_paths-$(date +"%Y%m%d_%H%M").txt"
dataset_vrt="$dataset-$(date +"%Y%m%d_%H%M").vrt"

echo "1. Starting download script km2-dem-downloader.py for getting raster elevation data from NLS API"
mkdir -p $output_dir/$dem_data_dl_dir
python km2-dem-downloader.py config.json $dataset $output_dir/$dem_data_dl_dir -v

echo "Running gdal_create_optimized_dem.sh DEM clipper and optimizer for the dataset"

find $output_dir/$dem_data_dl_dir -name '*.tif' > $output_dir/$file_paths

echo "Creating VRT $dataset_vrt of raster files in $file_paths"
gdalbuildvrt -input_file_list $output_dir/$file_paths $output_dir/$dataset_vrt

if $noclip ; then
    bash gdal_create_optimized_dem.sh $output_dir/$dataset_vrt $output_dir
else
    bash gdal_create_optimized_dem.sh $output_dir/$dataset_vrt $output_dir $clipper
fi

duration=$SECONDS
echo "Finished download_and_optimize_dem_data.sh. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."