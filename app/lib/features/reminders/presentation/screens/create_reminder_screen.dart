import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/reminder_model.dart';
import '../providers/reminder_providers.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final ReminderModel? existingReminder;
  const CreateReminderScreen({super.key, this.existingReminder});

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  ReminderType _type = ReminderType.birthday;
  final _titleCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  ReminderRecurrence _recurrence = ReminderRecurrence.none;
  int _notifyBefore = 15; // minutes
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    if (widget.existingReminder != null) {
      _isEditing = true;
      final r = widget.existingReminder!;
      _type = r.type;
      _titleCtrl.text = r.title;
      _remarkCtrl.text = r.remark;
      _date = r.date;
      _time = TimeOfDay.fromDateTime(r.date);
      _recurrence = r.recurrence;
      _notifyBefore = r.notifyBeforeMinutes;
    } else {
      _titleCtrl.text = _type.label;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(ReminderType? type) {
    if (type == null) return;
    setState(() {
      _type = type;
      // Auto-fill title based on type if title was the old type label
      if (_titleCtrl.text.isEmpty ||
          ReminderType.values.any((t) => t.label == _titleCtrl.text)) {
        _titleCtrl.text = type.label;
      }
      // Auto-set recurrence for birthday/anniversary
      if (type == ReminderType.birthday || type == ReminderType.anniversary) {
        _recurrence = ReminderRecurrence.yearly;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceColor,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceColor,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      final reminder = ReminderModel(
        id: _isEditing ? widget.existingReminder!.id : '',
        userId: user.uid,
        type: _type,
        title: _titleCtrl.text.trim(),
        remark: _remarkCtrl.text.trim(),
        date: dateTime,
        recurrence: _recurrence,
        notifyBeforeMinutes: _notifyBefore,
        isCompleted: false,
        createdAt: _isEditing
            ? widget.existingReminder!.createdAt
            : DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(reminderNotifierProvider.notifier)
            .updateReminder(reminder);
      } else {
        final created = await ref
            .read(reminderNotifierProvider.notifier)
            .createReminder(reminder);

        // Schedule local notification
        if (created != null) {
          final notifService = ref.read(pushNotificationServiceProvider);
          notifService.scheduleReminderNotification(created);
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 24),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildRemarkField(),
                      const SizedBox(height: 24),
                      _buildDateTimeRow(),
                      const SizedBox(height: 24),
                      _buildRecurrenceSelector(),
                      const SizedBox(height: 24),
                      _buildNotifyBeforeSelector(),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Reminder' : 'New Reminder',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _type.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ReminderType>(
                value: _type,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                dropdownColor: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                items: ReminderType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(type.icon, color: type.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preview chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _type.color.withValues(alpha: 0.15),
                  _type.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(_type.icon, color: _type.color, size: 22),
                const SizedBox(width: 10),
                Text(
                  _type.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _type.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. John\'s Birthday',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remark',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarkCtrl,
            maxLines: 3,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note or remark...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_date);
    final timeStr = _time.format(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReminderRecurrence.values.map((r) {
              final isActive = _recurrence == r;
              return GestureDetector(
                onTap: () => setState(() => _recurrence = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifyBeforeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notify Me',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _notifyBefore,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                dropdownColor: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                items: ReminderModel.notifyBeforeOptions.map((mins) {
                  return DropdownMenuItem(
                    value: mins,
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          ReminderModel.notifyBeforeLabel(mins),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _notifyBefore = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isEditing ? 'Update Reminder' : 'Create Reminder',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
