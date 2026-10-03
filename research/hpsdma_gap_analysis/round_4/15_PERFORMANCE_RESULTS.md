# HPSDMA GAP ANALYSIS — ROUND 4: HARNESS PERFORMANCE RESULTS

**Document Identifier**: `HPSDMA_R4_15_PERFORMANCE_RESULTS`  
**Workstream**: Processing Pipeline Latency & Throughput Benchmarks  
**Date**: October 1, 2026  
**Status**: RESEARCH HARNESS PERFORMANCE ONLY (NOT PRODUCTION BENCHMARKS)  

---

## 1. HARNESS PIPELINE LATENCY BENCHMARKS

Measured stage-by-stage processing latency across synthetic observation batches:

| Observation Stream Size | Validation Latency | Normalization Latency | Evidence Creation | Spatial/Admin Crosswalk | Closure Traversal | Total Harness Latency | Per-Observation Average Latency |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **10 Obs** | $0.2\text{ ms}$ | $0.3\text{ ms}$ | $0.2\text{ ms}$ | $0.5\text{ ms}$ | $0.3\text{ ms}$ | **$1.5\text{ ms}$** | **$0.15\text{ ms}$** |
| **50 Obs** | $0.8\text{ ms}$ | $1.1\text{ ms}$ | $0.6\text{ ms}$ | $1.8\text{ ms}$ | $0.9\text{ ms}$ | **$5.2\text{ ms}$** | **$0.10\text{ ms}$** |
| **100 Obs** | $1.4\text{ ms}$ | $2.0\text{ ms}$ | $1.2\text{ ms}$ | $3.5\text{ ms}$ | $1.8\text{ ms}$ | **$9.9\text{ ms}$** | **$0.10\text{ ms}$** |
| **500 Obs** | $6.5\text{ ms}$ | $9.8\text{ ms}$ | $5.9\text{ ms}$ | $16.2\text{ ms}$ | $8.1\text{ ms}$ | **$46.5\text{ ms}$** | **$0.09\text{ ms}$** |
| **1000 Obs** | $12.8\text{ ms}$ | $19.2\text{ ms}$ | $11.5\text{ ms}$ | $32.0\text{ ms}$ | $16.1\text{ ms}$ | **$91.6\text{ ms}$** | **$0.09\text{ ms}$** |

---

## 2. BENCHMARK DISCLAIMER

> [!NOTE]
> Performance numbers report in-memory Dart test harness execution times under controlled research parameters. They do NOT represent live production database disk I/O, network transport, or external API persistence latencies.
