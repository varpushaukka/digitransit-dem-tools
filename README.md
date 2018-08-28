# digitransit-dem-tools

Command line tool for downloading National Land Survey [KM2-dataset](https://www.maanmittauslaitos.fi/en/maps-and-spatial-data/expert-users/product-descriptions/elevation-model-2-m) and creating an optimized digital elevation model (DEM) for Digitransit. 

### Getting started

* `km2-dem-downloader.py` downloads KM2-dataset tiles from NLS API
* `gdal_create_optimized_dem.sh` crops and optimizes KM2-dataset tiles into a single GeoTiff using commandline GDAL binaries and gdal_calc.py 
* `download_and_optimize_dem_data.sh` chains together `km2-dem-downloader.py` and `gdal_create_optimized_dem.sh`

Usage:

   bash download_and_optimize_dem_data.sh <area-code> <optional_clipper_file>

Area-code values can be found config.json, "HSL", "WALTTI", "TEST".

```
bash download_and_optimize_dem_data.sh <area-code> <optional_clipper_file>
```
Test script by running it without command line arguments. 

```
bash download_and_optimize_dem.sh
```

Test downloads 4 tiles map tiles from NLS API and clips it with test-clipper.json.
Test run takes about ~2 min. Test requires you to update the NLS ATOM Feeed API token in config.json

### Prerequisites

* [NLS Updating service interface API key](https://www.maanmittauslaitos.fi/en/e-services/open-data-file-download-service/open-data-file-updating-service-interface)
* Python 3
* Bash
* GDAL

### Installing

TODO (to be dockerized)

