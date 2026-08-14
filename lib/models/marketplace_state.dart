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
  static final List<BroadcastProject> broadcasts = [];

  static bool isServiceProvider = false;
  static BroadcastProject? activeProject;
  static int initialIndex = 0;
  static VoidCallback? onRoleChanged;

  /// Called whenever a new broadcast is inserted into [broadcasts].
  /// MarketplacePage subscribes to this to trigger a rebuild.
  static VoidCallback? onBroadcastsChanged;

  /// Called when a screen wants Home's dashboard refreshed the next time
  /// it's back on screen — e.g. after popping back to it following a
  /// project creation deep in the navigation stack, where a plain
  /// `Navigator.pop`/`popUntil` doesn't run any of Home's own refresh
  /// logic on its own. HomePage subscribes to this the same way it
  /// subscribes to [onRoleChanged].
  static VoidCallback? onNeedsRefresh;

  static void toggleRole() {
    isServiceProvider = !isServiceProvider;
    initialIndex = isServiceProvider ? 2 : 0; // If switching to provider, default to Marketplace tab
    if (onRoleChanged != null) {
      onRoleChanged!();
    }
  }

  /// Insert a new project and notify listeners.
  static void addBroadcast(BroadcastProject project) {
    broadcasts.insert(0, project);
    if (onBroadcastsChanged != null) {
      onBroadcastsChanged!();
    }
  }
}
