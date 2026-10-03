/// Explicit lifecycle status categories for Administrative State records.
enum AdministrativeStateStatus {
  active,
  superseded,
  invalidated,
  withdrawn,
  unavailable;

  static AdministrativeStateStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in AdministrativeStateStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return AdministrativeStateStatus.active;
  }
}
