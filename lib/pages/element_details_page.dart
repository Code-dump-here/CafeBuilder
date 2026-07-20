import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/service_provider_service.dart';

class ElementDetailsPage extends StatefulWidget {
  const ElementDetailsPage({super.key});

  @override
  State<ElementDetailsPage> createState() => _ElementDetailsPageState();
}

class _ElementDetailsPageState extends State<ElementDetailsPage> {
  String _ownerLabel = 'Owner (shop owner)';
  bool _loadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    try {
      final name = await ShopOwnerService.getCurrentOwnerFirstName();
      if (mounted) {
        setState(() {
          _ownerLabel = '$name (shop owner)';
          _loadingOwner = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOwner = false);
    }
  }

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
        title: const Text(
          'Review Revised File',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('REVISED v2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '3D Interior Perspective',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Designer's Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('Designer\'s Note', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '"I adjusted the lighting tone to be slightly warmer to match the morning sun vibe we discussed. I also reduced the counter size by 15% to improve the flow of the customer seating area."',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Version Comparison
            const Text('Version Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.network(
                              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=400',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              height: 100,
                              color: Colors.white.withOpacity(0.6), // faded effect
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                color: Colors.black54,
                                child: const Text('v1 Original', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('SUBMITTED JULY 12', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.network(
                              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=400',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                color: Colors.green.shade700,
                                child: const Text('v2 Revised', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('LATEST REVISION', style: TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Revision Timeline
            const Text('Revision Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildTimelineItem(
              title: 'v1 Submitted',
              time: 'July 12, 2023 • 09:45 AM',
              isActive: false,
              isCompleted: true,
            ),
            _buildTimelineItem(
              title: 'Revision Requested',
              time: 'July 13, 2023 • 02:15 PM',
              description: '"Please warm up the lighting and shrink the main counter area."',
              isActive: false,
              isCompleted: true,
              isRevision: true,
            ),
            _buildTimelineItem(
              title: 'v2 Uploaded',
              time: 'July 14, 2023 • 11:30 AM',
              isActive: true,
              isCompleted: true,
              isLast: true,
            ),
            const SizedBox(height: 24),
            
            // Feedback Discussion
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Feedback\nDiscussion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2)),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                  icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.textPrimary),
                  label: const Text('View Full\nChat', style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.2)),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                 color: AppColors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.outlineVariant)
              ),
              child: Column(
                children: [
                  _buildChatBubble(
                    sender: 'TROP designer',
                    time: '2:30 PM',
                    avatarUrl: 'https://i.pravatar.cc/100?img=11',
                    message: 'The lighting layout looks great, but could we add more accent lighting near the zen garden viewing area? It seems a bit dark in the 3D perspective.',
                    isMe: false,
                  ),
                  const SizedBox(height: 16),
                  _buildChatBubble(
                    sender: _loadingOwner ? '... (shop owner)' : _ownerLabel,
                    time: '3:15 PM',
                    avatarUrl: 'https://i.pravatar.cc/100?img=68',
                    message: 'Absolutely, James. I\'ll update the lighting plan to include some discreet spotlights focusing on the garden elements. I\'ll have the updated version ready',
                    isMe: true,
                  ),
                  const SizedBox(height: 12),
                  // Chat Input Field Mockup
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Type a quick reply...', style: TextStyle(color: AppColors.placeholder, fontSize: 13)),
                        ),
                        Icon(Icons.send_rounded, size: 18, color: AppColors.placeholder),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Approve Version'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
               icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Request Another Revision'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.outlineVariant),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    String? description,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
    bool isRevision = false,
  }) {
    Color dotColor = Colors.green.shade600;
    if (isActive) dotColor = Colors.green.shade600;
    if (isRevision) dotColor = Colors.red.shade600;
    if (!isCompleted && !isActive) dotColor = Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: description != null ? 70 : 40,
                color: AppColors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
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
            radius: 12,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Text(sender, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 10, color: AppColors.placeholder)),
                   ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primaryContainer : AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                    bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? AppColors.white : AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(avatarUrl),
          ),
        ]
      ],
    );
  }
}
