import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DesignPackagesPage extends StatelessWidget {
  const DesignPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Design Cafe',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.espresso),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image at the top
          Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 80),
            children: [
              _buildPackageCard(
                title: 'BẢN VẼ SƠ ĐỒ KĨ THUẬT',
                designerName: 'TROP Studio',
                designerRole: 'Lead Architecture Firm',
                contentCount: '6 Files included',
                timeline: 'Uploaded 2 hours ago',
                designerAvatar: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=150', // Drawing/architect photo
              ),
              const SizedBox(height: 24),
              _buildPackageCard(
                title: 'Industrial Coffee\nShop Renovation',
                titleIsSerif: true,
                designerName: 'TROP Studio',
                designerRole: 'Lead Architecture Firm',
                contentCount: '6 Files included',
                timeline: 'Uploaded 2 hours ago',
                designerAvatar: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=150',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    bool titleIsSerif = false,
    required String designerName,
    required String designerRole,
    required String contentCount,
    required String timeline,
    required String designerAvatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleIsSerif ? title : title.toUpperCase(),
            style: titleIsSerif 
              ? GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso, height: 1.2)
              : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.espresso),
          ),
          const SizedBox(height: 24),
          _buildLabel('DESIGNER'),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  designerAvatar,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(designerName, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(height: 4),
                  Text(designerRole, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('CONTENT'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: AppColors.espresso),
              const SizedBox(width: 8),
              Text(contentCount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('TIMELINE'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 16, color: AppColors.espresso),
              const SizedBox(width: 8),
              Text(timeline, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('OPEN PACKAGE & REVIEW', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.espresso),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_outlined, size: 16, color: AppColors.espresso),
                  const SizedBox(width: 12),
                  Text('QUICK DOWNLOAD\n(ZIP)', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.espresso, height: 1.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: AppColors.placeholder,
      ),
    );
  }
}
