class AdminStatsState {
  final Map<String, int> stats;
  final bool isLoading;
  final String? error;

  const AdminStatsState({
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  AdminStatsState copyWith({
    Map<String, int>? stats,
    bool? isLoading,
    String? error,
  }) {
    return AdminStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

