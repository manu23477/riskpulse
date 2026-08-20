import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/community_report.dart';
import '../../data/models/geo_location.dart';
import '../../data/services/community_report_service.dart';
import '../../data/services/location_service.dart';

class ReportHazardScreen extends StatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  State<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends State<ReportHazardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();
  final _reportService = CommunityReportService();
  final _picker = ImagePicker();

  String _selectedCategory = 'Landslide';
  HazardSeverity _selectedSeverity = HazardSeverity.moderate;
  XFile? _image;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Landslide',
    'Road Crack',
    'Soil Slip',
    'Rockfall',
    'Water Logging',
    'Other'
  ];

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      
      final report = CommunityReport(
        id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
        category: _selectedCategory,
        description: _descriptionController.text,
        location: GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        severity: _selectedSeverity,
        imagePath: _image?.path,
      );

      _reportService.addReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hazard report submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D5E),
        foregroundColor: Colors.white,
        title: const Text('Report Hazard'),
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contribution to Safety',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your report helps the community stay safe by providing real-time hazard data.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('Hazard Type'),
                  _buildCategoryDropdown(),
                  
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('Photo Evidence'),
                  _buildImagePicker(),
                  
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('Severity Level'),
                  _buildSeveritySelector(),
                  
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('Description'),
                  _buildDescriptionField(),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5D5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, style: BorderStyle.solid),
        ),
        child: _image == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.black26),
                SizedBox(height: 8),
                Text('Tap to capture photo', style: TextStyle(color: Colors.black38)),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(_image!.path), fit: BoxFit.cover),
            ),
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: HazardSeverity.values.map((severity) {
        final isSelected = _selectedSeverity == severity;
        final color = _getSeverityColor(severity);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedSeverity = severity),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : Colors.black12),
            ),
            child: Text(
              _getSeverityLabel(severity),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Provide details about what you observed...',
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a description';
          }
          return null;
        },
      ),
    );
  }

  Color _getSeverityColor(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.low: return Colors.green;
      case HazardSeverity.moderate: return Colors.orange;
      case HazardSeverity.high: return Colors.red;
      case HazardSeverity.critical: return Colors.purple;
    }
  }

  String _getSeverityLabel(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.low: return 'Low';
      case HazardSeverity.moderate: return 'Moderate';
      case HazardSeverity.high: return 'High';
      case HazardSeverity.critical: return 'Critical';
    }
  }
}
