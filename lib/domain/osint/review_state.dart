/// Workflow state machine values for the human review and operational promotion gate.
enum ReviewState {
  pendingReview,
  underReview,
  approved,
  rejected,
  returnedForFurtherReview,
  promoted,
  promotionFailed,
}
