import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _progressAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: tasksAsync.when(
              data: (tasks) => _buildContent(context, tasks),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TaskModel> tasks) {
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final progress = tasks.isEmpty ? 0 : ((completed / tasks.length) * 100).round();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Insights', style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            )),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: const Icon(Icons.settings_outlined, size: 24,
                      color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Circular Progress Ring Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppTheme.softShadows,
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  return SizedBox(
                    width: 200, height: 200,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progress * _progressAnim.value / 100,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(progress * _progressAnim.value).round()}%',
                              style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('COMPLETE', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 2,
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(child: _statItem('GPA', '3.92', AppColors.textPrimary)),
                    Container(width: 1, height: 40, color: AppColors.bgColor),
                    Expanded(child: _statItem('XP EARNED', '2.4k', AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Mastery Levels
        const Text('MASTERY LEVELS', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 2,
        )),
        const SizedBox(height: 20),

        _masteryCard('Computer Science', 88, AppColors.gradientPurpleBlue),
        const SizedBox(height: 16),
        _masteryCard('Modern Physics', 72, AppColors.gradientPinkOrange),
        const SizedBox(height: 16),
        _masteryCard('Advanced Calculus', 94, AppColors.gradientTealBlue),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w900,
          color: valueColor,
          letterSpacing: -1.0,
        )),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        )),
      ],
    );
  }

  Widget _masteryCard(String subject, int value, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
              Text('$value%', style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              )),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                final fill = value * _progressAnim.value / 100;
                return Container(
                  height: 10, // Thicker bar for premium feel
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;

    // Background circle (Very subtle gray track)
    final bgPaint = Paint()
      ..color = AppColors.bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with gradient shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = AppColors.gradientPurpleBlue.createShader(rect);
    
    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      // Soft glow for the ring itself
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}
