// ignore_for_file: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/task_providers.dart';
import '../../domain/models/task_model.dart';
import '../../../groups/data/repositories/group_repository.dart';
import '../../../groups/domain/models/group_model.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../friends/presentation/providers/friend_providers.dart';
import '../../../friends/domain/models/friend_model.dart';

part 'create_task_steps.dart';
part 'create_task_team_steps.dart';

// ─── Wizard State ─────────────────────────────────────────────────────────────
enum _TaskMode { individual, team }
enum _TeamSource { newTeam, existingTeam }

class CreateTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? existingTask;
  const CreateTaskScreen({super.key, this.existingTask});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _step = 0; // 0=Mode, 1=Details, 2=Team, 3=Review
  bool _isLoading = false;
  bool _isEditing = false;

  // ── Step 1: Mode
  _TaskMode _mode = _TaskMode.individual;

  // ── Step 2: Details
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  TaskPriority _priority = TaskPriority.medium;
  bool _isRecurring = false;
  RecurrenceRule _recurrenceRule = RecurrenceRule.none;
  List<File> _attachments = [];

  // ── Step 3: Team
  _TeamSource _teamSource = _TeamSource.newTeam;
  final _teamNameCtrl = TextEditingController();
  final _memberSearchCtrl = TextEditingController();
  List<FriendModel> _selectedMembers = [];
  String? _leaderId;
  String? _leaderName;
  PermissionMode _permMode = PermissionMode.leader;
  // Existing team
  GroupModel? _selectedGroup;
  String? _assigneeId;
  String? _assigneeName;
  // Search results
  List<UserProfile> _searchResults = [];
  bool _searching = false;

  int get _totalSteps => _mode == _TaskMode.team ? 4 : 3;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _isEditing = true;
      final t = widget.existingTask!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _subjectCtrl.text = t.subject;
      _dueDate = t.dueDate;
      _dueTime = TimeOfDay.fromDateTime(t.dueDate);
      _priority = t.priority;
      _isRecurring = t.isRecurring;
      _recurrenceRule = t.recurrenceRule;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    _teamNameCtrl.dispose();
    _memberSearchCtrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
  }

  void _next() {
    // Validate current step
    if (_step == 1 && _titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a task title');
      return;
    }
    if (_step == 2 && _mode == _TaskMode.team) {
      if (_teamSource == _TeamSource.newTeam &&
          _teamNameCtrl.text.trim().isEmpty) {
        _snack('Please enter a team name');
        return;
      }
      if (_teamSource == _TeamSource.existingTeam && _selectedGroup == null) {
        _snack('Please select a team');
        return;
      }
    }
    final nextStep = _step + 1;
    if (nextStep < _totalSteps) _goTo(nextStep);
  }

  void _back() {
    if (_step > 0) _goTo(_step - 1);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _searchMembers(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(friendRepositoryProvider).searchUsers(q);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _searching = false);
    }
  }

  bool _isMemberSelected(String uid) =>
      _selectedMembers.any((m) => m.friendUid == uid);

  void _toggleFriend(FriendModel f) {
    setState(() {
      if (_isMemberSelected(f.friendUid)) {
        _selectedMembers.removeWhere((m) => m.friendUid == f.friendUid);
        if (_leaderId == f.friendUid) { _leaderId = null; _leaderName = null; }
      } else {
        _selectedMembers.add(f);
      }
    });
  }

  void _toggleSearchResult(UserProfile u) {
    setState(() {
      if (_isMemberSelected(u.uid)) {
        _selectedMembers.removeWhere((m) => m.friendUid == u.uid);
        if (_leaderId == u.uid) { _leaderId = null; _leaderName = null; }
      } else {
        _selectedMembers.add(FriendModel(
          id: '', userId: '', friendUid: u.uid,
          friendName: u.displayName, friendEmail: u.email,
          connectedAt: DateTime.now(),
        ));
      }
    });
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      final dueDateTime = DateTime(
        _dueDate.year, _dueDate.month, _dueDate.day,
        _dueTime.hour, _dueTime.minute,
      );

      if (_mode == _TaskMode.individual || _isEditing) {
        final task = TaskModel(
          id: _isEditing ? widget.existingTask!.id : '',
          userId: user.uid,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          dueDate: dueDateTime,
          priority: _priority,
          status: _isEditing ? widget.existingTask!.status : TaskStatus.pending,
          isRecurring: _isRecurring,
          recurrenceRule: _isRecurring ? _recurrenceRule : RecurrenceRule.none,
          attachments: _isEditing ? widget.existingTask!.attachments : [],
          createdAt: _isEditing ? widget.existingTask!.createdAt : DateTime.now(),
        );
        if (_isEditing) {
          await ref.read(taskNotifierProvider.notifier).updateTask(task);
        } else {
          final created = await ref.read(taskNotifierProvider.notifier).createTask(task);
          if (created != null && _attachments.isNotEmpty) {
            for (final file in _attachments) {
              await ref.read(taskNotifierProvider.notifier).uploadAttachment(created.id, file);
            }
          }
        }
      } else {
        // Team task
        final repo = ref.read(groupRepositoryProvider);
        String groupId;
        String leaderId;

        if (_teamSource == _TeamSource.newTeam) {
          final allMemberIds = [
            user.uid,
            ..._selectedMembers.map((m) => m.friendUid),
          ];
          final group = GroupModel(
            id: '', name: _teamNameCtrl.text.trim(),
            leaderId: _leaderId ?? user.uid,
            memberIds: allMemberIds,
            permissionMode: _permMode,
            createdAt: DateTime.now(),
          );
          groupId = await repo.createGroupReturnId(group);
          leaderId = _leaderId ?? user.uid;
        } else {
          groupId = _selectedGroup!.id;
          leaderId = _selectedGroup!.leaderId;
        }

        final assignedTo = _teamSource == _TeamSource.existingTeam
            ? (_assigneeId ?? leaderId)
            : (_leaderId ?? user.uid);

        final groupTask = GroupTaskModel(
          id: '', groupId: groupId,
          assignedTo: assignedTo,
          assignedBy: user.uid,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: dueDateTime,
          priority: _priority.name,
          status: GroupTaskStatus.pending,
          createdAt: DateTime.now(),
        );
        await repo.createGroupTask(groupTask);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _snack('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            const SizedBox(height: 4),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepMode(
                    mode: _mode,
                    onSelect: (m) => setState(() => _mode = m),
                  ),
                  _StepDetails(
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    subjectCtrl: _subjectCtrl,
                    dueDate: _dueDate,
                    dueTime: _dueTime,
                    priority: _priority,
                    isRecurring: _isRecurring,
                    recurrenceRule: _recurrenceRule,
                    attachments: _attachments,
                    onDateTap: _pickDate,
                    onTimeTap: _pickTime,
                    onPriority: (p) => setState(() => _priority = p),
                    onRecurringToggle: (v) => setState(() => _isRecurring = v),
                    onRuleSelect: (r) => setState(() => _recurrenceRule = r),
                    onPickFiles: _pickFiles,
                    onRemoveFile: (i) => setState(() => _attachments.removeAt(i)),
                  ),
                  if (_mode == _TaskMode.team)
                    _StepTeam(
                      teamSource: _teamSource,
                      onSourceChange: (s) => setState(() => _teamSource = s),
                      teamNameCtrl: _teamNameCtrl,
                      memberSearchCtrl: _memberSearchCtrl,
                      selectedMembers: _selectedMembers,
                      searchResults: _searchResults,
                      searching: _searching,
                      leaderId: _leaderId,
                      leaderName: _leaderName,
                      permMode: _permMode,
                      onSearch: _searchMembers,
                      onToggleFriend: _toggleFriend,
                      onToggleSearch: _toggleSearchResult,
                      onSelectLeader: (uid, name) => setState(() {
                        _leaderId = uid; _leaderName = name;
                      }),
                      onPermMode: (m) => setState(() => _permMode = m),
                      selectedGroup: _selectedGroup,
                      assigneeId: _assigneeId,
                      assigneeName: _assigneeName,
                      onSelectGroup: (g) => setState(() {
                        _selectedGroup = g;
                        _assigneeId = null; _assigneeName = null;
                      }),
                      onSelectAssignee: (id, name) => setState(() {
                        _assigneeId = id; _assigneeName = name;
                      }),
                    ),
                  _StepReview(
                    mode: _mode,
                    title: _titleCtrl.text,
                    dueDate: _dueDate,
                    dueTime: _dueTime,
                    priority: _priority,
                    teamSource: _teamSource,
                    teamName: _teamNameCtrl.text,
                    selectedGroup: _selectedGroup,
                    selectedMembers: _selectedMembers,
                    leaderName: _leaderName,
                    permMode: _permMode,
                    assigneeName: _assigneeName,
                    onEdit: _goTo,
                  ),
                ],
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = _mode == _TaskMode.team
        ? ['Choose Mode', 'Task Details', 'Team Setup', 'Review']
        : ['Choose Mode', 'Task Details', 'Review'];
    final title = _step < titles.length ? titles[_step] : 'Create Task';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgColor, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Task' : title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_step + 1} / $_totalSteps',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: done || active ? AppColors.primary : AppColors.bgColor,
                  gradient: active
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary])
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavBar() {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: _back,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.bgColor, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: isLast
                ? GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text('Create Task', style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _isEditing ? null : _next,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _dueTime);
    if (time != null) setState(() => _dueTime = time);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.where((p) => p != null).map((p) => File(p!)));
      });
    }
  }
}
