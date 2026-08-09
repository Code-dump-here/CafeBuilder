import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/responses/api_responses.dart';
import '../theme/app_colors.dart';
import '../services/ai_chat_service.dart';

class _ChatMessage {
  final bool isAi;
  final String text;
  final bool isError;

  const _ChatMessage({required this.isAi, required this.text, this.isError = false});

  Map<String, dynamic> toJson() => {'a': isAi, 't': text};

  factory _ChatMessage.fromJson(Map<String, dynamic> j) =>
      _ChatMessage(isAi: j['a'] == true, text: j['t']?.toString() ?? '');
}

class AiAdvicePage extends StatefulWidget {
  /// When opened from a project, its details are given to the assistant so it
  /// can answer specifically instead of asking for numbers the app already has.
  final ProjectResponse? project;

  const AiAdvicePage({super.key, this.project});

  @override
  State<AiAdvicePage> createState() => _AiAdvicePageState();
}

class _AiAdvicePageState extends State<AiAdvicePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _greetingText => widget.project == null
      ? "Hello! I'm your cafe design assistant. Ask me about layout, budgeting, "
          "materials, lighting, or working with designers and constructors."
      : "Hello! I've got the details for **${widget.project!.name}**. Ask me "
          "anything about its layout, budget, or the providers you're working with.";

  final List<_ChatMessage> _messages = [];

  AiChatSession? _session;
  bool _sending = false;
  /// Partial reply while streaming; null when not mid-response.
  String? _streaming;
  /// The prompt that failed, so the error bubble can offer a retry.
  String? _lastFailedPrompt;
  bool _restoring = true;

  /// Per-project chats are stored separately so a project thread and the
  /// general assistant don't overwrite each other's history.
  String get _storageKey => widget.project == null
      ? 'ai_chat_history'
      : 'ai_chat_history_p${widget.project!.id}';

  /// Facts handed to the model as system context. Only includes what we
  /// actually have — an empty or unknown field is worse than omitting it.
  String? get _projectContext {
    final p = widget.project;
    if (p == null) return null;
    final lines = <String>[
      '- Project name: ${p.name}',
      if (p.address.trim().isNotEmpty) '- Location: ${p.address}',
      if (p.areaM2 > 0) '- Floor area: ${p.areaM2.toStringAsFixed(0)} m2',
      if (p.budget > 0) '- Total budget: ${p.budget.toStringAsFixed(0)} VND',
      if (p.status.trim().isNotEmpty) '- Current status: ${p.status}',
    ];
    final providers = p.providers
        .whereType<Map>()
        .map((m) => '${m['displayName'] ?? '?'} (${m['contractType'] ?? '?'}, ${m['status'] ?? '?'})')
        .where((s) => !s.startsWith('?'))
        .toList();
    lines.add(providers.isEmpty
        ? '- Providers: none engaged yet'
        : '- Providers: ${providers.join('; ')}');
    if (p.openFor.isNotEmpty) lines.add('- Currently recruiting: ${p.openFor.join(', ')}');
    return lines.join('\n');
  }

  /// Cap on stored/replayed turns. Every turn is re-sent to the model, so an
  /// uncapped history grows cost linearly and eventually hits the token limit.
  static const _maxStoredTurns = 20;

  List<String> get _starters => widget.project == null
      ? const [
          'How many seats fit my space?',
          'What should I budget for lighting?',
          'How do I brief a designer?',
        ]
      : const [
          'How many seats should this space fit?',
          'Is my budget realistic for this area?',
          'What should I check before approving a design?',
        ];

  bool get _available => AiChatService.isAvailable;

  @override
  void initState() {
    super.initState();
    _restoreConversation();
  }

  /// Reloads the previous conversation and replays it into the model, so the
  /// assistant keeps its context rather than just showing stale bubbles.
  Future<void> _restoreConversation() async {
    List<_ChatMessage> saved = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        saved = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((e) => _ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      // Corrupt or unreadable history should never block the page.
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(isAi: true, text: _greetingText));
      if (saved.isNotEmpty) _messages.addAll(saved);
      if (_available) {
        _session = AiChatService.startSession(
          history: [for (final m in saved) (isAi: m.isAi, text: m.text)],
          projectContext: _projectContext,
        );
      }
      _restoring = false;
    });
    if (saved.isNotEmpty) _scrollToBottom();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Skip the hardcoded greeting and any error bubbles — neither is a real
      // turn, and replaying them would confuse the model.
      final real = _messages.where((m) => !m.isError && m.text != _greetingText).toList();
      final trimmed = real.length > _maxStoredTurns
          ? real.sublist(real.length - _maxStoredTurns)
          : real;
      await prefs.setString(_storageKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _clearConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMessage(isAi: true, text: _greetingText));
      _streaming = null;
      _lastFailedPrompt = null;
      if (_available) {
        _session = AiChatService.startSession(projectContext: _projectContext);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Wait for the new bubble to be laid out before scrolling to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    final session = _session;
    if (text.isEmpty || _sending || session == null) return;

    setState(() {
      // Drop a previous failure bubble so retries don't stack up.
      _messages.removeWhere((m) => m.isError);
      _lastFailedPrompt = null;
      _messages.add(_ChatMessage(isAi: false, text: text));
      _controller.clear();
      _sending = true;
      _streaming = '';
    });
    _scrollToBottom();

    try {
      // Stream so text appears as it arrives instead of after the full reply.
      await for (final chunk in session.sendStream(text)) {
        if (!mounted) return;
        setState(() => _streaming = (_streaming ?? '') + chunk);
        _scrollToBottom();
      }
      if (!mounted) return;
      final full = (_streaming ?? '').trim();
      setState(() {
        _messages.add(_ChatMessage(isAi: true, text: full));
        _streaming = null;
      });
      _persist();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _streaming = null;
        // Remember the prompt so the error bubble can retry it, and drop the
        // unanswered user message — _send re-adds it on retry.
        _lastFailedPrompt = text;
        if (_messages.isNotEmpty && !_messages.last.isAi) _messages.removeLast();
        _messages.add(_ChatMessage(
          isAi: true,
          text: "Sorry — I couldn't get a response. $e",
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (!_available) _buildUnavailableBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_sending ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == _messages.length + (_sending ? 1 : 0)) {
                  return _buildStarters();
                }
                if (index == _messages.length) {
                  // Show partial text once the first chunk lands, otherwise
                  // the "thinking" indicator.
                  final partial = _streaming;
                  return (partial == null || partial.isEmpty)
                      ? _buildTypingBubble()
                      : _buildChatBubble(true, partial);
                }
                final msg = _messages[index];
                return _buildChatBubble(msg.isAi, msg.text, isError: msg.isError);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUnavailableBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFFFF4E5),
      child: Text(
        AiChatService.initError != null
            // Startup was attempted and failed — show why, rather than
            // misreporting it as "not configured".
            ? 'AI assistant failed to start: ${AiChatService.initError}'
            : kIsWeb
                ? 'AI assistant is not configured for web yet. Add your Firebase '
                    'web settings in lib/firebase_config.dart to enable it.'
                : 'AI assistant is unavailable. Check that Firebase AI Logic is '
                    'enabled for this project.',
        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8A5A00), height: 1.4),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expert Advice',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Get professional design consultation',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (_messages.length > 1)
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _sending ? null : _confirmClear,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.outlineVariant.withOpacity(0.3), height: 1),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start a new conversation?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.espresso)),
        content: Text('This clears the current chat and the assistant forgets its context.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFB3261E))),
          ),
        ],
      ),
    );
    if (ok == true) await _clearConversation();
  }

  /// Tappable prompts so a first-time user can see what the assistant is for
  /// without having to think of a question. Hidden once a conversation starts.
  Widget _buildStarters() {
    if (!_available || _sending || _messages.length > 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _starters
            .map((s) => GestureDetector(
                  onTap: () => _send(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.espresso),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiAvatar(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F3F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.espresso),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(bool isAi, String text, {bool isError = false}) {
    final bubbleColor = isAi
        ? (isError ? const Color(0xFFFDECEC) : const Color(0xFFF6F3F2))
        : AppColors.espresso;
    final textColor = isAi
        ? (isError ? const Color(0xFFB3261E) : AppColors.textPrimary)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) _buildAiAvatar(),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAi ? 4 : 20),
                  bottomRight: Radius.circular(isAi ? 20 : 4),
                ),
              ),
              // The model replies in markdown (**bold**, bullet lists), so
              // render it rather than showing raw asterisks.
              child: isAi && !isError
                  ? MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(fontSize: 15, height: 1.6, color: textColor),
                        listBullet: GoogleFonts.inter(fontSize: 15, height: 1.6, color: textColor),
                        strong: GoogleFonts.inter(
                            fontSize: 15, height: 1.6, color: textColor, fontWeight: FontWeight.w700),
                        em: GoogleFonts.inter(
                            fontSize: 15, height: 1.6, color: textColor, fontStyle: FontStyle.italic),
                        h1: GoogleFonts.inter(fontSize: 18, height: 1.5, color: textColor, fontWeight: FontWeight.bold),
                        h2: GoogleFonts.inter(fontSize: 17, height: 1.5, color: textColor, fontWeight: FontWeight.bold),
                        h3: GoogleFonts.inter(fontSize: 16, height: 1.5, color: textColor, fontWeight: FontWeight.bold),
                        code: GoogleFonts.robotoMono(fontSize: 13, color: textColor),
                        blockquote: GoogleFonts.inter(fontSize: 15, height: 1.6, color: textColor),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.6,
                            color: textColor,
                          ),
                        ),
                        if (isError && _lastFailedPrompt != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _sending ? null : () => _send(_lastFailedPrompt),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFB3261E)),
                                const SizedBox(width: 6),
                                Text(
                                  'Retry',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB3261E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 12),
          if (!isAi) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD9EAA3).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.psychology_outlined, color: Color(0xFF33210D), size: 24),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
    );
  }

  Widget _buildInputArea() {
    // Also blocked while restoring, so a message can't be sent before the
    // previous conversation has been replayed into the model.
    final enabled = _available && !_sending && !_restoring;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _available ? 'Ask a question...' : 'AI assistant unavailable',
                  hintStyle: GoogleFonts.inter(color: AppColors.outline, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFF56642B) : AppColors.outlineVariant,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: enabled ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
