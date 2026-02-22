part of 'create_task_screen.dart';

// ═══════════════════════════════════════════════════════
//  STEP 1 — Mode Select
// ═══════════════════════════════════════════════════════
class _StepMode extends StatelessWidget {
  final _TaskMode mode;
  final ValueChanged<_TaskMode> onSelect;
  const _StepMode({required this.mode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you working\non this task?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Choose individual for personal tasks or team to collaborate.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 36),
          _ModeCard(
            icon: Icons.person_rounded,
            title: 'Individual',
            subtitle: 'A personal task only you can see and manage',
            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            selected: mode == _TaskMode.individual,
            onTap: () => onSelect(_TaskMode.individual),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.groups_rounded,
            title: 'Team',
            subtitle: 'Collaborate with others, assign roles and set rules',
            gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
            selected: mode == _TaskMode.team,
            onTap: () => onSelect(_TaskMode.team),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle,
      required this.gradient, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))]
              : AppTheme.softShadows,
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.4)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : AppColors.bgColor,
                border: Border.all(color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3), width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STEP 2 — Task Details
// ═══════════════════════════════════════════════════════
class _StepDetails extends StatelessWidget {
  final TextEditingController titleCtrl, descCtrl, subjectCtrl;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final TaskPriority priority;
  final bool isRecurring;
  final RecurrenceRule recurrenceRule;
  final List<File> attachments;
  final VoidCallback onDateTap, onTimeTap, onPickFiles;
  final ValueChanged<TaskPriority> onPriority;
  final ValueChanged<bool> onRecurringToggle;
  final ValueChanged<RecurrenceRule> onRuleSelect;
  final ValueChanged<int> onRemoveFile;

  const _StepDetails({
    required this.titleCtrl, required this.descCtrl, required this.subjectCtrl,
    required this.dueDate, required this.dueTime, required this.priority,
    required this.isRecurring, required this.recurrenceRule, required this.attachments,
    required this.onDateTap, required this.onTimeTap, required this.onPriority,
    required this.onRecurringToggle, required this.onRuleSelect,
    required this.onPickFiles, required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Task Title *'),
          const SizedBox(height: 8),
          _fancyField(titleCtrl, 'What needs to be done?', Icons.title_rounded),
          const SizedBox(height: 16),

          _sectionLabel('Description'),
          const SizedBox(height: 8),
          _fancyField(descCtrl, 'Add more details...', Icons.notes_rounded, maxLines: 3),
          const SizedBox(height: 16),

          _sectionLabel('Subject / Category'),
          const SizedBox(height: 8),
          _fancyField(subjectCtrl, 'e.g. Mathematics, Design', Icons.book_outlined),
          const SizedBox(height: 20),

          _sectionLabel('Due Date & Time'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _tapTile(Icons.calendar_today_rounded, DateFormat('MMM dd, yyyy').format(dueDate), onDateTap)),
            const SizedBox(width: 12),
            Expanded(child: _tapTile(Icons.access_time_rounded, dueTime.format(context), onTimeTap)),
          ]),
          const SizedBox(height: 20),

          _sectionLabel('Priority'),
          const SizedBox(height: 10),
          Row(children: TaskPriority.values.map((p) {
            final isSelected = priority == p;
            final colors = {
              TaskPriority.high: (AppColors.priorityHighBg, AppColors.priorityHighText),
              TaskPriority.medium: (AppColors.priorityMediumBg, AppColors.priorityMediumText),
              TaskPriority.low: (AppColors.priorityLowBg, AppColors.priorityLowText),
            };
            final (bg, text) = colors[p]!;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p != TaskPriority.low ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onPriority(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? text : Colors.transparent, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: text.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))] : AppTheme.softShadows,
                    ),
                    child: Center(child: Text(
                      p.name[0].toUpperCase() + p.name.substring(1),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? text : AppColors.textSecondary),
                    )),
                  ),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Recurring
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadows),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.repeat_rounded, size: 22, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Recurring Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ]),
                  Switch.adaptive(value: isRecurring, onChanged: onRecurringToggle, activeTrackColor: AppColors.primary),
                ],
              ),
              if (isRecurring) ...[
                const SizedBox(height: 12),
                Row(children: RecurrenceRule.values.where((r) => r != RecurrenceRule.none).map((r) {
                  final isSel = recurrenceRule == r;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: r != RecurrenceRule.monthly ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => onRuleSelect(r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primary : Colors.transparent),
                          ),
                          child: Center(child: Text(
                            r.name[0].toUpperCase() + r.name.substring(1),
                            style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600, color: isSel ? AppColors.primary : AppColors.textSecondary),
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // Files
          _sectionLabel('Attachments'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onPickFiles,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), style: BorderStyle.solid),
              ),
              child: Column(children: [
                Icon(Icons.cloud_upload_outlined, size: 34, color: AppColors.primary.withValues(alpha: 0.6)),
                const SizedBox(height: 6),
                Text('Tap to upload files', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...attachments.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceColor, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.softShadows),
                child: Row(children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value.path.split('/').last, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  GestureDetector(onTap: () => onRemoveFile(e.key), child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error)),
                ]),
              ),
            )),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5));

  Widget _fancyField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceColor, borderRadius: BorderRadius.circular(18), boxShadow: AppTheme.softShadows),
      child: TextField(
        controller: ctrl, maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _tapTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(color: AppColors.surfaceColor, borderRadius: BorderRadius.circular(18), boxShadow: AppTheme.softShadows),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ]),
      ),
    );
  }
}
