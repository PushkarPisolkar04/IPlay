import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 96, color: AppDesignSystem.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesignSystem.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: AppDesignSystem.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.primaryIndigo,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Predefined empty states
class EmptyClassrooms extends StatelessWidget {
  final VoidCallback? onCreate;
  const EmptyClassrooms({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.class_outlined,
      title: 'No Classrooms Yet',
      message: 'Create your first classroom to get started with teaching!',
      actionText: 'Create Classroom',
      onAction: onCreate,
    );
  }
}

class EmptyBadges extends StatelessWidget {
  const EmptyBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'No Badges Yet',
      message: 'Complete lessons and challenges to earn badges!',
    );
  }
}

class EmptyCertificates extends StatelessWidget {
  const EmptyCertificates({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.workspace_premium_outlined,
      title: 'No Certificates Yet',
      message: 'Complete all levels in a realm to earn a certificate!',
    );
  }
}

class EmptyAnnouncements extends StatelessWidget {
  const EmptyAnnouncements({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.announcement_outlined,
      title: 'No Announcements',
      message: 'There are no announcements at this time.',
    );
  }
}

class EmptyAssignments extends StatelessWidget {
  final VoidCallback? onCreate;
  const EmptyAssignments({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Assignments',
      message: 'Create an assignment to get started!',
      actionText: 'Create Assignment',
      onAction: onCreate,
    );
  }
}

