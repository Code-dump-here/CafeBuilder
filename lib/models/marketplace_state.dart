import 'package:flutter/material.dart';

class BroadcastProject {
  final String id;
  final String title;
  final String location;
  final String style;
  final String budgetTier;
  final String description;
  final List<String> requirements;
  final String date;
  final int proposalsCount;
  final int commentsCount;
  final String status; // 'Open for Proposals', 'Reviewing', 'Urgent'
  final String imageUrl;

  BroadcastProject({
    required this.id,
    required this.title,
    required this.location,
    required this.style,
    required this.budgetTier,
    required this.description,
    required this.requirements,
    required this.date,
    required this.proposalsCount,
    required this.commentsCount,
    required this.status,
    required this.imageUrl,
  });
}

class MarketplaceState {
  static final List<BroadcastProject> broadcasts = [
    BroadcastProject(
      id: 'AT-612-Kyoto',
      title: 'Artisanal Hearth Studio',
      location: 'Kyoto, Japan',
      style: 'Modern Minimal',
      budgetTier: '\$80k - \$120k',
      description: 'Seeking a minimalist architectural design for a 120sqm specialty coffee shop with traditional hearth accents.',
      requirements: ['Interior Design', 'MEP Engineering'],
      date: 'Oct 2024',
      proposalsCount: 8,
      commentsCount: 12,
      status: 'Open for Proposals',
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
    ),
    BroadcastProject(
      id: 'AT-817-Berlin',
      title: 'The Obsidian Roastery',
      location: 'Berlin, Germany',
      style: 'Industrial',
      budgetTier: '\$150k - \$220k',
      description: 'Redesign of an old industrial warehouse into a premium roastery and tasting hall. Heavy focus on exposed steel frames.',
      requirements: ['Construction & Build', 'MEP Engineering', 'Branding & Identity'],
      date: 'Nov 2024',
      proposalsCount: 24,
      commentsCount: 5,
      status: 'Reviewing',
      imageUrl: 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&q=80&w=600',
    ),
    BroadcastProject(
      id: 'AT-541-Oslo',
      title: 'Nordic Bloom Cafe',
      location: 'Oslo, Norway',
      style: 'Japandi',
      budgetTier: '\$50k - \$80k',
      description: 'Small pop-up concept requiring innovative modular furniture and high energy efficiency ventilation systems.',
      requirements: ['Interior Design', 'Branding & Identity'],
      date: 'Sep 2024',
      proposalsCount: 3,
      commentsCount: 2,
      status: 'Urgent',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=600',
    ),
  ];

  static bool isServiceProvider = false;
  static BroadcastProject? activeProject;
  static int initialIndex = 0;
  static VoidCallback? onRoleChanged;

  static void toggleRole() {
    isServiceProvider = !isServiceProvider;
    initialIndex = isServiceProvider ? 2 : 0; // If switching to provider, default to Marketplace tab
    if (onRoleChanged != null) {
      onRoleChanged!();
    }
  }
}
