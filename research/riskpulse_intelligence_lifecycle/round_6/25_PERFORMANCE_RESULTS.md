# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: PERFORMANCE RESULTS

**Document Identifier**: `RISKPULSE_R6_25_PERFORMANCE_RESULTS`  
**Workstream**: Processing Pipeline Benchmarks on Scale Graphs (100 to 5000 Nodes)  
**Date**: October 1, 2026  
**Status**: RESEARCH HARNESS PERFORMANCE ONLY  

---

## 1. SCALE GRAPH BENCHMARK RESULTS

Measured processing performance across scale graphs from 100 to 5000 nodes:

| Scale Graph Size | Total DAG Nodes | Strategy A Full Rebuild Time | Strategy C Closure Traversal Time | Recomputation Reduction (`L28`) | Average Traversal Latency |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **100 Nodes** | 314 | $12.5\text{ ms}$ | **$0.3\text{ ms}$** | **97.60%** | $0.075\text{ ms/node}$ |
| **500 Nodes** | 1,570 | $68.0\text{ ms}$ | **$0.9\text{ ms}$** | **98.67%** | $0.043\text{ ms/node}$ |
| **1000 Nodes** | 3,140 | $142.0\text{ ms}$ | **$1.8\text{ ms}$** | **98.73%** | $0.036\text{ ms/node}$ |
| **5000 Nodes** | 15,700 | $780.0\text{ ms}$ | **$8.5\text{ ms}$** | **98.91%** | $0.024\text{ ms/node}$ |

---

## 2. BENCHMARK DISCLAIMER

> [!NOTE]
> Benchmarks reflect in-memory Dart test execution times under controlled research conditions. They do NOT represent live production database disk I/O, network transport, or multi-tenant cloud persistence latencies.
