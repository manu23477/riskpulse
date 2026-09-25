# RISKPULSE FORENSIC EXPORT AUDIT REPORT
## EXPORTED MAP & PDF FORENSIC AUDIT & ROOT CAUSE ANALYSIS

**Document ID**: `RISKPULSE_FORENSIC_EXPORT_AUDIT_REPORT`  
**Workstream**: Forensic Export Audit & Root Cause Analysis  
**Date**: September 25, 2026  
**Authoritative Repository**: `C:\Users\HP\StudioProjects\riskpulse`  
**Branch**: `main`  
**Authoritative HEAD**: `9dd86ee2918a6c7cf1bc9c6192a9133e9f996ab1`  
**Audit Mode**: READ-ONLY FORENSIC AUDIT (0 code changes, 0 commits, 0 pushes executed)

---

## 1. FORENSIC AUDIT FINDINGS

An exhaustive read-only inspection of `ResearchMapPrintService`, `PdfCompiler`, `PrintableResearchMapModel`, `CartographicService`, and the `RepaintBoundary` viewport capture path reveals the exact root causes for the observed export behaviors:

### A. Missing Map Image in PDF Export:
- **Root Cause**: `ResearchMapPrintService.generatePdfBinary()` converts `PrintableResearchMapModel` into text markdown (`toPublicationMarkdown()`) and compiles text lines via `PdfCompiler.compileMarkdownToPdf()`.
- `PdfCompiler` synthesizes PDF 1.4 page streams containing only text operators (`BT ... Tj ET`) and font resources (`/Type /Font`).
- `PdfCompiler` currently lacks `/Type /XObject /Subtype /Image` stream objects in its PDF binary synthesizer. Therefore, no map image object is written into the PDF stream.

### B. Unicode / Character Encoding Corruption:
- **Root Cause**: `PdfCompiler` declares Type1 fonts using `/WinAnsiEncoding`, but writes string bytes encoded via `convert.utf8.encode(str)`.
- UTF-8 multi-byte sequences for `°` (`0xC2 0xB0`), `²` (`0xC2 0xB2`), and `—` (`0xE2 0x80 0x94`) are interpreted by PDF readers as broken or unmapped WinAnsi glyphs (e.g., `Â°`, `Â²`).

### C. D8 Flow Direction Representation:
- D8 codes are discrete integers (`1`, `2`, `4`, `8`, `16`, `32`, `64`, `128`).
- When D8 flow direction is formatted as a continuous float range, intermediate scalar labels (`64.5 D8 Code`) are confusing. D8 codes must be displayed as discrete direction classes (`1: East`, `2: South-East`, `4: South`, `8: South-West`, `16: West`, `32: North-West`, `64: North`, `128: North-East`).

### D. Strahler Order Symbology:
- Strahler stream order is a vector line-width hierarchy (`Order 1: 1.0pt`, `Order 2: 2.0pt`, `Order 3: 3.0pt`, `Order 4+: 4.0pt+`).
- In `CartographicService`, Strahler order is already represented as discrete line entries with stroke widths. In PDF text legends, Strahler order should be explicitly described with stroke weight hierarchies.

---

## 2. ANSWERS TO FORENSIC QUESTIONS

1. **Why the PDF does not embed the actual map image**: `PdfCompiler` only writes text operators and font definitions. It does not contain an `/XObject /Subtype /Image` binary stream builder.
2. **Whether `PdfCompiler` supports embedded PNG/image objects**: Currently **NO**. However, standard PDF 1.4 natively supports `/XObject /Subtype /Image` with `/ColorSpace /DeviceRGB` and `/BitsPerComponent 8`. Adding XObject image support to `PdfCompiler` requires ~25 lines of pure Dart code.
3. **How the existing viewport capture can be reused for PDF**: `ResearchGisScreen` can capture the `FlutterMap` viewport via `_mapRepaintKey` (`RenderRepaintBoundary.toImage()`) and pass `List<int>? mapImageBytes` to `ResearchMapPrintService.generatePdfBinary()`.
4. **How to preserve map extent, symbology, and aspect ratio**: Capturing `FlutterMap` via `RepaintBoundary` captures the exact rendered canvas, preserving current extent, visible layers, symbology, and aspect ratio. `PdfCompiler` calculates image box height ($H = W \times \text{height} / \text{width}$) to preserve aspect ratio on the PDF page.
5. **How to compose page elements without clipping**: Page 1 holds the Header Banner + Embedded Map Canvas ($540\text{pt} \times 270\text{pt}$ on A4 Landscape). Page 2 holds structured tabular sections for Extent, Represented Products, Dynamic Legend, Morphometrics, Workflow, and Provenance.
6. **Why Unicode characters are corrupted**: Multi-byte UTF-8 sequences for `°` and `²` conflict with PDF `/WinAnsiEncoding`. Mapping Unicode symbols to WinAnsi octal escape codes (`\260`, `\262`) or clean ASCII (`deg`, `km^2`, `-`) eliminates all rendering defects.
7. **Whether D8 labels correspond to actual raster values**: Yes, D8 codes ($1..128$) map to `HydrologicalAnalysisService` outputs. They should be rendered as discrete direction classes.
8. **How Strahler line-width symbology should be represented**: Described in text/markdown legend with line-weight hierarchy (`Order 1: 1.0pt`, `Order 2: 2.0pt`, `Order 3+: 3.0pt+`).
9. **Whether exported legend values correspond to actual raster data**: Yes, `CartographicService.generateLegend()` computes min/max values directly from valid `RasterData.values`.

---

## 3. MINIMAL REMEDIATION PLAN (AWAITING AUTHORIZATION)

1. **Surgical `PdfCompiler` Enhancement (`lib/data/services/pdf_compiler.dart`)**:
   - Add `/XObject /Subtype /Image` stream builder (`/Im1`).
   - Add `_sanitizePdfText()` for WinAnsi Unicode safety.
2. **Update `ResearchMapPrintService` (`lib/data/services/research_map_print_service.dart`)**:
   - Accept optional `List<int>? mapImageBytes` in `generatePdfBinary()`.
3. **Update `ResearchGisScreen._exportPdfMap` (`lib/screens/research_gis/research_gis_screen.dart`)**:
   - Capture `_mapRepaintKey` image before compiling PDF and pass to `ResearchMapPrintService`.
4. **Add Regression Tests (`test/research_map_print_test.dart`)**:
   - Verify PDF image embedding and WinAnsi text sanitization.

---

```
============================================================
RISKPULSE FORENSIC EXPORT AUDIT COMPLETE
STATUS: AWAITING REMEDIATION AUTHORIZATION
SCIENTIFIC & HYDROLOGICAL ALGORITHMS: 100% UNTOUCHED
COMMITS EXECUTED: 0 | PUSHES EXECUTED: 0
============================================================
```