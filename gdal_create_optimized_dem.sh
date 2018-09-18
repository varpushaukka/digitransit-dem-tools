#!/bin/bash

# Description:
# GDAL script to create optimized Digital Elevation Model for OpenTripPlanner using NLS KM2 dataset.
#
# Requirements:
# GDAL binaries: gdal-bin, gdal_calc.py
#	add-apt-repository ppa:ubuntugis/ppa && sudo apt-get update && apt-get install gdal-bin
#
# Input:
#   - GDAL supported raster formats, eg. .VRT, GeoTIFF
#   - Optional OGR supported geometry format for clipping the dataset to a geometry cutline. For example GeoJSON.
#
# Output:
#   - Single Digital Elevation Model tiled and LZW compressed GeoTIFF. Elevation values are stored in 16 bit unsigned
#     integers rounded to decimeters from meters.
#
# Usage:
#   gdal_create_optimized_dem.sh <input_file> <output_dir> [optional_clipper]
#
# Author: Juuso Korhonen

set -e
SECONDS=0
echo_time() {
    echo ""
    date +"%m-%d_%H:%M:%S  :: $*"
}

clip_mode=false

if [ "$#" = 3 ]; then
    input_file=$1
    output_dir=$2
    clipper=$3
	clip_mode=true
elif [ "$#" = 2 ]; then
    input_file=$1
    output_dir=$2
else
   	echo ""
    echo "Usage:"
    echo "    gdal_create_optimized_dem.sh <input_file> <output_dir> [optional_clipper]"
    echo ""
    echo "Example:"
    echo "    gdal_create_optimized_dem.sh my_input_file.vrt my-output-dir my-area.geojson"
	echo ""
	echo "Creates an optimized GeoTIFF DEM file from files provided by my_input_file.vrt clipped to cutline of file my-area.geojson in my-output-dir."
	echo "Input supports any GDAL raster format (VRT, GeoTIFF etc. and clipping supports any OGR vector format (GeoJSON, Shapefile etc.) Area outside of clipper is written to NoData."
	echo "Input data is expected to be in EPSG:3067 and the output is reprojected to EPSG:4326."
	exit 1
fi

input_file_basepath=${input_file##*/}
input_file_basename=${input_file_basepath%.*}
clipper_basepath=${clipper##*/}
clipper_basename=${clipper_basepath%.*}

initial_cut="$output_dir/$input_file_basename-initial_cut-$clipper_basename.tif"
reproj="$output_dir/$input_file_basename-initial_cut-$clipper_basename-EPSG4326.tif"
finaldem="$output_dir/$clipper_basename-DEM-final-uint16-dm.tif"

if $clip_mode ; then
    echo_time "1. Creating GeoTiff with cutline, nodata 99999"
    gdalwarp -of GTiff -dstnodata 99999 -cutline $clipper -crop_to_cutline -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW --config GDAL_CACHEMAX 500 -wm 500 $input_file $initial_cut
else
    echo_time "1. Creating GeoTiff, nodata to 99999"
    gdalwarp -of GTiff -dstnodata 99999 -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW --config GDAL_CACHEMAX 500 -wm 500 $input_file $initial_cut
fi

echo_time "2. Reproject to WGS84"

gdalwarp -of GTiff -srcnodata 99999 -dstnodata 99999 -s_srs EPSG:3067 -t_srs EPSG:4326 -r bilinear -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co COMPRESS=LZW -co BIGTIFF=YES -co TILED=YES --config GDAL_CACHEMAX 500 -wm 500 $initial_cut $reproj

echo_time "3. Converting elevation unit from meters to decimeters. Round 32 bit floats to 16 bit unsigned integers. NoData is 0."

gdal_calc.py -A $reproj --outfile=$finaldem --type UInt16 --format=GTiff --co COMPRESS=LZW --co TILED=YES --co BIGTIFF=YES --co NUM_THREADS=ALL_CPUS --calc="numpy.around(10*(A*(A>0)))" --NoDataValue=0

duration=$SECONDS
echo_time "Finished gdal_create_optimized_dem.sh. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."