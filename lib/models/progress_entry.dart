class ProgressEntry {
  final String summary;

  const ProgressEntry({required this.summary});

  factory ProgressEntry.sample() {
    return const ProgressEntry(
      summary: 'Goal-driven analytics plus recovery tracking.',
    );
  }
}
