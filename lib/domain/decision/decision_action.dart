/// Controlled classification of decision actions for emergency management decision support.
enum DecisionAction {
  monitor,
  verify,
  inspect,
  assess,
  warn,
  restrictAccess,
  closeRoad,
  protectCriticalAsset,
  prepareEvacuation,
  deployResource,
  openShelter,
  restoreAccess;

  static DecisionAction fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final action in DecisionAction.values) {
      if (action.name.toLowerCase() == normalized) {
        return action;
      }
    }
    return DecisionAction.monitor;
  }
}
