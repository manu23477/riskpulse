import 'package:flutter/material.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';

/// Selection result returned by [ExportMapDialog].
enum ExportMapActionType {
  publicationPdf,
  pngSnapshot,
  gisCatalogue,
}

class ExportMapDialogResult {
  final ExportMapActionType actionType;
  final ResearchMapPageFormat selectedPdfFormat;

  const ExportMapDialogResult({
    required this.actionType,
    this.selectedPdfFormat = ResearchMapPageFormat.a4Portrait,
  });
}

/// Dialog enabling researchers to choose a map export option.
class ExportMapDialog extends StatefulWidget {
  final ResearchMapPageFormat initialPdfFormat;

  const ExportMapDialog({
    super.key,
    this.initialPdfFormat = ResearchMapPageFormat.a4Portrait,
  });

  @override
  State<ExportMapDialog> createState() => _ExportMapDialogState();
}

class _ExportMapDialogState extends State<ExportMapDialog> {
  late ResearchMapPageFormat _selectedPdfFormat;

  @override
  void initState() {
    super.initState();
    _selectedPdfFormat = widget.initialPdfFormat;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Color(0xFF0F172A), size: 22),
          SizedBox(width: 8),
          Text(
            'Export Research Map',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select map export format or browse GIS product datasets:',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Option 1: Publication PDF Map
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print, color: Colors.indigo, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Publication PDF Map',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ResearchMapPageFormat>(
                    initialValue: _selectedPdfFormat,
                    decoration: const InputDecoration(
                      labelText: 'Page Layout Format',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: ResearchMapPageFormat.values.map((fmt) {
                      return DropdownMenuItem(
                        value: fmt,
                        child: Text(fmt.displayName, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (fmt) {
                      if (fmt != null) {
                        setState(() => _selectedPdfFormat = fmt);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('export-pdf-action-btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(
                          ExportMapDialogResult(
                            actionType: ExportMapActionType.publicationPdf,
                            selectedPdfFormat: _selectedPdfFormat,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export PDF Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Option 2: PNG Viewport Snapshot
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.image, color: Colors.teal, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Map Image Snapshot (PNG)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Captures pixel viewport of the active map canvas.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('export-png-action-btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(
                          const ExportMapDialogResult(
                            actionType: ExportMapActionType.pngSnapshot,
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Capture PNG Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Option 3: GIS Dataset Catalogue
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('export-catalogue-action-btn'),
                onPressed: () {
                  Navigator.of(context).pop(
                    const ExportMapDialogResult(
                      actionType: ExportMapActionType.gisCatalogue,
                    ),
                  );
                },
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Browse GIS Product Catalogue (GeoTIFF / GeoJSON)', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
