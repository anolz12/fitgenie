class WorkoutPlan {
  final String title;
  final String nextSync;
  final List<WorkoutPlanItem> items;

  const WorkoutPlan({
    required this.title,
    required this.nextSync,
    required this.items,
  });

  factory WorkoutPlan.sample() {
    return const WorkoutPlan(
      title: 'AI Plan v3.2',
      nextSync: 'Next sync 7:00 PM',
      items: [
        WorkoutPlanItem(label: 'Strength', detail: 'Upper focus - 5x5 strategy'),
        WorkoutPlanItem(label: 'Cardio', detail: 'Zone 2 ride - 18 min'),
        WorkoutPlanItem(label: 'Recovery', detail: 'Yoga flow - 12 min'),
      ],
    );
  }
}

class WorkoutPlanItem {
  final String label;
  final String detail;

  const WorkoutPlanItem({
    required this.label,
    required this.detail,
  });
}
