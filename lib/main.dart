import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'models/wellness_session.dart';
import 'models/workout.dart';
import 'screens/ai_workout_plan_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/chatbot_service.dart';
import 'services/seed_service.dart';
import 'services/user_service.dart';
import 'services/wellness_service.dart';
import 'services/stats_service.dart';
import 'services/workout_service.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/recovery_plan_service.dart';
import 'services/ai_content_service.dart';
import 'utils/beep_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(NotificationService.backgroundHandler);
  await NotificationService.instance.init();
  runApp(const FitGenieApp());
}

class FitGenieApp extends StatelessWidget {
  const FitGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitGenie',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const WelcomePage();
        }
        return FutureBuilder<bool>(
          future: UserService.instance.isOnboardingComplete(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (onboardingSnapshot.data == true) {
              return const MainShell();
            }
            return const OnboardingPage();
          },
        );
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2C7DD8).withOpacity(0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/fitgenie_logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FitGenie',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-Powered Fitness & Wellness',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthPage(
                                startLogin: false,
                                showToggle: false,
                              ),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthPage(
                                startLogin: true,
                                showToggle: false,
                              ),
                            ),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  final bool startLogin;
  final bool showToggle;
  const AuthPage({super.key, this.startLogin = true, this.showToggle = true});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool _isLogin = widget.startLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                Text(
                  'FitGenie',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: const Color(0xFF7DD3FC),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-powered fitness coaching with mindful recovery.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      if (widget.showToggle)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 360;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  _AuthToggleButton(
                                    label: 'Login',
                                    isActive: _isLogin,
                                    onTap: () {
                                      if (!widget.showToggle) return;
                                      setState(() => _isLogin = true);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AuthToggleButton(
                                    label: 'Register',
                                    isActive: !_isLogin,
                                    onTap: () {
                                      if (!widget.showToggle) return;
                                      setState(() => _isLogin = false);
                                    },
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _AuthToggleButton(
                                    label: 'Login',
                                    isActive: _isLogin,
                                    onTap: () {
                                      if (!widget.showToggle) return;
                                      setState(() => _isLogin = true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _AuthToggleButton(
                                    label: 'Register',
                                    isActive: !_isLogin,
                                    onTap: () {
                                      if (!widget.showToggle) return;
                                      setState(() => _isLogin = false);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      if (widget.showToggle) const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isLogin
                            ? const LoginForm()
                            : const RegisterForm(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'By continuing, you agree to personalized recommendations and progress tracking.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF22C6A3) : const Color(0xFFF3F6FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isActive ? Colors.black : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login'),
      children: [
        _AuthField(controller: _emailController, label: 'Email'),
        const SizedBox(height: 12),
        _AuthField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
          ),
        if (_error != null) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C6A3),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Login'),
          ),
        ),
      ],
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('register'),
      children: [
        _AuthField(controller: _nameController, label: 'Full Name'),
        const SizedBox(height: 12),
        _AuthField(controller: _emailController, label: 'Email'),
        const SizedBox(height: 12),
        _AuthField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
          ),
        if (_error != null) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C6A3),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Create account'),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF3F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    WorkoutsPage(),
    CoachPage(),
    WellnessPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    SeedService.instance.run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(child: _pages[_index]),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String _focus = 'Strength';
  String _goal = 'Lean muscle';
  int _sessions = 4;
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await UserService.instance.completeOnboarding(
        focus: _focus,
        goal: _goal,
        sessionsPerWeek: _sessions,
      );
    } catch (error) {
      setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                Text(
                  'Welcome to FitGenie',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us your focus so the AI coach can personalize your plan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _OnboardingSection(
                  title: 'Primary Focus',
                  child: _SegmentedPicker(
                    values: const ['Strength', 'Endurance', 'Mobility'],
                    selected: _focus,
                    onChanged: (value) => setState(() => _focus = value),
                  ),
                ),
                const SizedBox(height: 18),
                _OnboardingSection(
                  title: 'Main Goal',
                  child: _SegmentedPicker(
                    values: const ['Lean muscle', 'Fat loss', 'Athletic'],
                    selected: _goal,
                    onChanged: (value) => setState(() => _goal = value),
                  ),
                ),
                const SizedBox(height: 18),
                _OnboardingSection(
                  title: 'Sessions / Week',
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _sessions.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          label: '$_sessions',
                          onChanged: (value) =>
                              setState(() => _sessions = value.round()),
                        ),
                      ),
                      Text(
                        '$_sessions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                  ),
                if (_error != null) const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C6A3),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Finish setup'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _OnboardingSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedPicker({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) => onChanged(value),
              selectedColor: const Color(0xFF22C6A3),
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected == value ? Colors.black : Colors.black87,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEAF2FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(color: Color(0xFF2C7DD8), size: 220),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowOrb(color: Color(0xFF22C6A3), size: 260),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF12061F), Color(0xFF2A1240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(color: Color(0xFF9B5DE5), size: 220),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowOrb(color: Color(0xFF5A189A), size: 260),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.45), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: StatsService.instance.stream(),
      builder: (context, statsSnap) {
        return StreamBuilder<List<Workout>>(
          stream: WorkoutService.instance.streamWorkouts(),
          builder: (context, workoutSnap) {
            final stats = statsSnap.data;
            final workouts = workoutSnap.data ?? [];
            final steps = stats?['steps']?.toString() ?? '--';
            final calories = stats?['calories']?.toString() ?? '--';
            final activeMin = stats?['activeMinutes']?.toString() ?? '--';
            final dailySummary = _DailySummary(
              steps: steps,
              calories: calories,
              activeMinutes: activeMin,
            );
            final weekly = _weeklyMetrics(workouts);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                const _FadeSlideIn(delayMs: 0, child: _TopBar()),
                const SizedBox(height: 16),
                _FadeSlideIn(
                  delayMs: 80,
                  child: Text(
                    'Hey, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Athlete'}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FadeSlideIn(
                  delayMs: 100,
                  child: _DailySummaryCard(summary: dailySummary),
                ),
                const SizedBox(height: 18),
                _FadeSlideIn(
                  delayMs: 140,
                  child: Text(
                    'Weekly progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _FadeSlideIn(
                  delayMs: 160,
                  child: _WeeklyChartCard(
                    calorieBars: weekly.calorieBars,
                    consistencyBars: weekly.consistencyBars,
                    totalCalories: weekly.totalCalories,
                    consistencyPercent: weekly.consistencyPercent,
                  ),
                ),
                const SizedBox(height: 18),
                _FadeSlideIn(
                  delayMs: 200,
                  child: _SmartStatRow(
                    caloriesBurned: weekly.totalCalories.toString(),
                    workoutConsistency: '${weekly.consistencyPercent.round()}%',
                  ),
                ),
                const SizedBox(height: 20),
                _FadeSlideIn(
                  delayMs: 220,
                  child: _AIPlanCtaCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AIWorkoutPlanScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<RecoveryPlanData>(
                  stream: RecoveryPlanService.instance.stream(),
                  builder: (context, recoverySnap) {
                    final data =
                        recoverySnap.data ?? RecoveryPlanData.defaults();
                    return Column(
                      children: [
                        _FadeSlideIn(
                          delayMs: 225,
                          child: _SmartRecoveryCard(data: data),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          delayMs: 235,
                          child: _SmartNotificationsCard(data: data),
                        ),
                        const SizedBox(height: 14),
                        _FadeSlideIn(
                          delayMs: 245,
                          child: _PlanHighlightsCard(data: data),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _FadeSlideIn(
                  delayMs: 255,
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CoachPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.smart_toy_outlined, size: 20),
                          label: const Text('Ask FitGenie'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await HealthService.instance
                              .syncToday();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync, size: 20),
                        label: const Text('Sync'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _FadeSlideIn(
                  delayMs: 260,
                  child: Text(
                    'AI Insights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _FadeSlideIn(
                  delayMs: 280,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Your cardio base is improving. Aim for 2 zone-2 sessions this week and one strength session.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FadeSlideIn(
                  delayMs: 300,
                  child: Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const _UpcomingTile(
                  title: 'Strength · Lower Body',
                  subtitle: 'Tomorrow · 45 min',
                  icon: Icons.fitness_center,
                ),
                const _UpcomingTile(
                  title: 'Mindful Flow',
                  subtitle: 'Wed · 12 min',
                  icon: Icons.self_improvement,
                ),
                const SizedBox(height: 18),
                _FadeSlideIn(
                  delayMs: 320,
                  child: Text(
                    'Today\'s focus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _FocusTile(
                        title: 'Recommended Workout',
                        subtitle: 'High-intensity interval training',
                        accent: Color(0xFFE9E9E9),
                        imagePath: 'assets/images/cycling.jpg',
                      ),
                      SizedBox(width: 14),
                      _FocusTile(
                        title: 'Mental Wellness',
                        subtitle: 'Guided meditation',
                        accent: Color(0xFFF1D6A2),
                        imagePath: 'assets/images/stretching.jpg',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DailySummary {
  final String steps;
  final String calories;
  final String activeMinutes;
  _DailySummary({
    required this.steps,
    required this.calories,
    required this.activeMinutes,
  });
}

class _WeeklyMetrics {
  final List<double> calorieBars;
  final List<double> consistencyBars;
  final int totalCalories;
  final double consistencyPercent;
  _WeeklyMetrics({
    required this.calorieBars,
    required this.consistencyBars,
    required this.totalCalories,
    required this.consistencyPercent,
  });
}

_WeeklyMetrics _weeklyMetrics(List<Workout> workouts) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final map = <DateTime, int>{};
  final countMap = <DateTime, int>{};
  for (var i = 0; i < 7; i++) {
    final d = start.add(Duration(days: i));
    map[d] = 0;
    countMap[d] = 0;
  }
  for (final w in workouts) {
    final completed = w.completedAt;
    if (completed == null) continue;
    final day = DateTime(completed.year, completed.month, completed.day);
    if (!day.isBefore(start) && !day.isAfter(today)) {
      map[day] = (map[day] ?? 0) + w.durationMinutes;
      countMap[day] = (countMap[day] ?? 0) + 1;
    }
  }
  final bars = map.values.map((m) => (m * 8).toDouble()).toList();
  final maxBar = bars.isEmpty
      ? 1.0
      : bars.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
  final consistencyBars = countMap.values
      .map((c) => (c / 2).clamp(0.0, 1.0).toDouble())
      .toList();
  final totalCalories = bars.fold<int>(0, (a, b) => a + b.toInt());
  final workoutCount = countMap.values.fold<int>(0, (a, b) => a + b);
  final consistencyPercent = (workoutCount / 7 * 100).clamp(0.0, 100.0);
  return _WeeklyMetrics(
    calorieBars: bars.map((b) => b / maxBar).toList(),
    consistencyBars: consistencyBars,
    totalCalories: totalCalories,
    consistencyPercent: consistencyPercent,
  );
}

class _DailySummaryCard extends StatelessWidget {
  final _DailySummary summary;

  const _DailySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientCardDecoration(
        colors: [AppTheme.primary, AppTheme.primaryDark],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DailyStat(label: 'Steps', value: summary.steps),
              const SizedBox(width: 24),
              _DailyStat(label: 'Calories', value: summary.calories),
              const SizedBox(width: 24),
              _DailyStat(label: 'Active min', value: summary.activeMinutes),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  final String label;
  final String value;

  const _DailyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  final List<double> calorieBars;
  final List<double> consistencyBars;
  final int totalCalories;
  final double consistencyPercent;

  const _WeeklyChartCard({
    required this.calorieBars,
    required this.consistencyBars,
    required this.totalCalories,
    required this.consistencyPercent,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calories burned',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$totalCalories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final h = (calorieBars.length > i ? calorieBars[i] : 0.0) * 56;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: h.clamp(4.0, 56.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartStatRow extends StatelessWidget {
  final String caloriesBurned;
  final String workoutConsistency;

  const _SmartStatRow({
    required this.caloriesBurned,
    required this.workoutConsistency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: AppTheme.accentAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Calories burned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  caloriesBurned,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Workout consistency',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  workoutConsistency,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AIPlanCtaCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AIPlanCtaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration:
              AppTheme.cardDecoration(
                color: AppTheme.primary.withOpacity(0.06),
              ).copyWith(
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Personalized Workout Plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal · Equipment · Time · Level · Adaptive weekly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartRecoveryCard extends StatelessWidget {
  final RecoveryPlanData data;

  const _SmartRecoveryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: AppTheme.accentViolet,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Recovery Engine',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RecoveryRow(
            icon: Icons.bedtime,
            label: 'Rest day alerts',
            value: data.restDayAlert,
          ),
          const SizedBox(height: 8),
          _RecoveryRow(
            icon: Icons.warning_amber_rounded,
            label: 'Overtraining detection',
            value: data.overtrainingStatus,
          ),
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecoveryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SmartNotificationsCard extends StatelessWidget {
  final RecoveryPlanData data;

  const _SmartNotificationsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.accentAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _NotifRow(
            icon: Icons.auto_awesome,
            label: 'AI motivational messages',
            enabled: data.aiMotivation,
          ),
          const SizedBox(height: 6),
          _NotifRow(
            icon: Icons.fitness_center,
            label: 'Workout reminders',
            enabled: data.workoutReminders,
          ),
          const SizedBox(height: 6),
          _NotifRow(
            icon: Icons.local_fire_department,
            label: 'Streak protection alerts',
            enabled: data.streakProtection,
          ),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _NotifRow({
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.primary : AppTheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
        Text(
          enabled ? 'On' : 'Off',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: enabled ? AppTheme.primary : AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PlanHighlightsCard extends StatelessWidget {
  final RecoveryPlanData data;

  const _PlanHighlightsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your plan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PlanHighlightRow(
            icon: Icons.schedule,
            label: 'Adaptive difficulty',
            value: data.adaptiveDifficulty,
          ),
          const SizedBox(height: 8),
          _PlanHighlightRow(
            icon: Icons.home,
            label: 'Home & gym workouts',
            value: data.homeGymWorkouts,
          ),
          const SizedBox(height: 8),
          _PlanHighlightRow(
            icon: Icons.bedtime,
            label: 'Rest day recommendations',
            value: data.restDayRecommendations,
          ),
        ],
      ),
    );
  }
}

class _PlanHighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PlanHighlightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C7DD8).withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/fitgenie_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'FitGenie',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
          },
          icon: const Icon(Icons.settings_outlined, color: Colors.black87),
        ),
      ],
    );
  }
}

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _FocusTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String? imagePath;

  const _FocusTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: imagePath == null
                    ? LinearGradient(
                        colors: [
                          accent.withOpacity(0.7),
                          accent.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: imagePath == null
                    ? null
                    : DecorationImage(
                        image: AssetImage(imagePath!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: imagePath == null
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.black26,
                        size: 48,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CoachPageState extends State<CoachPage> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[
    ChatMessage(
      text:
          'How should I train if I only have 25 minutes today? I still want to build strength.',
      isUser: true,
    ),
    ChatMessage(
      text:
          'Let\'s do a 20-min compound circuit: goblet squats, push-ups, rows, and lunges. Then 5 min breathing.',
      isUser: false,
    ),
  ];

  bool _isSending = false;
  final _quickReplies = const [
    'Shorten my workout',
    'Focus lower body',
    'Add recovery tips',
    'Give me a warm-up',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
    });
    final response = await ChatbotService.instance.sendMessage(text);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'AI Fitness Chatbot',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ask FitGenie for workouts, form tips, or motivation.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Pill(label: 'Coach Mode', color: Color(0xFF2C7DD8)),
                  _Pill(label: 'Recovery Focus', color: Color(0xFF22C6A3)),
                  _Pill(label: 'Strength Plan', color: Color(0xFF7C5CFF)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _ChatBubble(
                      text: 'FitGenie is typing...',
                      isUser: false,
                      isTyping: true,
                    );
                  }
                  final message = _messages[index];
                  return _ChatBubble(
                    text: message.text,
                    isUser: message.isUser,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReplies
                    .map(
                      (q) => ActionChip(
                        label: Text(q),
                        onPressed: _isSending
                            ? null
                            : () {
                                _controller.text = q;
                                _send();
                              },
                      ),
                    )
                    .toList(),
              ),
            ),
            _ChatComposer(
              controller: _controller,
              isSending: _isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  String? _selectedCategory;
  bool _isGeneratingAi = false;

  @override
  void initState() {
    super.initState();
    WorkoutService.instance.ensureLibrary();
  }

  Future<void> _generateAiWorkouts() async {
    setState(() => _isGeneratingAi = true);
    final generated = await AIContentService.instance.generateWorkouts(
      goal: 'General fitness',
      equipment: 'Mixed',
      timePerSession: '30 min',
      fitnessLevel: 'Intermediate',
    );
    var inserted = 0;
    for (final workout in generated) {
      final added = await WorkoutService.instance.addWorkoutIfNotDuplicate(
        workout,
      );
      if (added) inserted++;
    }
    if (!mounted) return;
    setState(() => _isGeneratingAi = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          generated.isEmpty
              ? 'AI workout generation unavailable right now.'
              : (inserted == 0
                    ? 'No new AI workouts (duplicates skipped).'
                    : 'Added $inserted AI workouts.'),
        ),
      ),
    );
  }

  _WorkoutMeta _metaFor(Workout workout) {
    final focus = workout.focus.toLowerCase();
    if (focus.contains('strength')) {
      return const _WorkoutMeta(
        Icons.fitness_center,
        Color(0xFF2C7DD8),
        'Strength',
      );
    }
    if (focus.contains('endurance') || focus.contains('cardio')) {
      return const _WorkoutMeta(Icons.speed, Color(0xFF22C6A3), 'Cardio');
    }
    if (focus.contains('core')) {
      return const _WorkoutMeta(
        Icons.center_focus_strong,
        Color(0xFF7C5CFF),
        'Core',
      );
    }
    if (focus.contains('no-equipment')) {
      return const _WorkoutMeta(
        Icons.sports_gymnastics,
        Color(0xFFEE6C4D),
        'No-equipment',
      );
    }
    if (focus.contains('resistance band') || focus.contains('band')) {
      return const _WorkoutMeta(
        Icons.all_inclusive,
        Color(0xFF0EA5E9),
        'Bands',
      );
    }
    if (focus.contains('dumbbell')) {
      return const _WorkoutMeta(
        Icons.fitness_center,
        Color(0xFF1D4ED8),
        'Dumbbells',
      );
    }
    if (focus.contains('mobility')) {
      return const _WorkoutMeta(
        Icons.self_improvement,
        Color(0xFF10B981),
        'Mobility',
      );
    }
    if (focus.contains('recovery') || focus.contains('mobility')) {
      return const _WorkoutMeta(
        Icons.self_improvement,
        Color(0xFF7C5CFF),
        'Recovery',
      );
    }
    if (focus.contains('interval')) {
      return const _WorkoutMeta(Icons.timer, Color(0xFFEE6C4D), 'Intervals');
    }
    if (focus.contains('performance')) {
      return const _WorkoutMeta(Icons.bolt, Color(0xFF0EA5E9), 'Performance');
    }
    return const _WorkoutMeta(
      Icons.fitness_center,
      Color(0xFF2C7DD8),
      'Training',
    );
  }

  bool _matchesCategory(Workout workout, String category) {
    final focus = workout.focus.toLowerCase();
    final label = category.toLowerCase();
    if (label.contains('cardio')) {
      return focus.contains('cardio') || focus.contains('endurance');
    }
    if (label.contains('core')) return focus.contains('core');
    if (label.contains('no-equipment')) {
      return focus.contains('no-equipment') || focus.contains('bodyweight');
    }
    if (label.contains('resistance')) return focus.contains('band');
    if (label.contains('dumbbell')) return focus.contains('dumbbell');
    if (label.contains('mobility')) {
      return focus.contains('mobility') || focus.contains('recovery');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: WorkoutService.instance.streamWorkouts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final workouts = snapshot.data!;
        final featured = workouts.take(3).toList();
        const categories = [
          _WorkoutMeta(Icons.speed, Color(0xFF22C6A3), 'Cardio'),
          _WorkoutMeta(Icons.center_focus_strong, Color(0xFF7C5CFF), 'Core'),
          _WorkoutMeta(
            Icons.sports_gymnastics,
            Color(0xFFEE6C4D),
            'No-equipment',
          ),
          _WorkoutMeta(
            Icons.all_inclusive,
            Color(0xFF0EA5E9),
            'Resistance band',
          ),
          _WorkoutMeta(Icons.fitness_center, Color(0xFF1D4ED8), 'Dumbbells'),
          _WorkoutMeta(Icons.self_improvement, Color(0xFF10B981), 'Mobility'),
        ];
        final filtered = _selectedCategory == null
            ? workouts
            : workouts
                  .where((w) => _matchesCategory(w, _selectedCategory!))
                  .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Workouts',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isGeneratingAi ? null : _generateAiWorkouts,
                  icon: _isGeneratingAi
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _isGeneratingAi ? 'Generating...' : 'AI Generate',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Personalized plans and AI-guided sessions.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final selected = _selectedCategory == item.label;
                  return _CategoryChip(
                    meta: item,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = selected ? null : item.label;
                      });
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: categories.length,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Today\'s Plan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final w in featured)
              _WorkoutTile(
                title: w.title,
                duration: '${w.durationMinutes} min',
                intensity: w.focus,
                meta: _metaFor(w),
                workout: w,
              ),
            const SizedBox(height: 18),
            Text(
              _selectedCategory == null
                  ? 'All Sessions'
                  : '${_selectedCategory!} Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final w in filtered)
              _WorkoutTile(
                title: w.title,
                duration: '${w.durationMinutes} min',
                intensity: w.focus,
                meta: _metaFor(w),
                workout: w,
              ),
          ],
        );
      },
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final String title;
  final String duration;
  final String intensity;
  final _WorkoutMeta meta;
  final Workout workout;

  const _WorkoutTile({
    required this.title,
    required this.duration,
    required this.intensity,
    required this.meta,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '$duration - $intensity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                _Pill(label: meta.label, color: meta.color),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(workout: workout),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _WorkoutMeta(this.icon, this.color, this.label);
}

class _CategoryChip extends StatelessWidget {
  final _WorkoutMeta meta;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? meta.color.withOpacity(0.18)
                : meta.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: meta.color.withOpacity(selected ? 0.7 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(meta.icon, size: 16, color: meta.color),
              const SizedBox(width: 8),
              Text(
                meta.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isTyping;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF22C6A3) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: Colors.black12),
        ),
        child: isTyping
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _TypingDot(delayMs: 0),
                  SizedBox(width: 4),
                  _TypingDot(delayMs: 120),
                  SizedBox(width: 4),
                  _TypingDot(delayMs: 240),
                ],
              )
            : Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.black : Colors.black87,
                ),
              ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delayMs;
  const _TypingDot({required this.delayMs});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _animation = Tween(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delayMs / 900, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const CircleAvatar(radius: 4, backgroundColor: Colors.black54),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask FitGenie anything...',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF3F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF22C6A3),
            child: IconButton(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Icon(Icons.send, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Workout>>(
      stream: WorkoutService.instance.streamWorkouts(),
      builder: (context, workoutSnapshot) {
        if (!workoutSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<Map<String, dynamic>?>(
          stream: StatsService.instance.stream(),
          builder: (context, statsSnapshot) {
            final metrics = _ProgressMetrics.fromData(
              workouts: workoutSnapshot.data ?? const [],
              stats: statsSnapshot.data,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Text(
                  'User Insights',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Trends, recovery, and performance signals.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: const [
                    _Pill(label: 'Weekly', color: Color(0xFF2C7DD8)),
                    _Pill(label: 'Monthly', color: Color(0xFF22C6A3)),
                    _Pill(label: '90 Days', color: Color(0xFF7C5CFF)),
                  ],
                ),
                const SizedBox(height: 18),
                const _ProgressHeader(),
                const SizedBox(height: 16),
                _ProgressChartCard(
                  title: 'Active Minutes',
                  value: '${metrics.currentMinutes} min',
                  delta:
                      'Last 7 Days  ${_signedPercent(metrics.minutesPercent)}',
                  deltaUp: metrics.minutesPercent >= 0,
                  values: metrics.minuteBars,
                ),
                const SizedBox(height: 16),
                _ProgressBarCard(
                  title: 'Calories Burned',
                  value: '${metrics.currentCalories}',
                  delta:
                      'Last 7 Days  ${_signedPercent(metrics.caloriesPercent)}',
                  deltaUp: metrics.caloriesPercent >= 0,
                  values: metrics.calorieBars,
                ),
                const SizedBox(height: 16),
                _ProgressConsistencyCard(
                  percent: metrics.consistencyPercent,
                  values: metrics.consistencyBars,
                ),
                const SizedBox(height: 20),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  metrics.insightText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                Text(
                  'Motivational Alerts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                _AlertTile(
                  title: 'Streak Tracker',
                  subtitle: '${metrics.streakDays} day current streak',
                ),
                const SizedBox(height: 10),
                _AlertTile(title: 'Last Sync', subtitle: metrics.lastSyncLabel),
              ],
            );
          },
        );
      },
    );
  }
}

String _signedPercent(double value) {
  final rounded = value.round();
  return '${rounded >= 0 ? '+' : ''}$rounded%';
}

class _ProgressMetrics {
  final int currentMinutes;
  final int currentCalories;
  final double minutesPercent;
  final double caloriesPercent;
  final double consistencyPercent;
  final List<double> minuteBars;
  final List<double> calorieBars;
  final List<double> consistencyBars;
  final int streakDays;
  final String insightText;
  final String lastSyncLabel;

  const _ProgressMetrics({
    required this.currentMinutes,
    required this.currentCalories,
    required this.minutesPercent,
    required this.caloriesPercent,
    required this.consistencyPercent,
    required this.minuteBars,
    required this.calorieBars,
    required this.consistencyBars,
    required this.streakDays,
    required this.insightText,
    required this.lastSyncLabel,
  });

  factory _ProgressMetrics.fromData({
    required List<Workout> workouts,
    required Map<String, dynamic>? stats,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(const Duration(days: 6));
    final previousStart = currentStart.subtract(const Duration(days: 7));
    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final currentMinutesMap = <DateTime, int>{};
    final previousMinutesMap = <DateTime, int>{};
    final currentWorkoutCount = <DateTime, int>{};
    int previousWorkoutTotal = 0;

    for (var i = 0; i < 7; i++) {
      final day = currentStart.add(Duration(days: i));
      currentMinutesMap[day] = 0;
      currentWorkoutCount[day] = 0;
      previousMinutesMap[previousStart.add(Duration(days: i))] = 0;
    }

    for (final workout in workouts) {
      final completed = workout.completedAt;
      if (completed == null) continue;
      final day = DateTime(completed.year, completed.month, completed.day);
      if (!day.isBefore(currentStart) && !day.isAfter(today)) {
        currentMinutesMap[day] =
            (currentMinutesMap[day] ?? 0) + workout.durationMinutes;
        currentWorkoutCount[day] = (currentWorkoutCount[day] ?? 0) + 1;
      } else if (!day.isBefore(previousStart) && !day.isAfter(previousEnd)) {
        previousMinutesMap[day] =
            (previousMinutesMap[day] ?? 0) + workout.durationMinutes;
        previousWorkoutTotal += 1;
      }
    }

    final currentMinutes = currentMinutesMap.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final previousMinutes = previousMinutesMap.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final currentWorkouts = currentWorkoutCount.values.fold<int>(
      0,
      (a, b) => a + b,
    );

    final minuteBars = currentMinutesMap.values
        .map((v) => v.toDouble())
        .toList();
    final calorieBars = minuteBars.map((m) => m * 8.0).toList();
    final consistencyBars = currentWorkoutCount.values
        .map((v) => (v / 2).clamp(0.0, 1.0))
        .toList();

    final caloriesFromWorkouts = (currentMinutes * 8);
    final currentCalories =
        (stats?['calories'] as num?)?.toInt() ?? caloriesFromWorkouts;
    final previousCalories = previousMinutes * 8;

    final minutesPercent = _percentChange(currentMinutes, previousMinutes);
    final caloriesPercent = _percentChange(currentCalories, previousCalories);
    final consistencyPercent = _percentChange(
      currentWorkouts,
      previousWorkoutTotal,
    );

    final streakDays = _computeStreak(workouts, today);
    DateTime? lastSync;
    final rawUpdatedAt = stats?['updatedAt'];
    if (rawUpdatedAt is DateTime) {
      lastSync = rawUpdatedAt;
    } else if (rawUpdatedAt != null) {
      try {
        lastSync = rawUpdatedAt.toDate() as DateTime?;
      } catch (_) {
        lastSync = null;
      }
    }

    return _ProgressMetrics(
      currentMinutes: currentMinutes,
      currentCalories: currentCalories,
      minutesPercent: minutesPercent,
      caloriesPercent: caloriesPercent,
      consistencyPercent: consistencyPercent,
      minuteBars: minuteBars,
      calorieBars: calorieBars,
      consistencyBars: consistencyBars,
      streakDays: streakDays,
      insightText:
          'You completed $currentWorkouts workouts in the last 7 days with a $streakDays day streak.',
      lastSyncLabel: lastSync == null
          ? 'No sync yet'
          : 'Updated ${_formatLastSync(lastSync)}',
    );
  }

  static double _percentChange(int current, int previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  static int _computeStreak(List<Workout> workouts, DateTime today) {
    final completedDays = workouts
        .where((w) => w.completedAt != null)
        .map(
          (w) => DateTime(
            w.completedAt!.year,
            w.completedAt!.month,
            w.completedAt!.day,
          ),
        )
        .toSet();
    var streak = 0;
    var cursor = today;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _formatLastSync(DateTime date) {
    final now = DateTime.now();
    final delta = now.difference(date);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TabChip(label: 'Weekly', isActive: true),
            _TabChip(label: 'Monthly', isActive: false),
          ],
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isActive ? Colors.black : Colors.black54,
        ),
      ),
    );
  }
}

class _ProgressChartCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final bool deltaUp;
  final List<double> values;

  const _ProgressChartCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaUp,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            delta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: deltaUp
                  ? const Color(0xFF22C6A3)
                  : const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: values,
                lineColor: const Color(0xFF2C7DD8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBarCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final bool deltaUp;
  final List<double> values;

  const _ProgressBarCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaUp,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            delta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: deltaUp
                  ? const Color(0xFF22C6A3)
                  : const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _BarChartPainter(
                values: values,
                barColor: const Color(0xFF22C6A3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressConsistencyCard extends StatelessWidget {
  final double percent;
  final List<double> values;

  const _ProgressConsistencyCard({required this.percent, required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Consistency',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            _signedPercent(percent),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 Days  ${_signedPercent(percent)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: percent >= 0
                  ? const Color(0xFF22C6A3)
                  : const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 12),
          _ConsistencyBars(values: values),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AlertTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  _LineChartPainter({required this.values, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);
    final stepX = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = stepX * i;
      final norm = (values[i] - minVal) / range;
      final y = size.height - (norm * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color barColor;
  _BarChartPainter({required this.values, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    final barWidth = size.width / (values.length * 1.4);
    final gap = barWidth * 0.4;
    var x = 0.0;

    final paint = Paint()..color = barColor;
    for (final v in values) {
      final h = (v / safeMax) * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);
      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.barColor != barColor;
  }
}

class _ConsistencyBars extends StatelessWidget {
  final List<double> values;
  const _ConsistencyBars({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values
          .map(
            (v) => Container(
              height: 10,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C6A3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  bool _isGeneratingAi = false;

  Future<void> _generateAiWellness() async {
    setState(() => _isGeneratingAi = true);
    final generated = await AIContentService.instance.generateWellness(
      goal: 'Stress relief and better sleep',
    );
    var inserted = 0;
    for (final session in generated) {
      final added = await WellnessService.instance.addSessionIfNotDuplicate(
        session,
      );
      if (added) inserted++;
    }
    if (!mounted) return;
    setState(() => _isGeneratingAi = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          generated.isEmpty
              ? 'AI wellness generation unavailable right now.'
              : (inserted == 0
                    ? 'No new AI wellness sessions (duplicates skipped).'
                    : 'Added $inserted AI wellness sessions.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Guided Wellness',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _isGeneratingAi ? null : _generateAiWellness,
              icon: _isGeneratingAi
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_isGeneratingAi ? 'Generating...' : 'AI Generate'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Breathing, meditation, yoga & stress relief.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _WellnessSectionTitle(
          icon: Icons.air,
          title: 'Breathing exercises',
          subtitle: 'Calm your nervous system',
        ),
        const SizedBox(height: 12),
        const _BreathBar(label: 'Inhale', value: 0.5),
        const SizedBox(height: 10),
        const _BreathBar(label: 'Exhale', value: 0.5),
        const SizedBox(height: 12),
        StreamBuilder<List<WellnessSession>>(
          stream: WellnessService.instance.streamSessions(),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? WellnessSession.samples();
            final breathing = sessions
                .where(
                  (s) =>
                      s.title.toLowerCase().contains('breath') ||
                      s.title == '4-7-8 Breathing' ||
                      s.title == 'Morning Breathwork',
                )
                .toList();
            if (breathing.isEmpty) return const SizedBox.shrink();
            return Column(
              children: breathing
                  .map(
                    (s) => _WellnessCard(
                      title: s.title,
                      duration: s.duration,
                      description: s.description,
                      accent: s.accent,
                      onPlay: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WellnessSessionScreen(session: s),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        _WellnessSectionTitle(
          icon: Icons.self_improvement,
          title: 'Meditation (2–10 min)',
          subtitle: 'Short sessions for focus & calm',
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _MeditationTile(
                title: 'Quick calm',
                subtitle: '2 min reset',
                imagePath: 'assets/images/mindful_meditation.jpg',
                duration: '2 min',
                description: 'Brief breath focus.',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MeditationTile(
                title: 'Mindfulness',
                subtitle: '5 min',
                imagePath: 'assets/images/mindful_meditation.jpg',
                duration: '5 min',
                description: 'Present moment awareness.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _MeditationTile(
                title: 'Body scan',
                subtitle: '8 min',
                imagePath: 'assets/images/mindful_meditation.jpg',
                duration: '8 min',
                description: 'Release tension head to toe.',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MeditationTile(
                title: 'Sleep meditation',
                subtitle: '10 min',
                imagePath: 'assets/images/sleep_meditation.jpg',
                duration: '10 min',
                description: 'Drift off peacefully.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _WellnessSectionTitle(
          icon: Icons.accessibility_new,
          title: 'Yoga / mobility routines',
          subtitle: 'Flow and stretch',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _WellnessTile(
                title: 'Morning Flow',
                subtitle: 'Start your day',
                imagePath: 'assets/images/yoga1.jpg',
                duration: '10 min',
                description: 'Spine and hip mobility.',
              ),
              SizedBox(width: 14),
              _WellnessTile(
                title: 'Evening Relaxation',
                subtitle: 'Unwind',
                imagePath: 'assets/images/evening_relaxation.jpg',
                duration: '12 min',
                description: 'Slow stretches before bed.',
              ),
              SizedBox(width: 14),
              _WellnessTile(
                title: 'Neck + Shoulder',
                subtitle: 'Desk relief',
                imagePath: 'assets/images/neck_shoulder_icon.jpg',
                duration: '7 min',
                description: 'Release tension.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _WellnessSectionTitle(
          icon: Icons.nightlight_round,
          title: 'Stress & sleep improvement',
          subtitle: 'Wind down and recover',
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<WellnessSession>>(
          stream: WellnessService.instance.streamSessions(),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? WellnessSession.samples();
            final stressSleep = sessions.where((s) {
              final t = s.title.toLowerCase();
              return t.contains('sleep') ||
                  t.contains('mindset') ||
                  t.contains('body scan') ||
                  t.contains('evening') ||
                  t.contains('4-7-8');
            }).toList();
            if (stressSleep.isEmpty) {
              return Column(
                children: sessions
                    .take(3)
                    .map(
                      (s) => _WellnessCard(
                        title: s.title,
                        duration: s.duration,
                        description: s.description,
                        accent: s.accent,
                        onPlay: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WellnessSessionScreen(session: s),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            }
            return Column(
              children: stressSleep
                  .map(
                    (s) => _WellnessCard(
                      title: s.title,
                      duration: s.duration,
                      description: s.description,
                      accent: s.accent,
                      onPlay: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WellnessSessionScreen(session: s),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _WellnessSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WellnessSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WellnessCard extends StatelessWidget {
  final String title;
  final String duration;
  final String description;
  final Color accent;
  final VoidCallback? onPlay;

  const _WellnessCard({
    required this.title,
    required this.duration,
    required this.description,
    required this.accent,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        duration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill, color: accent, size: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathBar extends StatelessWidget {
  final String label;
  final double value;

  const _BreathBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.cardDecoration(borderRadius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final String duration;
  final String description;
  const _WellnessTile({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.description,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final session = WellnessSession(
            title: title,
            duration: duration,
            description: description,
            accent: const Color(0xFF22C6A3),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WellnessSessionScreen(session: session),
            ),
          );
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: imagePath == null
                        ? const LinearGradient(
                            colors: [Color(0xFFF3E6D2), Color(0xFFF8D8B1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: imagePath == null
                        ? null
                        : DecorationImage(
                            image: AssetImage(imagePath!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: imagePath == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.black26,
                            size: 48,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeditationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final String duration;
  final String description;

  const _MeditationTile({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.description,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final session = WellnessSession(
            title: title,
            duration: duration,
            description: description,
            accent: const Color(0xFF4CC9F0),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WellnessSessionScreen(session: session),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: imagePath == null
                      ? const LinearGradient(
                          colors: [Color(0xFFE1F1F2), Color(0xFF9CC6D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: imagePath == null
                      ? null
                      : DecorationImage(
                          image: AssetImage(imagePath!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: imagePath == null
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.black26,
                          size: 48,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _alertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'Profile & Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Firebase sync, reminders, and your personalized goals.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _SettingsTile(
          title: 'Firebase Sync',
          subtitle: 'Realtime data sync across devices',
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
        _SettingsTile(
          title: 'Motivational Alerts',
          subtitle: 'Daily reminders and streak nudges',
          trailing: Switch(
            value: _alertsEnabled,
            onChanged: (value) async {
              setState(() => _alertsEnabled = value);
              await NotificationService.instance.subscribeToMotivation(value);
            },
          ),
        ),
        _SettingsTile(
          title: 'AI Plan Updates',
          subtitle: 'Auto-adjust workouts based on progress',
          trailing: Switch(value: false, onChanged: (_) {}),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Strength goal: 12% to target. Mindfulness goal: 58% complete. Sleep trend: +18 min.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export Progress'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProgressPage()),
                  );
                },
                icon: const Icon(Icons.insights_outlined),
                label: const Text('View Progress'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => AuthService.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: onChanged,
        backgroundColor: AppTheme.surfaceCard,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'Coach AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Wellness',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black12),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final opacity = value.clamp(0.0, 1.0);
        final offset = 12 * (1 - value);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: Offset(0, offset), child: child),
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _UpcomingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2C7DD8).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2C7DD8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }
}

class SessionDetailScreen extends StatefulWidget {
  final Workout workout;
  const SessionDetailScreen({super.key, required this.workout});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late final List<_WorkoutExercise> _exercises;

  Timer? _timer;
  int _currentIndex = 0;
  int _remaining = 0;
  bool _running = false;
  bool _hasStarted = false;
  bool _didPersistCompletion = false;

  @override
  void initState() {
    super.initState();
    _exercises = _exercisePlan();
    _remaining = _exercises.first.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    _startTimer();
  }

  void _startTimer() {
    if (_running) return;
    setState(() {
      _running = true;
      _hasStarted = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        _nextExercise(auto: true);
      } else {
        if (_remaining <= 4) {
          _playBeep();
        }
        setState(() => _remaining--);
      }
    });
  }

  void _nextExercise({bool auto = false}) {
    _timer?.cancel();
    if (auto) {
      _playBeep();
    }
    if (_currentIndex < _exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _remaining = _exercises[_currentIndex].durationSeconds;
        _running = false;
      });
      if (auto) {
        _startTimer();
      }
    } else {
      setState(() {
        _running = false;
        _remaining = 0;
      });
      _completeWorkout();
    }
  }

  Future<void> _completeWorkout() async {
    if (_didPersistCompletion) return;
    _didPersistCompletion = true;

    final completedWorkout = Workout(
      id: widget.workout.id,
      title: widget.workout.title,
      focus: widget.workout.focus,
      durationMinutes: widget.workout.durationMinutes,
      createdAt: widget.workout.createdAt,
      completedAt: DateTime.now(),
    );

    if (completedWorkout.id.isEmpty) {
      await WorkoutService.instance.addWorkout(completedWorkout);
    } else {
      await WorkoutService.instance.updateWorkout(completedWorkout);
    }

    await StatsService.instance.update(
      minutesDelta: completedWorkout.durationMinutes,
      caloriesDelta: (completedWorkout.durationMinutes * 8),
    );

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _WorkoutCompleteScreen()));
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _currentIndex = 0;
      _remaining = _exercises.first.durationSeconds;
      _running = false;
      _hasStarted = false;
    });
  }

  List<_WorkoutExercise> _exercisePlan() {
    final title = widget.workout.title.toLowerCase();
    final focus = widget.workout.focus.toLowerCase();

    List<String> circuit;
    if (title.contains('core ignite')) {
      circuit = const [
        'Plank',
        'Hollow Hold',
        'Russian Twists',
        'Dead Bug',
        'Side Plank (Left)',
        'Side Plank (Right)',
      ];
    } else if (focus.contains('cardio')) {
      circuit = const [
        'Warm-up Walk',
        'Jog Intervals',
        'High Knees',
        'Jump Rope',
        'Cooldown Walk',
      ];
    } else if (focus.contains('core')) {
      circuit = const [
        'Plank',
        'Dead Bug',
        'Russian Twists',
        'Hollow Hold',
        'Side Plank',
      ];
    } else if (focus.contains('no-equipment')) {
      circuit = const [
        'Bodyweight Squats',
        'Push-ups',
        'Reverse Lunges',
        'Mountain Climbers',
        'Burpees',
      ];
    } else if (focus.contains('band')) {
      circuit = const [
        'Band Rows',
        'Band Squats',
        'Band Press',
        'Band RDL',
        'Band Pull-Aparts',
      ];
    } else if (focus.contains('dumbbell')) {
      circuit = const [
        'DB Squats',
        'DB Press',
        'DB Rows',
        'DB RDL',
        'DB Curls',
      ];
    } else if (focus.contains('mobility') || focus.contains('recovery')) {
      circuit = const [
        'Cat-Cow',
        'World\'s Greatest Stretch',
        'Hip Flexor Stretch',
        'Thoracic Rotations',
        'Breathing Reset',
      ];
    } else {
      circuit = const [
        'Squats',
        'Push-ups',
        'Lunges',
        'Plank',
        'Cooldown Stretch',
      ];
    }

    return _buildIntervalPlan(
      circuit,
      rounds: 3,
      workSeconds: 45,
      restSeconds: 15,
    );
  }

  List<_WorkoutExercise> _buildIntervalPlan(
    List<String> circuit, {
    required int rounds,
    required int workSeconds,
    required int restSeconds,
  }) {
    final plan = <_WorkoutExercise>[];
    for (var round = 1; round <= rounds; round++) {
      for (var i = 0; i < circuit.length; i++) {
        final exercise = circuit[i];
        plan.add(
          _WorkoutExercise(
            'R$round  $exercise',
            '${workSeconds}s work',
            workSeconds,
          ),
        );
        final isLastInWorkout = round == rounds && i == circuit.length - 1;
        if (!isLastInWorkout) {
          plan.add(
            _WorkoutExercise(
              'Rest',
              '${restSeconds}s rest',
              restSeconds,
              isRest: true,
            ),
          );
        }
      }
    }
    return plan;
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _playBeep() async {
    await playAppBeep();
  }

  @override
  Widget build(BuildContext context) {
    final current = _exercises[_currentIndex];
    final next = _currentIndex < _exercises.length - 1
        ? _exercises[_currentIndex + 1]
        : null;
    final progress = current.durationSeconds == 0
        ? 0.0
        : (current.durationSeconds - _remaining) / current.durationSeconds;
    final totalSeconds = _exercises.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    final elapsedBeforeCurrent = _exercises
        .take(_currentIndex)
        .fold<int>(0, (sum, item) => sum + item.durationSeconds);
    final elapsedTotal =
        elapsedBeforeCurrent + (current.durationSeconds - _remaining);
    final overallProgress = totalSeconds == 0
        ? 0.0
        : elapsedTotal / totalSeconds;
    final isCoreIgnite = widget.workout.title.toLowerCase().contains(
      'core ignite',
    );
    final displayDuration = '${(totalSeconds / 60).round()} minutes';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              Expanded(
                child: Text(
                  widget.workout.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          if (isCoreIgnite) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/coreignite_picture.png',
                      height: 190,
                      width: 320,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 280),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFF1F5F9), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    current.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.reps,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: Colors.black12,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        Text(
                          _format(_remaining),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF22C6A3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Overall: ${(overallProgress * 100).round()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  if (next != null)
                    Text(
                      'Next: ${next.name}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.workout.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          _DetailRow(label: 'Duration', value: displayDuration),
          const SizedBox(height: 6),
          _DetailRow(label: 'Focus', value: widget.workout.focus),
          const SizedBox(height: 14),
          Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final ex in _exercises)
            _ExerciseTile(name: ex.name, reps: ex.reps),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C6A3),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _startPause,
                  child: Text(
                    _running
                        ? 'Pause'
                        : (_hasStarted ? 'Resume' : 'Start Workout'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onPressed: _nextExercise,
                child: const Text('Next'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {},
              child: const Text('Goal Driven'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutExercise {
  final String name;
  final String reps;
  final int durationSeconds;
  final bool isRest;
  const _WorkoutExercise(
    this.name,
    this.reps,
    this.durationSeconds, {
    this.isRest = false,
  });
}

class _WorkoutCompleteScreen extends StatelessWidget {
  const _WorkoutCompleteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 84, color: Color(0xFF7C3AED)),
              const SizedBox(height: 16),
              Text(
                'Workout Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Great effort. Your progress has been synced.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Workouts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStep extends StatelessWidget {
  final String label;
  final String detail;

  const _SessionStep({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF22C6A3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String name;
  final String reps;

  const _ExerciseTile({required this.name, required this.reps});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE7E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  reps,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WellnessSessionScreen extends StatefulWidget {
  final WellnessSession session;

  const WellnessSessionScreen({super.key, required this.session});

  @override
  State<WellnessSessionScreen> createState() => _WellnessSessionScreenState();
}

class _WellnessSessionScreenState extends State<WellnessSessionScreen> {
  Timer? _timer;
  late int _totalSeconds;
  late int _remaining;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final minutes =
        int.tryParse(
          RegExp(r'(\\d+)').firstMatch(widget.session.duration)?.group(1) ?? '',
        ) ??
        5;
    _totalSeconds = minutes * 60;
    _remaining = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
    });
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0
        ? 0.0
        : (_totalSeconds - _remaining) / _totalSeconds;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.session.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.session.duration,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: widget.session.accent),
          ),
          const SizedBox(height: 12),
          Text(
            widget.session.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Timer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (widget.session.title == 'Neck + Shoulder Relief')
                  _NeckShoulderTimer(
                    progress: progress,
                    timeLabel: _format(_remaining),
                    accent: widget.session.accent,
                  )
                else if (widget.session.title == '4-7-8 Breathing')
                  _BreathingTimer(
                    progress: progress,
                    timeLabel: _format(_remaining),
                    accent: widget.session.accent,
                  )
                else ...[
                  Center(
                    child: Text(
                      _format(_remaining),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation(widget.session.accent),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.session.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _startPause,
                        child: Text(_running ? 'Pause' : 'Start'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: widget.session.accent.withOpacity(0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.session.title == 'Mindset Coach')
            _MindsetCoachScript()
          else if (widget.session.title == 'Neck + Shoulder Relief')
            _NeckShoulderReliefScript()
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guided Steps',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  const _SessionStep(label: 'Inhale', detail: '4 seconds'),
                  const _SessionStep(label: 'Hold', detail: '7 seconds'),
                  const _SessionStep(label: 'Exhale', detail: '8 seconds'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MindsetCoachScript extends StatelessWidget {
  const _MindsetCoachScript();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mindset Coach', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _ScriptBlock(
            title: 'Minute 0:00-0:30 Ã¢â‚¬â€ Arrival & Grounding',
            body:
                'Welcome. Find a comfortable position and gently close your eyes if that feels right. '
                'Take a slow breath in through your nose and out through your mouth. '
                'You are here. Nothing else matters for the next few minutes.',
          ),
          _ScriptBlock(
            title: 'Minute 0:30-1:30 Ã¢â‚¬â€ Breath Control',
            body:
                'Breathe in for 4. Hold for 2. Breathe out for 6. '
                'Let your shoulders soften as you exhale. Repeat this breathing pattern twice more.',
          ),
          _ScriptBlock(
            title: 'Minute 1:30-2:30 Ã¢â‚¬â€ Body Awareness',
            body:
                'Bring your attention to your body. Notice where you are holding tension Ã¢â‚¬â€ '
                'your jaw, shoulders, or chest. With each exhale, imagine that tension gently melting away.',
          ),
          _ScriptBlock(
            title: 'Minute 2:30-3:45 Ã¢â‚¬â€ Mindset Reframe',
            body:
                'Thoughts may come and go. That is normal. You do not need to fight them. '
                'Just notice them and let them pass. Remind yourself: '
                '"I am capable. I am improving. I am in control of my effort."',
          ),
          _ScriptBlock(
            title: 'Minute 3:45-4:30 Ã¢â‚¬â€ Confidence Boost',
            body:
                'Visualize yourself succeeding today Ã¢â‚¬â€ staying focused, calm, and confident. '
                'See yourself handling challenges with clarity. Feel that confidence settle into your body.',
          ),
          _ScriptBlock(
            title: 'Minute 4:30-5:00 Ã¢â‚¬â€ Closing',
            body:
                'Take one final deep breath in and out. When you are ready, gently open your eyes. '
                'Carry this calm mindset with you into the rest of your day.',
          ),
          const SizedBox(height: 10),
          Text(
            'FitGenie AI: Nice work.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _NeckShoulderReliefScript extends StatelessWidget {
  const _NeckShoulderReliefScript();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neck + Shoulder Relief',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _ScriptBlock(
            title: 'Minute 0:00-1:00 â€” Ground & Breathe',
            body:
                'Inhale slowly through your nose for 4 seconds. Exhale through your mouth for 6 seconds. '
                'Drop your shoulders away from your ears. Imagine tension melting down your back. '
                'Repeat this breathing 3â€“4 times.',
          ),
          _ScriptBlock(
            title: 'Minute 1:00-2:00 â€” Neck Side Release',
            body:
                'Gently tilt your head right ear toward right shoulder. Hold for 10 seconds, breathing deeply. '
                'Come back to center. Tilt left ear toward left shoulder. Hold for 10 seconds. '
                'Keep shoulders relaxed â€” no lifting.',
          ),
          _ScriptBlock(
            title: 'Minute 2:00-3:00 â€” Neck Forward & Back Stretch',
            body:
                'Slowly lower your chin toward your chest. Feel the stretch along the back of your neck. '
                'Hold for 10 seconds. Gently lift your head and look slightly upward (no forcing). '
                'Hold for 5 seconds. Repeat once.',
          ),
          _ScriptBlock(
            title: 'Minute 3:00-4:00 â€” Shoulder Rolls & Release',
            body:
                'Roll both shoulders up, back, and down. Slow and controlled, 5 circles. '
                'Then reverse direction for 5 circles. Let your arms hang loose.',
          ),
          _ScriptBlock(
            title: 'Minute 4:00-5:00 â€” Upper Trap Stretch + Reset',
            body:
                'Place your right hand on the left side of your head. Gently guide your ear toward your shoulder. '
                'Hold 10 seconds. Switch sides. Finish with one deep breath in and a long sigh out.',
          ),
        ],
      ),
    );
  }
}

class _ScriptBlock extends StatelessWidget {
  final String title;
  final String body;

  const _ScriptBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _NeckShoulderTimer extends StatelessWidget {
  final double progress;
  final String timeLabel;
  final Color accent;

  const _NeckShoulderTimer({
    required this.progress,
    required this.timeLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/neck_shoulder_icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _BreathingTimer extends StatelessWidget {
  final double progress;
  final String timeLabel;
  final Color accent;

  const _BreathingTimer({
    required this.progress,
    required this.timeLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/breathing_icon.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
