import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';

/// Abstract contract for multispectral remote-sensing data providers (e.g. Sentinel-2 from GEE/Copernicus).
abstract class RemoteSensingProvider {
  String get providerId;
  String get displayName;

  /// Requests a multispectral remote sensing product matching the specified query.
  Future<DataProviderResult<MultispectralProduct>> fetchProduct(RemoteSensingQuery query, {String? accessToken});
}
