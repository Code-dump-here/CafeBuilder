import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/ai_chat_service.dart';

class _ChatMessage {
  final bool isAi;
  final String text;
  final bool isError;

  const _ChatMessage({required this.isAi, required this.text, this.isError = false});
}

class AiAdvicePage extends StatefulWidget {
  const AiAdvicePage({super.key});

  @override
  State<AiAdvicePage> createState() => _AiAdvicePageState();
}

class _AiAdvicePageState extends State<AiAdvicePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const _greeting =
      "Hello! I'm your cafe design assistant. Ask me about layout, budgeting, "
      "materials, lighting, or working with designers and constructors.";

  final List<_ChatMessage> _messages = [
    const _ChatMessage(isAi: true, text: _greeting),
  ];

  AiChatSession? _session;
  bool _sending = false;

  bool get _available => AiChatService.isAvailable;

  @override
  void initState() {
    super.initState();
    if (_available) {
      _session = AiChatService.startSession();
    }
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    final session = _session;
    if (text.isEmpty || _sending || session == null) return;

    setState(() {
      _messages.add(_ChatMessage(isAi: false, text: text));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await session.send(text);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(isAi: true, text: reply)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
            isAi: true,
            text: "Sorry — I couldn't get a response. $e",
            isError: true,
          )));
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
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingBubble();
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.outlineVariant.withOpacity(0.3), height: 1),
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
              child: SelectableText(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: textColor,
                ),
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
    final enabled = _available && !_sending;

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
