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
          Text('How are you working\non this task?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.2)),
          SizedBox(height: 8),
          Text('Choose individual for personal tasks or team to collaborate.',
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
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.4)),
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
