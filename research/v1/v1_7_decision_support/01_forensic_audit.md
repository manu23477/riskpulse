# V1.7 FORENSIC DECISION SUPPORT INVENTORY & AUDIT

**Document Identifier**: `V1_7_FORENSIC_DECISION_AUDIT`  
**Workstream**: Forensic Audit of Existing Decision Support, Warning & Priority Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC AUDIT  

---

## 1. INVENTORY OF EXISTING DECISION SUPPORT STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`DecisionRecommendation`**| `lib/domain/decision/decision_recommendation.dart` | `recommendationId`, `action`, `priority`, `urgency` | Structured Decision | **`NEW`** V1.7 Core Object |
| **`DecisionAction`** | `lib/domain/decision/decision_action.dart` | `monitor`, `inspect`, `closeRoad`, `evacuate` | Structured Action Enum | **`NEW`** V1.7 Core Enum |
| **`DecisionSupportService`**| `lib/data/services/decision/decision_support_service.dart` | `evaluateDecisionSupport()`, `applyHumanReview()` | Decision Support Gateway | **`NEW`** V1.7 Core Service |

---

## 2. GAPS & V1.7 IMPLEMENTATION BOUNDARY

1. **V1.7 IS DECISION SUPPORT, NOT ALERT DELIVERY (V1.11)**: V1.7 derives action recommendations and rationale; V1.11 handles alert delivery infrastructure (SMS/push).
2. **SYSTEM RECOMMENDATION != HUMAN DECISION != OFFICIAL ORDER**: Evacuation orders or road closures must NEVER be automatically issued by a score. Human review is explicitly recorded via `applyHumanReview()`.
