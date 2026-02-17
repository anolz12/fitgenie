import 'package:firebase_auth/firebase_auth.dart';

import 'goal_service.dart';
import 'progress_service.dart';
import 'stats_service.dart';
import 'wellness_service.dart';
import 'workout_service.dart';

class SeedService {
  SeedService._();
  static final SeedService instance = SeedService._();

  Future<void> run() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await StatsService.instance.seedIfMissing();
    await WorkoutService.instance.seedIfEmpty();
    await GoalService.instance.seedIfEmpty();
    await ProgressService.instance.seedIfEmpty();
    await WellnessService.instance.seedIfEmpty();
  }
}
