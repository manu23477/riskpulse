import 'package:riskpulse/domain/gis/remote_sensing_query.dart';

/// Builds a serialized Google Earth Engine Expression graph for
/// Sentinel-2 Surface Reflectance Harmonized acquisition.
///
/// No network access, authentication, raster decoding, resampling,
/// or cloud masking is performed here.
class Sentinel2ExpressionBuilder {
  static const String defaultDatasetId = 'COPERNICUS/S2_SR_HARMONIZED';

  static Map<String, dynamic> build({
    required RemoteSensingQuery query,
    required String bandId,
  }) {
    if (bandId.trim().isEmpty) {
      throw ArgumentError.value(
        bandId,
        'bandId',
        'Sentinel-2 band ID must not be empty.',
      );
    }

    if (query.startDate.isAfter(query.endDate)) {
      throw ArgumentError(
        'query.startDate must be before or equal to query.endDate.',
      );
    }

    final west = query.extent.southWest.longitude;
    final south = query.extent.southWest.latitude;
    final east = query.extent.northEast.longitude;
    final north = query.extent.northEast.latitude;

    final datasetId = query.datasetId ?? defaultDatasetId;

    final values = <String, dynamic>{};

    values['dataset'] = {
      'functionInvocationValue': {
        'functionName': 'ImageCollection.load',
        'arguments': {
          'id': {'constantValue': datasetId},
        },
      },
    };

    values['aoi'] = {
      'functionInvocationValue': {
        'functionName': 'GeometryConstructors.Polygon',
        'arguments': {
          'coordinates': {
            'constantValue': [
              [
                [west, south],
                [east, south],
                [east, north],
                [west, north],
                [west, south],
              ],
            ],
          },
        },
      },
    };

    values['spatialFilter'] = {
      'functionInvocationValue': {
        'functionName': 'Filter.bounds',
        'arguments': {
          'geometry': {'valueReference': 'aoi'},
        },
      },
    };

    values['spatiallyFiltered'] = {
      'functionInvocationValue': {
        'functionName': 'Collection.filter',
        'arguments': {
          'collection': {'valueReference': 'dataset'},
          'filter': {'valueReference': 'spatialFilter'},
        },
      },
    };

    values['dateFilter'] = {
      'functionInvocationValue': {
        'functionName': 'Filter.date',
        'arguments': {
          'start': {'constantValue': query.startDate.toIso8601String()},
          'end': {'constantValue': query.endDate.toIso8601String()},
        },
      },
    };

    values['temporallyFiltered'] = {
      'functionInvocationValue': {
        'functionName': 'Collection.filter',
        'arguments': {
          'collection': {'valueReference': 'spatiallyFiltered'},
          'filter': {'valueReference': 'dateFilter'},
        },
      },
    };

    values['cloudFilter'] = {
      'functionInvocationValue': {
        'functionName': 'Filter.lessThanOrEquals',
        'arguments': {
          'leftField': {'constantValue': 'CLOUDY_PIXEL_PERCENTAGE'},
          'rightValue': {'constantValue': query.maxCloudCoverPercentage},
        },
      },
    };

    values['cloudFiltered'] = {
      'functionInvocationValue': {
        'functionName': 'Collection.filter',
        'arguments': {
          'collection': {'valueReference': 'temporallyFiltered'},
          'filter': {'valueReference': 'cloudFilter'},
        },
      },
    };

    values['sorted'] = {
      'functionInvocationValue': {
        'functionName': 'Collection.sort',
        'arguments': {
          'collection': {'valueReference': 'cloudFiltered'},
          'property': {'constantValue': 'CLOUDY_PIXEL_PERCENTAGE'},
          'ascending': {'constantValue': true},
        },
      },
    };

    values['first'] = {
      'functionInvocationValue': {
        'functionName': 'Collection.first',
        'arguments': {
          'collection': {'valueReference': 'sorted'},
        },
      },
    };

    values['selected'] = {
      'functionInvocationValue': {
        'functionName': 'Image.select',
        'arguments': {
          'input': {'valueReference': 'first'},
          'bandSelectors': {
            'constantValue': [bandId],
          },
        },
      },
    };

    // Explicitly convert the selected Sentinel-2 band to Float32.
    // This keeps the source SR values unchanged while making the
    // computePixels GeoTIFF compatible with the current GeoTiffReader.
    values['floatBand'] = {
      'functionInvocationValue': {
        'functionName': 'Image.toFloat',
        'arguments': {
          'input': {'valueReference': 'selected'},
        },
      },
    };

    return <String, dynamic>{'values': values, 'result': 'floatBand'};
  }
}
