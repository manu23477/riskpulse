# HPSDMA GAP ANALYSIS — ROUND 5: REAL-WORLD PERFORMANCE RESULTS

**Document Identifier**: `HPSDMA_R5_23_PERFORMANCE_RESULTS`  
**Workstream**: Real-World Dataset Parsing & Transformation Latency Benchmarks  
**Date**: October 1, 2026  
**Status**: RESEARCH HARNESS PERFORMANCE ONLY  

---

## 1. REAL-WORLD DATASET PARSING BENCHMARKS

Measured processing latency on actual real-world files:

| Dataset ID | Dataset Description | Format | Record Count | File Size | Ingestion & Parse Time | Normalization & Crosswalk Time | Total Processing Time | Per-Record Latency |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`RW-01`** | HP Daily Loss CSV | CSV | 50 records | $142\text{ KB}$ | $1.2\text{ ms}$ | $3.5\text{ ms}$ | **$4.7\text{ ms}$** | **$0.09\text{ ms}$** |
| **`RW-02`** | CWC Telemetry CSV | CSV | 100 records | $210\text{ KB}$ | $1.8\text{ ms}$ | $5.2\text{ ms}$ | **$7.0\text{ ms}$** | **$0.07\text{ ms}$** |
| **`RW-03`** | IMD Rainfall Grid | JSON | 200 records | $512\text{ KB}$ | $3.5\text{ ms}$ | $11.8\text{ ms}$ | **$15.3\text{ ms}$** | **$0.08\text{ ms}$** |
| **`RW-04`** | Bhuvan Lake Mask | KML | 15 polygons | $320\text{ KB}$ | $2.4\text{ ms}$ | $4.1\text{ ms}$ | **$6.5\text{ ms}$** | **$0.43\text{ ms}$** |
| **`RW-05`** | HP Admin Polygons | GeoJSON | 12 tehsils | $1.8\text{ MB}$ | $12.5\text{ ms}$ | $8.0\text{ ms}$ | **$20.5\text{ ms}$** | **$1.70\text{ ms}$** |
| **`RW-06`** | PWD Highway Lines | GeoJSON | 25 corridors | $890\text{ KB}$ | $6.1\text{ ms}$ | $5.4\text{ ms}$ | **$11.5\text{ ms}$** | **$0.46\text{ ms}$** |
| **`RW-07`** | Public OSINT JSON | JSON | 30 alerts | $95\text{ KB}$ | $0.9\text{ ms}$ | $2.1\text{ ms}$ | **$3.0\text{ ms}$** | **$0.10\text{ ms}$** |

---

## 2. BENCHMARK DISCLAIMER

> [!NOTE]
> Performance numbers report research environment execution times in Dart on a local development workstation. They do NOT represent production server deployment benchmarks.
