import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';
import 'package:riskpulse/data/services/gee/gee_data_provider.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';

/// Dialog enabling researchers to supply a local GeoTIFF file or acquire a Copernicus DEM from GEE.
class DemAcquisitionDialog extends StatefulWidget {
  final MapExtent aoiExtent;
  final GeoTiffReader reader;
  final GeeDataProvider geeProvider;
  final DemValidationService validationService;
  final DemReadinessPolicyService policyService;

  DemAcquisitionDialog({
    super.key,
    required this.aoiExtent,
    GeoTiffReader? reader,
    GeeDataProvider? geeProvider,
    DemValidationService? validationService,
    DemReadinessPolicyService? policyService,
  })  : reader = reader ?? GeoTiffReader(),
        geeProvider = geeProvider ?? GeeDataProvider(),
        validationService = validationService ?? const DemValidationService(),
        policyService = policyService ?? const DemReadinessPolicyService();

  @override
  State<DemAcquisitionDialog> createState() => _DemAcquisitionDialogState();
}

class _DemAcquisitionDialogState extends State<DemAcquisitionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tokenController = TextEditingController();

  bool _isProcessing = false;
  String? _errorMessage;
  DemValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void loadLocalBytes(Uint8List bytes) {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _validationResult = null;
    });

    try {
      final raster = widget.reader.decode(bytes);
      final result = widget.validationService.validateDemAgainstAoi(
        raster: raster,
        aoiExtent: widget.aoiExtent,
      );

      setState(() {
        _validationResult = result;
        _isProcessing = false;
        if (result.isRejected) {
          _errorMessage = result.message;
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'GeoTIFF Decoding Failed: ${e.toString().replaceAll('FormatException: ', '')}';
      });
    }
  }

  Future<void> _fetchGeeDem() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'GEE Authentication Required: Please enter a valid Bearer Access Token.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _validationResult = null;
    });

    try {
      final result = await widget.geeProvider.fetchDem(
        extent: widget.aoiExtent,
        resolutionMeters: 30.0,
        accessToken: token,
      );

      if (result.isSuccess && result.data != null) {
        final valResult = widget.validationService.validateDemAgainstAoi(
          raster: result.data!,
          aoiExtent: widget.aoiExtent,
        );

        setState(() {
          _validationResult = valResult;
          _isProcessing = false;
          if (valResult.isRejected) {
            _errorMessage = valResult.message;
          }
        });
      } else {
        final err = result.error;
        String msg = 'GEE Acquisition Failed: ${err?.message ?? "Unknown error"}';
        if (err?.type == DataProviderErrorType.unauthorized) {
          msg = 'GEE Authentication Failed: Bearer token is invalid or expired.';
        } else if (err?.type == DataProviderErrorType.quotaExceeded) {
          msg = 'GEE Rate Limit Exceeded: Compute quota exceeded. Please try again later.';
        }

        setState(() {
          _isProcessing = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'GEE Acquisition Exception: $e';
      });
    }
  }

  void _confirmAndAttach() {
    if (_validationResult != null &&
        _validationResult!.raster != null &&
        !_validationResult!.isRejected) {
      final assessment = widget.policyService.evaluateReadiness(
        assessmentId: 'readiness-${DateTime.now().millisecondsSinceEpoch}',
        validationResult: _validationResult!,
        productContext: 'general_terrain',
      );
      Navigator.of(context).pop((raster: _validationResult!.raster!, assessment: assessment));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terrain_outlined, color: Color(0xFF0F172A), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Load Research DEM Dataset',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Local GeoTIFF File'),
                Tab(text: 'Google Earth Engine (GLO-30)'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLocalFileTab(),
                  _buildGeeTab(),
                ],
              ),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Decoding & Validating DEM Raster...', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            if (_validationResult != null && !_validationResult!.isRejected)
              _buildMetadataPreview(_validationResult!),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_validationResult != null && !_validationResult!.isRejected)
                      ? _confirmAndAttach
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('ATTACH DEM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalFileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supply an uncompressed 32-bit or 64-bit single-band GeoTIFF DEM raster.',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          key: const Key('browse-local-geotiff-btn'),
          onPressed: () {
            // For testing/mocking in Flutter, simulates loading test bytes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select or paste local GeoTIFF bytes.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.folder_open, size: 16),
          label: const Text('BROWSE GEOTIFF FILE'),
        ),
      ],
    );
  }

  Widget _buildGeeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acquire Copernicus DEM GLO-30 raster directly from Google Earth Engine REST API.',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('gee-token-field'),
          controller: _tokenController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'GCP / Earth Engine Bearer Access Token',
            hintText: 'Enter OAuth2 Bearer token (ya29...)',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.key, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          key: const Key('fetch-gee-dem-btn'),
          onPressed: _isProcessing ? null : _fetchGeeDem,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          icon: const Icon(Icons.cloud_download, size: 16),
          label: const Text('FETCH GEE DEM (30m)'),
        ),
      ],
    );
  }

  Widget _buildMetadataPreview(DemValidationResult result) {
    final meta = result.metadata;
    final isPartial = result.isPartial;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPartial ? Colors.amber.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPartial ? Colors.amber.shade300 : Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isPartial ? Icons.warning_amber : Icons.verified, size: 16, color: isPartial ? Colors.amber.shade900 : Colors.green.shade800),
              const SizedBox(width: 6),
              Text(
                result.message,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPartial ? Colors.amber.shade900 : Colors.green.shade800),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Provider: ${meta['provider']}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
              Text('Dimensions: ${meta['width']} x ${meta['height']}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Footprint Coverage: ${meta['footprintCoveragePercentage']}%', style: const TextStyle(fontSize: 10, color: Colors.black87)),
              Text('Valid Cells: ${result.validCellPercentage.toStringAsFixed(1)}% (${result.validElevationCells}/${result.totalAoiCells})', style: const TextStyle(fontSize: 10, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CRS: ${meta['crs']}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
              Text('NoData %: ${result.noDataPercentage.toStringAsFixed(1)}% (${result.noDataCells} cells)', style: const TextStyle(fontSize: 10, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
