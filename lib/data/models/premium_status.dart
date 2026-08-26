class PremiumStatus {
  final bool isPremium;
  final bool isLoading;
  final bool isAvailable;
  final String? errorMessage;

  const PremiumStatus({
    this.isPremium = false,
    this.isLoading = false,
    this.isAvailable = false,
    this.errorMessage,
  });

  PremiumStatus copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? isAvailable,
    String? errorMessage,
  }) {
    return PremiumStatus(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      isAvailable: isAvailable ?? this.isAvailable,
      errorMessage: errorMessage,
    );
  }
}
