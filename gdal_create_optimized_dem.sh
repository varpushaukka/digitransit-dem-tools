#!/bin/bash

# Description:
# GDAL script to create optimized Digital Elevation Model for OpenTripPlanner using NLS KM2 dataset.
#
# Requirements:
# GDAL binaries: gdal-bin, gdal_calc.py
#	add-apt-repository ppa:ubuntugis/ppa && sudo apt-get update && apt-get install gdal-bin
#
# Input:
#   - List of source tif file paths for the DEM. (Eg. find $(pwd) -iname "*.tif" -type f > raster_paths.txt)
#   - Optional OGR supported geometry format for clipping the dataset to a geometry cutline. For example GeoJSON.
#
# Output:
#   - Single Digital Elevation Model tiled and LZW compressed GeoTIFF. Elevation values are stored in 16 bit unsigned
#     integers rounded to decimeters from meters.
#
# Usage:
#   gdal_create_optimized_dem.sh <input_file_list> [optional_clipper]
#
# Author: Juuso Korhonen

set -e
SECONDS=0
echo_time() {
    echo ""
    date +"%m-%d_%H:%M:%S  :: $*"
}

clip_mode=false

if [ "$#" = 2 ]; then
    raster_paths=$1
    clipper=$2
	clip_mode=true
elif [ "$#" = 1 ]; then
    raster_paths=$1
else
   	echo ""
    echo "Usage:"
    echo "    gdal_create_optimized_dem.sh <input_file_list> [optional_clipper]"
    echo ""
    echo "Example:"
    echo "    gdal_create_optimized_dem.sh my_raster_paths.txt my-area.geojson"
	echo ""
	echo "Creates an optimized DEM file from files provided by my_raster_paths.txt clipped to cutline of file my-area.geojson."
	echo "Clipping supports any OGR and multipolygon format (GeoJSON, Shapefile etc.) Area outside of HSL-area.geojson is written to NoData."
	exit 1
fi


source_vrt="dem-area-$(date +"%Y%m%d_%H%M%S").vrt"
reprojected="reprojected-$(date +"%Y%m%d_%H%M%S").tif"
finaldem="DEM-final-uint16-dm-$(date +"%Y%m%d_%H%M%S").tif"

echo_time "1. Creating VRT of raster files."
gdalbuildvrt -input_file_list $raster_paths $source_vrt

if $clip_mode ; then
    echo_time "2. Creating GeoTiff with cutline, nodata 99999"
    gdalwarp -of GTiff -dstnodata 99999 -cutline $clipper -crop_to_cutline -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW $source_vrt $reprojected
else
    echo_time "2. Creating GeoTiff, nodata to 99999"
    gdalwarp -of GTiff -dstnodata 99999 -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW $source_vrt $reprojected
fi

echo_time "3. Reproject to WGS84"

gdalwarp -of GTiff -srcnodata 99999 -dstnodata 99999 -s_srs EPSG:3067 -t_srs EPSG:4326 -r bilinear -multi -wo NUM_THREADS=ALL_CPUS -wo OPTIMIZE_SIZE -co COMPRESS=LZW -co BIGTIFF=YES -co TILED=YES $reprojected 4326-$reprojected

echo_time "4. Converting elevation unit from meters to decimeters. Round 32 bit floats to 16 bit unsigned integers. NoData is 0."

gdal_calc.py -A 4326-$reprojected --outfile=$finaldem --type UInt16 --format=GTiff --co COMPRESS=LZW --co TILED=YES --co BIGTIFF=YES --co NUM_THREADS=ALL_CPUS --calc="numpy.around(10*(A*(A>0)))" --NoDataValue=0

duration=$SECONDS
echo_time "Finished gdal_create_optimized_dem.sh. $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."