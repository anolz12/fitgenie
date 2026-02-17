import 'package:flutter/material.dart';

import '../models/workout_plan.dart';
import '../services/ai_content_service.dart';
import '../services/plan_service.dart';
import '../theme/app_theme.dart';

class AIWorkoutPlanScreen extends StatefulWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  State<AIWorkoutPlanScreen> createState() => _AIWorkoutPlanScreenState();
}

class _AIWorkoutPlanScreenState extends State<AIWorkoutPlanScreen> {
  String _goal = 'Build muscle';
  String _equipment = 'Dumbbells';
  String _time = '45 min';
  String _level = 'Intermediate';
  WorkoutPlan? _generatedPlan;
  bool _isGenerating = false;
  bool _prefsLoaded = false;

  static const List<String> _goals = [
    'Build muscle',
    'Lose weight',
    'Endurance',
    'General fitness',
  ];
  static const List<String> _equipmentList = [
    'None',
    'Dumbbells',
    'Resistance bands',
    'Full gym',
    'Kettlebell',
  ];
  static const List<String> _times = ['15 min', '30 min', '45 min', '60 min'];
  static const List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  void _generatePlan() {
    setState(() => _isGenerating = true);
    Future<void>(() async {
      final aiPlan = await AIContentService.instance.generateWorkoutPlan(
        goal: _goal,
        equipment: _equipment,
        timePerSession: _time,
        fitnessLevel: _level,
      );

      final plan =
          aiPlan ??
          WorkoutPlan(
            title: 'AI Plan v1 · $_level',
            nextSync: 'Next sync: Sun 7:00 PM',
            items: _buildFallbackItems(),
          );

      await PlanService.instance.saveGeneratedPlan(
        title: plan.title,
        nextSync: plan.nextSync,
        items: plan.items,
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generatedPlan = plan;
      });
    });
  }

  List<WorkoutPlanItem> _buildFallbackItems() {
    final base = [
      const WorkoutPlanItem(label: 'Strength', detail: 'Upper focus · 5x5'),
      WorkoutPlanItem(label: 'Cardio', detail: 'Zone 2 · $_time'),
      const WorkoutPlanItem(
        label: 'Recovery',
        detail: 'Mobility flow · 12 min',
      ),
    ];
    if (_goal == 'Lose weight') {
      return [
        const WorkoutPlanItem(label: 'HIIT', detail: 'Intervals · 20 min'),
        const WorkoutPlanItem(label: 'Strength', detail: 'Compound moves'),
        ...base.skip(2),
      ];
    }
    if (_goal == 'Endurance') {
      return [
        const WorkoutPlanItem(label: 'Cardio', detail: 'Long steady · 40 min'),
        const WorkoutPlanItem(label: 'Strength', detail: 'Maintenance'),
        ...base.skip(2),
      ];
    }
    return base;
  }

  void _applySavedData(SavedPlanData? saved) {
    if (saved == null || _prefsLoaded) return;
    _prefsLoaded = true;
    _goal = saved.goal;
    _equipment = saved.equipment;
    _time = saved.timePerSession;
    _level = saved.fitnessLevel;
    _generatedPlan = saved.toWorkoutPlan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Workout Plan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<SavedPlanData?>(
        stream: PlanService.instance.stream(),
        builder: (context, snap) {
          _applySavedData(snap.data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const _SectionTitle(
                title: 'Your preferences',
                subtitle: 'AI will tailor your plan and adjust weekly.',
              ),
              const SizedBox(height: 16),
              _ChipSection(
                title: 'Goal',
                value: _goal,
                options: _goals,
                onSelect: (v) {
                  setState(() => _goal = v);
                  PlanService.instance.savePreferences(
                    goal: v,
                    equipment: _equipment,
                    timePerSession: _time,
                    fitnessLevel: _level,
                  );
                },
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Equipment',
                value: _equipment,
                options: _equipmentList,
                onSelect: (v) {
                  setState(() => _equipment = v);
                  PlanService.instance.savePreferences(
                    goal: _goal,
                    equipment: v,
                    timePerSession: _time,
                    fitnessLevel: _level,
                  );
                },
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Time per session',
                value: _time,
                options: _times,
                onSelect: (v) {
                  setState(() => _time = v);
                  PlanService.instance.savePreferences(
                    goal: _goal,
                    equipment: _equipment,
                    timePerSession: v,
                    fitnessLevel: _level,
                  );
                },
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Fitness level',
                value: _level,
                options: _levels,
                onSelect: (v) {
                  setState(() => _level = v);
                  PlanService.instance.savePreferences(
                    goal: _goal,
                    equipment: _equipment,
                    timePerSession: _time,
                    fitnessLevel: v,
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generatePlan,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate my plan',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_generatedPlan != null) ...[
                const SizedBox(height: 28),
                const _SectionTitle(
                  title: 'Your plan',
                  subtitle: 'Adaptive difficulty - auto-adjusts weekly.',
                ),
                const SizedBox(height: 12),
                _PlanCard(plan: _generatedPlan!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelect;

  const _ChipSection({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (opt) => FilterChip(
                  label: Text(opt),
                  selected: value == opt,
                  onSelected: (_) => onSelect(opt),
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                  side: BorderSide(
                    color: value == opt ? AppTheme.primary : AppTheme.border,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.nextSync,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: theme.textTheme.titleMedium),
                        Text(
                          item.detail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
