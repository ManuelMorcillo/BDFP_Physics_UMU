import cdsapi

c = cdsapi.Client()

c.retrieve(
    'cems-fire-historical-v1',
    {
        'product_type': 'reanalysis',
        'variable': 'fire_weather_index',
        'dataset_type': 'consolidated_dataset',
        'system_version': '4_1',
        'year': 'SSSYEAR',
        'month': 'SSSMONTH',
        'day': 'SSSDAY',
        'grid': '0.25/0.25',
        'format': 'netcdf',
    },
    'download.nc')
    