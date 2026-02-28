part of 'create_task_screen.dart';

// ═══════════════════════════════════════════════════════
//  STEP 2 — Details + AI (Combined)
//  Upload PDF → AI fills fields + generates subtasks
//  OR user fills everything manually
// ═══════════════════════════════════════════════════════
class _StepDetailsWithAI extends StatefulWidget {
  // ── Form fields
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

  // ── AI
  final bool hasPdfAttachment;
  final bool isTeamMode;
  final AIAnalysisResult? analysis;
  final bool isAnalyzing;
  final String? errorMessage;
  final VoidCallback onAnalyze;
  final ValueChanged<List<AISubTask>> onSubtasksUpdated;
  final Future<void> Function(String message) onRefine;

  const _StepDetailsWithAI({
    required this.titleCtrl,
    required this.descCtrl,
    required this.subjectCtrl,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.isRecurring,
    required this.recurrenceRule,
    required this.attachments,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onPickFiles,
    required this.onPriority,
    required this.onRecurringToggle,
    required this.onRuleSelect,
    required this.onRemoveFile,
    required this.hasPdfAttachment,
    required this.isTeamMode,
    required this.analysis,
    required this.isAnalyzing,
    required this.errorMessage,
    required this.onAnalyze,
    required this.onSubtasksUpdated,
    required this.onRefine,
  });

  @override
  State<_StepDetailsWithAI> createState() => _StepDetailsWithAIState();
}

class _StepDetailsWithAIState extends State<_StepDetailsWithAI> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isRefining = false;
  bool _subtasksExpanded = true;
  final List<_ChatBubble> _chatHistory = [];

  // AI Auto-Fill toggle
  bool _aiAutoFillEnabled = true;

  // Track which fields were auto-filled by AI
  bool _titleFilledByAI = false;
  bool _subjectFilledByAI = false;
  bool _descFilledByAI = false;

  @override
  void didUpdateWidget(_StepDetailsWithAI old) {
    super.didUpdateWidget(old);

    // Auto-trigger AI analysis when toggle is ON and PDF is newly attached
    if (_aiAutoFillEnabled &&
        !old.hasPdfAttachment &&
        widget.hasPdfAttachment &&
        widget.analysis == null &&
        !widget.isAnalyzing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAnalyze();
      });
    }

    // Detect when AI finishes analysis and fills fields
    if (old.analysis == null && widget.analysis != null) {
      setState(() {
        _titleFilledByAI = widget.titleCtrl.text == widget.analysis!.title;
        _subjectFilledByAI =
            widget.subjectCtrl.text == widget.analysis!.subject;
        _descFilledByAI = widget.descCtrl.text == widget.analysis!.summary;
      });
      // Scroll down to show results
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isRefining) return;

    setState(() {
      _chatHistory.add(_ChatBubble(text: text, isUser: true));
      _isRefining = true;
    });
    _chatCtrl.clear();

    try {
      await widget.onRefine(text);
      setState(() {
        _chatHistory.add(_ChatBubble(
          text: 'Done! I\'ve updated the subtasks based on your feedback.',
          isUser: false,
        ));
      });
    } catch (_) {
      setState(() {
        _chatHistory.add(_ChatBubble(
          text: 'Sorry, I couldn\'t process that. Please try again.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isRefining = false);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnalysis = widget.analysis != null;
    final showChat = hasAnalysis;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AI Banner
                _buildAIBanner(),
                const SizedBox(height: 24),

                // ── Form Fields
                _buildField(
                  label: 'Task Title',
                  required: true,
                  isAIFilled: _titleFilledByAI,
                  child: _fancyField(
                    widget.titleCtrl,
                    'What needs to be done?',
                    Icons.title_rounded,
                    onChanged: (_) {
                      if (_titleFilledByAI) {
                        setState(() => _titleFilledByAI = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                _buildField(
                  label: 'Subject / Category',
                  isAIFilled: _subjectFilledByAI,
                  child: _fancyField(
                    widget.subjectCtrl,
                    'e.g. Mathematics, Design',
                    Icons.book_outlined,
                    onChanged: (_) {
                      if (_subjectFilledByAI) {
                        setState(() => _subjectFilledByAI = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                _buildField(
                  label: 'Description',
                  isAIFilled: _descFilledByAI,
                  child: _fancyField(
                    widget.descCtrl,
                    'Add more details...',
                    Icons.notes_rounded,
                    maxLines: 3,
                    onChanged: (_) {
                      if (_descFilledByAI) {
                        setState(() => _descFilledByAI = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Schedule
                _sectionLabel('Due Date & Time'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _tapTile(
                        Icons.calendar_today_rounded,
                        DateFormat('MMM dd, yyyy').format(widget.dueDate),
                        widget.onDateTap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tapTile(
                        Icons.access_time_rounded,
                        widget.dueTime.format(context),
                        widget.onTimeTap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Priority
                _sectionLabel('Priority'),
                const SizedBox(height: 10),
                _buildPriorityRow(),
                const SizedBox(height: 20),

                // ── Recurring
                _buildRecurringSection(),
                const SizedBox(height: 20),

                // ── Attachments
                _buildAttachments(),

                // ── AI Subtasks
                if (hasAnalysis &&
                    widget.analysis!.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _buildSubtaskSection(),
                ],

                // ── Chat History
                if (_chatHistory.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildChatHistory(),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Chat input bar (team mode with analysis)
        if (showChat) _buildChatInput(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  AI BANNER
  // ═══════════════════════════════════════════════════════
  Widget _buildAIBanner() {
    // Loading state
    if (widget.isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667EEA).withValues(alpha: 0.08),
              const Color(0xFF764BA2).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF667EEA).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyzing PDF...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'AI is reading your document',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Already analyzed — success state
    if (widget.analysis != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF11998E).withValues(alpha: 0.08),
              const Color(0xFF38EF7D).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF11998E).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Analysis Complete',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Fields auto-filled \u2022 Edit anything below',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onAnalyze,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Color(0xFF11998E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Toggle banner (no analysis yet)
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _aiAutoFillEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA).withValues(alpha: 0.1),
                  const Color(0xFF764BA2).withValues(alpha: 0.06),
                ],
              )
            : null,
        color: _aiAutoFillEnabled ? null : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _aiAutoFillEnabled
              ? const Color(0xFF667EEA).withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        boxShadow: _aiAutoFillEnabled ? null : AppTheme.softShadows,
      ),
      child: Column(
        children: [
          // Toggle row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _aiAutoFillEnabled
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  color: _aiAutoFillEnabled
                      ? null
                      : const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _aiAutoFillEnabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _aiAutoFillEnabled
                      ? Colors.white
                      : const Color(0xFF667EEA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Auto-Fill',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _aiAutoFillEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _aiAutoFillEnabled
                          ? (widget.hasPdfAttachment
                              ? 'PDF ready \u2022 Tap Analyze to fill'
                              : 'Upload a PDF to auto-fill')
                          : 'Turned off \u2022 Fill manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle switch
              Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: _aiAutoFillEnabled,
                  onChanged: (val) {
                    setState(() => _aiAutoFillEnabled = val);
                    // If just toggled ON with a PDF already attached, auto-trigger
                    if (val &&
                        widget.hasPdfAttachment &&
                        widget.analysis == null &&
                        !widget.isAnalyzing) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.onAnalyze();
                      });
                    }
                  },
                  activeTrackColor: const Color(0xFF667EEA),
                  inactiveTrackColor:
                      AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),

          // Analyze button (only when toggle ON + PDF attached)
          if (_aiAutoFillEnabled && widget.hasPdfAttachment) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.onAnalyze,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analyze & Auto-Fill',
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

          // Error message
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════════════════════
  //  FORM FIELD WITH AI BADGE
  // ═══════════════════════════════════════════════════════
  Widget _buildField({
    required String label,
    bool required = false,
    bool isAIFilled = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label${required ? ' *' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (isAIFilled) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PRIORITY ROW
  // ═══════════════════════════════════════════════════════
  Widget _buildPriorityRow() {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = widget.priority == p;
        final colors = {
          TaskPriority.high: (
            AppColors.priorityHighBg,
            AppColors.priorityHighText,
          ),
          TaskPriority.medium: (
            AppColors.priorityMediumBg,
            AppColors.priorityMediumText,
          ),
          TaskPriority.low: (
            AppColors.priorityLowBg,
            AppColors.priorityLowText,
          ),
        };
        final (bg, text) = colors[p]!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: p != TaskPriority.low ? 8 : 0),
            child: GestureDetector(
              onTap: () => widget.onPriority(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? bg : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? text : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: text.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : AppTheme.softShadows,
                ),
                child: Center(
                  child: Text(
                    p.name[0].toUpperCase() + p.name.substring(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? text : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  RECURRING SECTION
  // ═══════════════════════════════════════════════════════
  Widget _buildRecurringSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recurring Task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: widget.isRecurring,
                onChanged: widget.onRecurringToggle,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (widget.isRecurring) ...[
            const SizedBox(height: 12),
            Row(
              children: RecurrenceRule.values
                  .where((r) => r != RecurrenceRule.none)
                  .map((r) {
                final isSel = widget.recurrenceRule == r;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: r != RecurrenceRule.monthly ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => widget.onRuleSelect(r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            r.name[0].toUpperCase() + r.name.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ATTACHMENTS
  // ═══════════════════════════════════════════════════════
  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Attachments'),
        SizedBox(height: 10),
        GestureDetector(
          onTap: widget.onPickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 34,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to upload files',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'PDF files can be analyzed by AI',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...widget.attachments.asMap().entries.map((e) {
            final fileName = e.value.path.split('/').last;
            final isPdf = fileName.toLowerCase().endsWith('.pdf');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.softShadows,
                  border: isPdf
                      ? Border.all(
                          color: const Color(0xFF667EEA).withValues(
                            alpha: 0.2,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_outlined,
                      size: 20,
                      color: isPdf
                          ? const Color(0xFF667EEA)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPdf && widget.analysis == null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => widget.onRemoveFile(e.key),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SUBTASK SECTION (Team mode, after AI analysis)
  // ═══════════════════════════════════════════════════════
  Widget _buildSubtaskSection() {
    final subtasks = widget.analysis!.subtasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _subtasksExpanded = !_subtasksExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withValues(alpha: 0.1),
                  const Color(0xFF764BA2).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Color(0xFF667EEA),
                ),
                SizedBox(width: 10),
                Text(
                  'AI Subtasks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${subtasks.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _subtasksExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              const SizedBox(height: 10),
              ...subtasks.asMap().entries.map((e) {
                return _AISubtaskCard(
                  index: e.key,
                  subtask: e.value,
                  onDelete: () {
                    final updated = List<AISubTask>.from(subtasks);
                    updated.removeAt(e.key);
                    widget.onSubtasksUpdated(updated);
                  },
                );
              }),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _subtasksExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CHAT HISTORY
  // ═══════════════════════════════════════════════════════
  Widget _buildChatHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.chat_rounded,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            SizedBox(width: 6),
            Text(
              'AI CONVERSATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._chatHistory.map((b) => _ChatBubbleWidget(bubble: b)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  CHAT INPUT BAR
  // ═══════════════════════════════════════════════════════
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _chatCtrl,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Refine subtasks with AI...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isRefining ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isRefining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════
  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _fancyField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _tapTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadows,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Subtask Card ──────────────────────────────────────────────────────────
class _AISubtaskCard extends StatelessWidget {
  final int index;
  final AISubTask subtask;
  final VoidCallback onDelete;

  const _AISubtaskCard({
    required this.index,
    required this.subtask,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      'high': (AppColors.priorityHighBg, AppColors.priorityHighText),
      'medium': (AppColors.priorityMediumBg, AppColors.priorityMediumText),
      'low': (AppColors.priorityLowBg, AppColors.priorityLowText),
    };
    final prio = subtask.priority.toLowerCase();
    final (bg, text) = priorityColors[prio] ??
        (AppColors.priorityLowBg, AppColors.priorityLowText);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (subtask.description.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              subtask.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  prio.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
              ),
              if (subtask.estimatedHours > 0) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 3),
                Text(
                  '${subtask.estimatedHours}h',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────
class _ChatBubble {
  final String text;
  final bool isUser;
  _ChatBubble({required this.text, required this.isUser});
}

class _ChatBubbleWidget extends StatelessWidget {
  final _ChatBubble bubble;
  const _ChatBubbleWidget({required this.bubble});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: bubble.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubble.isUser
              ? AppColors.primary
              : const Color(0xFF667EEA).withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(bubble.isUser ? 18 : 4),
            bottomRight: Radius.circular(bubble.isUser ? 4 : 18),
          ),
        ),
        child: Text(
          bubble.text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: bubble.isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
