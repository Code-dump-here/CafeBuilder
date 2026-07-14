import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ThreadDetailPage extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final Color tagTextColor;

  const ThreadDetailPage({
    super.key,
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        title: Text(
          'Discussion Thread',
           style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: tagTextColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso),
                  ),
                  const SizedBox(height: 24),
                  
                  // Initial Message
                  _buildMessage(
                    isMe: false,
                    avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150',
                    name: 'Elena (Designer)',
                    time: '2 hours ago',
                    message: "I've been looking at the section drawings for the main bar counter. To integrate the seamless brass inlays within the mahogany, we might need a slightly thicker edge profile (approx. 45mm instead of 30mm).",
                  ),
                  const SizedBox(height: 20),
                  
                  // Reply
                  _buildMessage(
                    isMe: true,
                    avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150',
                    name: 'Minh (Owner)',
                    time: '1 hour ago',
                    message: "45mm sounds a bit bulky. Can we bevel the bottom edge so it looks thinner from the customer's POV while maintaining structural integrity for the brass?",
                  ),
                  const SizedBox(height: 20),
                  
                  // Constructor Reply
                  _buildMessage(
                    isMe: false,
                    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150',
                    name: 'Trung (Contractor)',
                    time: '45 mins ago',
                    message: "Yes, we can undercut the edge by 45 degrees. I'll shoot over a quick sketch of the joint detail. It will cost slightly more in CNC routing time, maybe +5% on the carpentry budget.",
                    attachments: ['https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&q=80&w=300'],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required bool isMe,
    required String avatarUrl,
    required String name,
    required String time,
    required String message,
    List<String>? attachments,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(width: 8),
                  Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.espresso : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12),
                  ),
                  border: isMe ? null : Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (attachments != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: attachments.map((url) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, height: 100, width: 140, fit: BoxFit.cover),
                        )).toList(),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 16),
          // Empty space to push bubble left
        ] else ...[
          const SizedBox(width: 32),
        ]
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.placeholder),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.espresso),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
