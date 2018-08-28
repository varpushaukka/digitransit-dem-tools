#!/bin/bash

# Description:
# Chains together km2-dem-downloader.py and gdal_create_optimized_dem.sh
# Check the afromentioned files for more documentation.

# Usage:
#
#    bash download_and_optimize_dem_data.sh <area-code> <optional_clipper_file>
#
# Test script by running it without command line arguments. Test downloads 4 tiles map tiles from NLS API and clips it with test-clipper.json.
# Test run takes about ~2 min. Test requires you to update the NLS ATOM Feeed API token in config.example.json
#
# Area-code values can be found config.example.json, "HSL", "WALTTI", "TEST".

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


dem_data_dl_dir="km2-data-$(date +"%Y%m%d_%H%M")"
file_paths="km2_tif_file_paths-$(date +"%Y%m%d_%H%M").txt"

echo "Starting download script for raster data from NLS API"
mkdir -p $dem_data_dl_dir
python km2-dem-downloader.py config.json $dataset $dem_data_dl_dir -v

echo "Running gdal_create_optimized_dem.sh DEM clipper and optimizer for the dataset"

find $dem_data_dl_dir -name '*.tif' > $file_paths

if $noclip ; then
    bash gdal_create_optimized_dem.sh $file_paths 
else
    bash gdal_create_optimized_dem.sh $file_paths $clipper
fi

duration=$SECONDS
echo "Finished download_and_optimize_dem_data.sh. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."