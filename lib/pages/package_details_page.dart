import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PackageDetailsPage extends StatelessWidget {
  const PackageDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: const Icon(Icons.coffee, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Design Cafe',
              style: TextStyle(
                  color: AppColors.appName,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Projects > Japanese Coffee Shop Design',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'Japanese Coffee Shop\nDesign',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'by TROP Studio',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Text('6 total files', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatusChip('3 Approved', Colors.green.shade100, Colors.green.shade700),
                  const SizedBox(width: 8),
                  _buildStatusChip('2 Need Review', Colors.orange.shade100, Colors.orange.shade700),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusChip('1 Revision', Colors.red.shade100, Colors.red.shade700),
              
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(100, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Approve'),
              ),
              const SizedBox(height: 24),
              
              // Deliverable Cards
              _buildDeliverableCard(
                context,
                title: '3D Interior Perspective',
                subtitle: 'Comprehensive visual of the main\nservice area and lounge.',
                version: 'v2.4',
                status: 'NEED REVIEW',
                statusColor: Colors.orange.shade700,
                imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
                actionText: 'View',
                onAction: () => Navigator.pushNamed(context, '/element-details'),
              ),
              const SizedBox(height: 16),
              _buildDeliverableCard(
                context,
                title: 'Lighting Layout',
                subtitle: '',
                version: 'v1.1',
                status: '',
                statusColor: Colors.transparent,
                imageUrl: 'https://images.unsplash.com/photo-1531834685032-c34bf0d84c77?auto=format&fit=crop&q=80&w=600',
                actionText: 'View Details',
              ),
              const SizedBox(height: 16),
              _buildDeliverableCard(
                context,
                title: 'Furniture Layout',
                subtitle: 'Clarify clearance around the barista\nstation.',
                version: 'v3.0',
                status: 'REVISION REQUESTED',
                statusColor: Colors.red.shade700,
                imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=600',
                actionText: 'Revise',
              ),
              const SizedBox(height: 16),
              _buildDeliverableCard(
                context,
                title: 'Material Board',
                subtitle: 'Finalized selection of wood, paper, and\nmetal finishes.',
                version: 'v1.2',
                status: 'APPROVED',
                statusColor: Colors.green.shade700,
                imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&q=80&w=600',
                actionText: 'View',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Approve Package'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.outlineVariant,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverableCard(BuildContext context, {
    required String title,
    required String subtitle,
    required String version,
    required String status,
    required Color statusColor,
    required String imageUrl,
    required String actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(version, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              if (status.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status == 'APPROVED' || status == 'REVISION REQUESTED')
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onAction ?? () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
