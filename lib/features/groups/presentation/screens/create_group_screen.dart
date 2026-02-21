import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/group_providers.dart';
import '../../domain/models/group_model.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _memberIdController = TextEditingController();
  final List<String> _memberIds = [];
  PermissionMode _permissionMode = PermissionMode.leader;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  void _addMember() {
    final id = _memberIdController.text.trim();
    if (id.isNotEmpty && !_memberIds.contains(id)) {
      setState(() {
        _memberIds.add(id);
        _memberIdController.clear();
      });
    }
  }

  void _createGroup() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    final allMembers = [user.uid, ..._memberIds];

    final group = GroupModel(
      id: '',
      name: _nameController.text.trim(),
      leaderId: user.uid,
      memberIds: allMembers,
      permissionMode: _permissionMode,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(groupRepositoryProvider).createGroup(group);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createGroup),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        type: StepperType.vertical,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 2)
                  Expanded(
                    child: AppButton(
                      label: 'Continue',
                      height: 48,
                      onPressed: () {
                        if (_currentStep == 0 &&
                            _nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Group name is required')),
                          );
                          return;
                        }
                        setState(() => _currentStep++);
                      },
                    ),
                  )
                else
                  Expanded(
                    child: AppButton(
                      label: 'Create Group',
                      icon: Icons.check_rounded,
                      isLoading: _isLoading,
                      height: 48,
                      onPressed: _createGroup,
                    ),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        steps: [
          // Step 1: Name
          Step(
            title: Text('Group Name',
                style: Theme.of(context).textTheme.titleSmall),
            subtitle: _nameController.text.isNotEmpty
                ? Text(_nameController.text)
                : null,
            isActive: _currentStep >= 0,
            state:
                _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  hint: 'e.g. CS101 Project Team',
                  prefixIcon: Icons.group_outlined,
                ),
              ],
            ),
          ),

          // Step 2: Add Members
          Step(
            title: Text(AppStrings.addMembers,
                style: Theme.of(context).textTheme.titleSmall),
            subtitle: _memberIds.isNotEmpty
                ? Text('${_memberIds.length} members added')
                : null,
            isActive: _currentStep >= 1,
            state:
                _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _memberIdController,
                        hint: 'Enter User ID (e.g. TH-A7X9K2)',
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addMember,
                      icon: const Icon(Icons.add_circle_rounded),
                      color: AppColors.primary,
                      iconSize: 36,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._memberIds.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _memberIds.removeAt(entry.key)),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Step 3: Permissions
          Step(
            title: Text(AppStrings.permissions,
                style: Theme.of(context).textTheme.titleSmall),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                _PermissionOption(
                  title: AppStrings.leaderLed,
                  description:
                      'Only the leader can assign tasks and approve submissions',
                  icon: Icons.shield_outlined,
                  isSelected: _permissionMode == PermissionMode.leader,
                  onTap: () => setState(
                      () => _permissionMode = PermissionMode.leader),
                ),
                const SizedBox(height: 10),
                _PermissionOption(
                  title: AppStrings.democratic,
                  description:
                      'All members can create and assign tasks equally',
                  icon: Icons.handshake_outlined,
                  isSelected:
                      _permissionMode == PermissionMode.democratic,
                  onTap: () => setState(
                      () => _permissionMode = PermissionMode.democratic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PermissionOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerTheme.color ?? Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primary : null, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
