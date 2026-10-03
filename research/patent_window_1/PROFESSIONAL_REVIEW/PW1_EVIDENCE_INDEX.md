# RISKPULSE PATENT WINDOW 1: EVIDENCE INDEX

This index maps every major research conclusion to its authoritative experimental report, manifest, and result JSON file.

---

## 1. MILESTONE EVIDENCE INDEX

| Milestone | Subject Matter | Primary Report File | Result Artifact Directory / File |
| :---: | :--- | :--- | :--- |
| **PW1C-1A** | Frozen Dataset Generation | `PW1C1A_DATASET_GENERATION_FORENSIC_REPORT.md` | `dataset/manifest/dataset_manifest.json` |
| **PW1C-1B** | Experimental Harness Contract | `PW1C1B_EXPERIMENTAL_HARNESS_ARCHITECTURE_REPORT.md` | `contracts/metric_contract.dart` |
| **PW1C-2A** | Baseline Fusion Reconciliation | `PW1C2A_BASELINE_COMPARATIVE_EXPERIMENT_REPORT.md` | `experiments/results/PW1C2A-E01/` |
| **PW1C-2B** | Controlled Dependency Propagation | `PW1C2B_CONTROLLED_PROPAGATION_EXPERIMENT_REPORT.md` | `experiments/results/PW1C2B-E02/` |
| **PW1C-3** | Deep Mutation & Multi-Gen State History | `PW1C3_DEEP_MUTATION_DEPENDENCY_EXPERIMENT_REPORT.md` | `experiments/results/PW1C3/` |
| **PW1C-4** | Prior-Art Boundary Mapping | `PW1C4_PRIOR_ART_BOUNDARY_MAPPING_REPORT.md` | `experiments/results/PW1C4/` |
| **PW1C-5** | Continuous Stream & Shared Dependency | `PW1C5_CONTINUOUS_SHARED_DEPENDENCY_EXPERIMENT_REPORT.md` | `experiments/results/PW1C5/` |
| **PW1C-5R** | Reference Validation & Collision Audit | `PW1C5R_COMBINATION_COLLISION_AUDIT_REPORT.md` | `experiments/results/PW1C5R/` |
| **PW1C-5S** | Boundary Stress Test | `PW1C5S_BOUNDARY_STRESS_TEST_REPORT.md` | `experiments/results/PW1C5S/` |
| **PW1C-6** | Exact Technical Boundary Decomposition | `PW1C6_EXACT_TECHNICAL_BOUNDARY_DECOMPOSITION_REPORT.md` | `experiments/results/PW1C6/` |
| **PW1C-6R** | Targeted Collision Audit of Minimal Boundaries | `PW1C6R_TARGETED_COLLISION_AUDIT_REPORT.md` | `experiments/results/PW1C6R/` |

---

## 2. KEY EXPERIMENTAL CLAIM EVIDENCE MAPPING

- **89.62% to 99.91% Recomputation Reduction**: Evidenced in `PW1C-2B` ($M28 = 90.51\%$), `PW1C-3` ($M40 = 89.62\%$), `PW1C-5` ($M59 = 90.86\%$), `PW1C-5S` ($S21 = 91.20\%..99.91\%$).
- **100% Full-Rebuild State Equivalence**: Evidenced in `PW1C-3` ($M45 = 1.0$), `PW1C-5` ($M60 = 1.0$), `PW1C-5S` ($S01 = 1.0$, $S17 = 1.0$), `PW1C-6` ($B03 = 1.0$).
- **100% Cross-Event Isolation**: Evidenced in `PW1C-3` ($M36 = 1.0$), `PW1C-5` ($M63 = 1.0$), `PW1C-5S` ($S02 = 1.0$, $S19 = 0$), `PW1C-6` ($B04 = 1.0$).
- **1000 mut/sec Continuous Stream Convergence**: Evidenced in `PW1C-5` ($M51..M55$).
- **Ablation Minimality Proof (70% Failure Rate on Component Removal)**: Evidenced in `PW1C-6` ($B02 = 0.70$, `pw1c6_ablation_results.json`).
- **100% Counterexample Survival**: Evidenced in `PW1C-6` ($B15 = 1.0$, `pw1c6_counterexample_results.json`).
- **Targeted Prior-Art Single-Reference Coverage (Partial Coverage Only)**: Evidenced in `PW1C-5R` (`PW1C5R_COMBINATION_COLLISION_AUDIT_REPORT.md`) and `PW1C-6R` (`PW1C6R_TARGETED_COLLISION_AUDIT_REPORT.md`).
