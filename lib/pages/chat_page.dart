import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryFixed,
              child: const Icon(Icons.coffee, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Design Cafe',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Today, October 24', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
                _buildChatBubble(
                  sender: 'Designer',
                  time: '10:42 AM',
                  avatarUrl: 'https://i.pravatar.cc/100?img=11',
                  message: 'The counter area feels too large in this perspective. It seems like it might block the flow for the baristas behind the machine.',
                  isMe: false,
                ),
                const SizedBox(height: 24),
                _buildChatBubble(
                  sender: 'Minh',
                  time: '10:45 AM',
                  avatarUrl: 'https://i.pravatar.cc/100?img=68',
                  message: 'That\'s a fair point. I can see how it looks a bit tight on the workspace side. I\'ll reduce the size and send v2 by this afternoon.',
                  isMe: true,
                ),
              ],
            ),
          ),
          
          // Chat Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                )
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.placeholder),
                    onPressed: () {},
                  ),
                  IconButton(
                     icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.placeholder),
                     onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(24),
                       ),
                       child: const Text('Type a message...', style: TextStyle(color: AppColors.placeholder, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                     ),
                     child: const Text('Send >', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String sender,
    required String time,
    required String avatarUrl,
    required String message,
    required bool isMe,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
           CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      if (isMe) Text(time, style: const TextStyle(fontSize: 10, color: AppColors.placeholder)),
                      if (isMe) const SizedBox(width: 6),
                      Text(sender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      if (!isMe) const SizedBox(width: 6),
                      if (!isMe) Text(time, style: const TextStyle(fontSize: 10, color: AppColors.placeholder)),
                   ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primaryContainer : AppColors.white,
                  border: isMe ? null : Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? AppColors.white : AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatarUrl),
          ),
        ]
      ],
    );
  }
}
