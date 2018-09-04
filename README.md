# digitransit-dem-tools

Command line tool for downloading National Land Survey [KM2-dataset](https://www.maanmittauslaitos.fi/en/maps-and-spatial-data/expert-users/product-descriptions/elevation-model-2-m) and creating an optimized digital elevation model (DEM) for Digitransit. 

### Getting started

File | Description
--- | --- 
`km2-dem-downloader.py` | Downloads KM2-dataset tiles from NLS API
`gdal_create_optimized_dem.sh` |  Crops and optimizes KM2-dataset tiles into a single GeoTiff using commandline GDAL binaries and gdal_calc.py 
`download_and_optimize_dem_data.sh` | Chains together `km2-dem-downloader.py` and `gdal_create_optimized_dem.sh`
`config.json` | Contains NLS API token and predefined tiles for different Digitransit areas (HSL, Waltti and cities)

> **Note!** For optimization reasons the unit of elevation in the final GeoTIFF is **decimeters**.
### Prerequisites

* [NLS Updating service interface API key](https://www.maanmittauslaitos.fi/en/e-services/open-data-file-download-service/open-data-file-updating-service-interface)
* Python 3
* Bash
* GDAL

### Installing

Install gdal binaries from UbuntuGIS repository

```
sudo add-apt-repository ppa:ubuntugis/ppa && sudo apt-get update && sudo apt-get install gdal-bin python-gdal
```

Install pip and virtualenv

```
sudo apt-get install python3-pip && sudo pip3 install virtualenv
```

Create a python3 virtual environment 

```
virtualenv -p python3 my-virtual-env
```

Active your newly created virtual environment:
```
source my-virtual-env/bin/activate
```
Install python package `requests`

```
pip3 install requests
```

Clone project

```
git clone https://github.com/hsldevcom/digitransit-dem-tools
```

Update `config.json` with NLS API key.

Test the script:

```
bash download_and_optimize_dem
```

Test downloads 4 tiles map tiles from NLS API and clips it with test-clipper.json.
Test run takes about ~2 min.

### Usage

Make sure to update your NLS API key to `config.json`

```
bash download_and_optimize_dem_data.sh <area-code> <optional_clipper_file>
```

Area-code values can be found config.json. Following values are accepted:

<area_code> |
--- |
HSL |
WALTTI | 
HAMEENLINNA |  
KUOPIO |
JOENSUU |
JYVASKYLA |
KOTKA | 
KOUVOLA |
LAHTI |
LAPPEENRANTA |
MIKKELI |
OULU |
ROVANIEMI |
TAMPERE |
TURKU |

Pre-made area specific clippers based on Digitransit UI search extent [configurations](https://github.com/HSLdevcom/digitransit-ui/tree/master/app/configurations) are available in GeoJSON format in `area-extents/`

For example:

```
bash download_and_optimize_dem KUOPIO area-extents/kuopio.geojson
```

Downloads all available Kuopio specific KM2-tiles and clip the raster to the `kuopio.geojson`.


### TODO (to be dockerized)

