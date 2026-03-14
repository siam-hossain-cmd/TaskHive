import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/task_model.dart';
import '../providers/ai_enhancement_providers.dart';
import '../providers/task_providers.dart';

class AIFeaturesScreen extends ConsumerStatefulWidget {
  const AIFeaturesScreen({super.key});

  @override
  ConsumerState<AIFeaturesScreen> createState() => _AIFeaturesScreenState();
}

class _AIFeaturesScreenState extends ConsumerState<AIFeaturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _naturalInputController = TextEditingController();
  Map<String, dynamic>? _parsedTask;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _naturalInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiEnhancementProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Smart Input'),
                  Tab(text: 'Tips'),
                  Tab(text: 'Review'),
                  Tab(text: 'Priority'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSmartInputTab(aiState),
                  _buildSuggestionsTab(aiState),
                  _buildWeeklyReviewTab(aiState),
                  _buildPriorityTab(aiState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Powered by Gemini AI',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Smart Input ──────────────────────────────────────────────────

  Widget _buildSmartInputTab(AIEnhancementState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadows,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Natural Language Input',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe your task in plain English and AI will structure it for you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _naturalInputController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g., "Finish math homework by Friday, high priority"',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: aiState.isParsingTask
                      ? null
                      : () async {
                          final text = _naturalInputController.text.trim();
                          if (text.isEmpty) return;
                          HapticFeedback.mediumImpact();
                          final result = await ref
                              .read(aiEnhancementProvider.notifier)
                              .parseTask(text);
                          if (mounted) {
                            setState(() => _parsedTask = result);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (aiState.isParsingTask)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          aiState.isParsingTask
                              ? 'Parsing...'
                              : 'Parse with AI',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Parsed Result
          if (_parsedTask != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Parsed Task',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _parsedField('Title', _parsedTask!['title'] ?? ''),
                  _parsedField('Subject', _parsedTask!['subject'] ?? ''),
                  _parsedField('Priority', _parsedTask!['priority'] ?? ''),
                  _parsedField('Due Date', _parsedTask!['dueDate'] ?? ''),
                  if (_parsedTask!['description'] != null)
                    _parsedField('Description', _parsedTask!['description']),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      // Navigate to create task with pre-filled data
                      context.push('/create-task', extra: _parsedTask);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_task_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Create This Task',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _parsedField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: AI Suggestions ──────────────────────────────────────────────

  Widget _buildSuggestionsTab(AIEnhancementState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Fetch button
          GestureDetector(
            onTap: aiState.isLoadingSuggestions
                ? null
                : () {
                    ref.read(aiEnhancementProvider.notifier).fetchSuggestions();
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (aiState.isLoadingSuggestions)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    aiState.isLoadingSuggestions
                        ? 'Generating...'
                        : 'Get Smart Suggestions',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions List
          if (aiState.suggestions.isNotEmpty)
            ...aiState.suggestions.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadows,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _categoryColor(s.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _categoryIcon(s.type),
                        size: 18,
                        color: _categoryColor(s.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _categoryColor(
                                    s.type,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s.type,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _categoryColor(s.type),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
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

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'productivity':
        return AppColors.primary;
      case 'time':
        return AppColors.warning;
      case 'focus':
        return const Color(0xFF667EEA);
      case 'wellness':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'productivity':
        return Icons.trending_up_rounded;
      case 'time':
        return Icons.schedule_rounded;
      case 'focus':
        return Icons.center_focus_strong_rounded;
      case 'wellness':
        return Icons.spa_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  // ─── Tab 3: Weekly Review ──────────────────────────────────────────────

  Widget _buildWeeklyReviewTab(AIEnhancementState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: aiState.isLoadingReview
                ? null
                : () {
                    ref
                        .read(aiEnhancementProvider.notifier)
                        .fetchWeeklyReview();
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (aiState.isLoadingReview)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.analytics_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    aiState.isLoadingReview
                        ? 'Generating...'
                        : 'Generate Weekly Review',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (aiState.weeklyReview != null) ...[
            // Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Score Circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${aiState.weeklyReview!.productivityScore}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Productivity Score',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aiState.weeklyReview!.summary,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Highlights
            if (aiState.weeklyReview!.highlights.isNotEmpty)
              _reviewSection(
                'Highlights',
                Icons.star_rounded,
                AppColors.warning,
                aiState.weeklyReview!.highlights,
              ),

            // Areas to improve
            if (aiState.weeklyReview!.improvements.isNotEmpty)
              _reviewSection(
                'Areas to Improve',
                Icons.trending_up_rounded,
                AppColors.info,
                aiState.weeklyReview!.improvements,
              ),

            // Tips
            if (aiState.weeklyReview!.nextWeekTips.isNotEmpty)
              _reviewSection(
                'Tips for Next Week',
                Icons.lightbulb_rounded,
                AppColors.success,
                aiState.weeklyReview!.nextWeekTips,
              ),
          ],
        ],
      ),
    );
  }

  Widget _reviewSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
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

  // ─── Tab 4: Smart Priority ──────────────────────────────────────────────

  Widget _buildPriorityTab(AIEnhancementState aiState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: aiState.isLoadingPriority
                ? null
                : () {
                    ref
                        .read(aiEnhancementProvider.notifier)
                        .fetchPrioritySuggestions();
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D5FEF), Color(0xFFA5A6F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (aiState.isLoadingPriority)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    aiState.isLoadingPriority
                        ? 'Analyzing...'
                        : 'Analyze Priorities',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (aiState.priorityAdjustments.isNotEmpty)
            ...aiState.priorityAdjustments.map((adj) {
              final priorityColor = _priorityColor(adj.suggestedPriority);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adj.taskTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _priorityBadge(
                          adj.currentPriority,
                          AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _priorityBadge(adj.suggestedPriority, priorityColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      adj.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.priorityHighText;
      case 'medium':
        return AppColors.priorityMediumText;
      case 'low':
        return AppColors.priorityLowText;
      default:
        return AppColors.textSecondary;
    }
  }
}
