import 'package:flutter/foundation.dart';
import 'research_product.dart';

/// Strongly typed derived inventory of all research products for a Research GIS study.
///
/// The registry acts as a derived snapshot that queries authoritative analytical state
/// to report product availability, metadata, and export format readiness.
@immutable
class ResearchProductRegistry {
  final String? sessionId;
  final String? sessionTitle;
  final List<ResearchProduct> products;
  final DateTime generatedAt;

  ResearchProductRegistry({
    this.sessionId,
    this.sessionTitle,
    required List<ResearchProduct> products,
    required this.generatedAt,
  }) : products = List.unmodifiable(products);

  /// Returns only products that currently exist in authoritative analytical state.
  List<ResearchProduct> get availableProducts =>
      products.where((p) => p.isAvailable).toList();

  /// Returns products that are part of the pipeline schema but have not been generated.
  List<ResearchProduct> get unavailableProducts =>
      products.where((p) => !p.isAvailable).toList();

  /// Returns products filtered by category (raster, vector, tabular, spatialContext).
  List<ResearchProduct> productsByCategory(ResearchProductCategory category) =>
      products.where((p) => p.category == category).toList();

  /// Finds a specific product by type.
  ResearchProduct? byType(ResearchProductType type) {
    try {
      return products.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Total count of available products.
  int get availableCount => availableProducts.length;

  /// Total count of all cataloged products in the pipeline schema.
  int get totalCount => products.length;
}
