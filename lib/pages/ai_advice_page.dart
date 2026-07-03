import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AiAdvicePage extends StatefulWidget {
  const AiAdvicePage({super.key});

  @override
  State<AiAdvicePage> createState() => _AiAdvicePageState();
}

class _AiAdvicePageState extends State<AiAdvicePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isAi': true,
      'text': 'Hello! I\'m your interior design assistant. How can I help you today?',
    },
    {
      'isAi': false,
      'text': 'I\'m planning to renovate my coffee shop. What should I consider?',
    },
    {
      'isAi': true,
      'text': 'Great! For a coffee shop renovation, here are the key considerations:\n\n'
          '1. **Customer flow** and seating layout to optimize efficiency.\n'
          '2. **Coffee bar** design and equipment placement for barista workflow.\n'
          '3. **Lighting** (warm, inviting atmosphere) to enhance the mood.\n'
          '4. **Materials** (durable, easy to clean) for high-traffic surfaces.\n'
          '5. **Branding** and visual identity throughout the space.\n\n'
          'What\'s your budget range?',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg['isAi'] as bool, msg['text'] as String);
              },
            ),
          ),
          _buildInputArea(),
        ],
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

  Widget _buildChatBubble(bool isAi, String text) {
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
                color: isAi ? const Color(0xFFF6F3F2) : AppColors.espresso,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAi ? 4 : 20),
                  bottomRight: Radius.circular(isAi ? 20 : 4),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: isAi ? AppColors.textPrimary : Colors.white,
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
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: GoogleFonts.inter(color: AppColors.outline, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF56642B),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    setState(() {
                      _messages.add({'isAi': false, 'text': _controller.text});
                      _controller.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
