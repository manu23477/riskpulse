import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/research_product_registry.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/domain/gis/research_output_sink.dart';
import 'package:riskpulse/data/services/raster_export_service.dart';
import 'package:riskpulse/data/services/share_output_sink.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/research_workspace_state.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/spectral_index_engine.dart';

/// Card widget displaying cataloged research products and remote sensing spectral indices.
class ResearchProductsCard extends StatefulWidget {
  final ResearchProductRegistry registry;
  final RasterExportService exportService;
  final ResearchOutputSink outputSink;
  final SpectralIndexEngine indexEngine;

  ResearchProductsCard({
    super.key,
    required this.registry,
    RasterExportService? exportService,
    ResearchOutputSink? outputSink,
    SpectralIndexEngine? indexEngine,
  })  : exportService = exportService ?? RasterExportService(),
        outputSink = outputSink ?? ShareOutputSink(),
        indexEngine = indexEngine ?? SpectralIndexEngine();

  @override
  State<ResearchProductsCard> createState() => _ResearchProductsCardState();
}

class _ResearchProductsCardState extends State<ResearchProductsCard> {
  final Set<String> _exportingProductIds = {};

  bool _isExportableRaster(ResearchProduct p) {
    return p.isAvailable &&
        p.category == ResearchProductCategory.raster &&
        p.supportedExportFormats.contains(ResearchProductFormat.geoTiff) &&
        p.sourceData is RasterData;
  }

  Future<void> _handleExport(ResearchProduct product) async {
    if (!_isExportableRaster(product)) return;

    setState(() {
      _exportingProductIds.add(product.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting ${product.name} as GeoTIFF...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      final request = RasterExportRequest(
        product: product,
        requestedAt: DateTime.now(),
      );

      final exportResult = widget.exportService.export(request);

      if (!exportResult.isSuccess || exportResult.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${exportResult.error?.message ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final filename = '${product.id}.tif';
      final sinkResult = await widget.outputSink.output(
        bytes: exportResult.bytes!,
        filename: filename,
        mimeType: 'image/tiff',
        title: product.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (sinkResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${product.name} successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (sinkResult.error?.type != OutputSinkErrorType.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export delivery failed: ${sinkResult.error?.message ?? "Delivery error"}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export exception: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportingProductIds.remove(product.id);
        });
      }
    }
  }

  void _calculateNdvi(ResearchWorkspaceProvider workspace) {
    final msProduct = workspace.multispectralProduct;
    if (msProduct == null) return;

    try {
      final ndviRaster = widget.indexEngine.calculateNdviFromProduct(msProduct);
      workspace.setNdviRaster(ndviRaster);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NDVI calculated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NDVI calculation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateNdwi(ResearchWorkspaceProvider workspace) {
    final msProduct = workspace.multispectralProduct;
    if (msProduct == null) return;

    try {
      final ndwiRaster = widget.indexEngine.calculateNdwiFromProduct(msProduct);
      workspace.setNdwiRaster(ndwiRaster);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NDWI calculated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NDWI calculation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInspectDialog(MultispectralProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_outlined, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Sentinel-2 Product Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _inspectRow('Product ID', product.productId),
              _inspectRow('Provider', product.providerId.toUpperCase()),
              _inspectRow('Dataset ID', product.datasetId),
              _inspectRow('Acquisition Date', product.acquisitionDate.toIso8601String().split('T').first),
              _inspectRow('Cloud Cover', product.cloudCoverPercentage != null ? '${product.cloudCoverPercentage}%' : 'Not available'),
              _inspectRow('CRS', product.crs.code),
              const SizedBox(height: 12),
              const Text('Available Spectral Bands:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 6),
              ...product.bands.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 6),
                    child: Text('• ${b.bandId} (${b.displayName}) — ${b.nominalResolutionMeters.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _inspectRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = widget.registry.products;
    ResearchWorkspaceProvider? workspace;
    try {
      workspace = Provider.of<ResearchWorkspaceProvider>(context);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF0F172A)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Research Products',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.registry.availableCount} / ${widget.registry.totalCount} Ready',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (allProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No products cataloged in research registry.',
                  style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                ),
              )
            else
              Column(
                children: allProducts.map((p) => _buildProductRow(p)).toList(),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // REMOTE SENSING SECTION
            _buildRemoteSensingSection(workspace),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteSensingSection(ResearchWorkspaceProvider? workspace) {
    final msProduct = workspace?.multispectralProduct;
    final ndviRaster = workspace?.ndviRaster;
    final ndwiRaster = workspace?.ndwiRaster;
    final isProcessing = workspace?.isRemoteSensingProcessing ?? false;
    final rsError = workspace?.remoteSensingError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.satellite_alt_outlined, size: 14, color: Color(0xFF0F172A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'REMOTE SENSING & SPECTRAL INDICES',
                softWrap: true,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0F172A), letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Sentinel-2 Surface Reflectance
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: msProduct != null ? Colors.green : isProcessing ? Colors.orange : rsError != null ? Colors.red : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Sentinel-2 Surface Reflectance',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        'COPERNICUS/S2_SR_HARMONIZED • 10m',
                        style: TextStyle(fontSize: 9, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
              if (msProduct != null)
                SizedBox(
                  height: 26,
                  child: OutlinedButton(
                    onPressed: () => _showInspectDialog(msProduct),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('INSPECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isProcessing
                        ? 'PROCESSING...'
                        : rsError != null
                            ? 'FAILED'
                            : workspace?.state is WorkspaceInitial
                                ? 'NOT CONFIGURED'
                                : 'GEE AUTH REQUIRED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isProcessing ? Colors.orange : rsError != null ? Colors.red : Colors.amber.shade900,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. NDVI Action
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: ndviRaster != null ? Colors.green : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Normalized Difference Vegetation Index (NDVI)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        '(NIR - RED) / (NIR + RED) • Bands 8, 4',
                        style: TextStyle(fontSize: 9, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
              if (ndviRaster != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('AVAILABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                )
              else if (msProduct != null && workspace != null)
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: () => _calculateNdvi(workspace),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('CALCULATE NDVI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Sentinel-2 product required', style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.black38)),
                ),
            ],
          ),
        ),

        // 3. NDWI Action
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: ndwiRaster != null ? Colors.green : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Normalized Difference Water Index (NDWI)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        '(GREEN - NIR) / (GREEN + NIR) • Bands 3, 8',
                        style: TextStyle(fontSize: 9, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
              if (ndwiRaster != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('AVAILABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                )
              else if (msProduct != null && workspace != null)
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: () => _calculateNdwi(workspace),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('CALCULATE NDWI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Sentinel-2 product required', style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.black38)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(ResearchProduct product) {
    final isExportable = _isExportableRaster(product);
    final isExporting = _exportingProductIds.contains(product.id);
    final isAvailable = product.isAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.black87 : Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    isAvailable
                        ? '${product.category.name.toUpperCase()} • ${product.units ?? "raw"}'
                        : '${product.category.name.toUpperCase()} • Not Generated',
                    style: const TextStyle(fontSize: 9, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
          if (isExportable)
            SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                key: Key('export-btn-${product.id}'),
                onPressed: isExporting ? null : () => _handleExport(product),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.blue, width: 1),
                ),
                icon: isExporting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                      )
                    : const Icon(Icons.download_outlined, size: 13, color: Colors.blue),
                label: Text(
                  isExporting ? 'Exporting...' : 'Export GeoTIFF',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                !isAvailable
                    ? 'Unavailable'
                    : product.category == ResearchProductCategory.vector
                        ? 'GeoJSON'
                        : product.category == ResearchProductCategory.tabular
                            ? 'CSV'
                            : 'Metadata Only',
                style: TextStyle(
                  fontSize: 9,
                  color: isAvailable ? Colors.black54 : Colors.black38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
