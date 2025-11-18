import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// Loading skeleton widget for better UX
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppDesignSystem.backgroundGrey,
                AppDesignSystem.backgroundLight,
                AppDesignSystem.backgroundGrey,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Card skeleton for list items
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          LoadingSkeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                LoadingSkeleton(
                  width: 150,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List skeleton with multiple cards
class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => const CardSkeleton(),
    );
  }
}

/// Grid skeleton for grid layouts
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: LoadingSkeleton(
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                const SizedBox(height: 6),
                LoadingSkeleton(
                  width: 70,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                LoadingSkeleton(
                  width: 50,
                  height: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Profile skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LoadingSkeleton(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(50),
          ),
          const SizedBox(height: 16),
          LoadingSkeleton(
            width: 150,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          LoadingSkeleton(
            width: 100,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatSkeleton(),
              _buildStatSkeleton(),
              _buildStatSkeleton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        LoadingSkeleton(
          width: 60,
          height: 32,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        LoadingSkeleton(
          width: 50,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Dashboard skeleton for teacher/principal dashboards
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Section title
          LoadingSkeleton(
            width: 150,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Cards
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingSkeleton(
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classroom detail skeleton
class ClassroomDetailSkeleton extends StatelessWidget {
  const ClassroomDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          LoadingSkeleton(
            height: 120,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 80,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 80,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Section title
          LoadingSkeleton(
            width: 120,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Student list
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Realm/Level list skeleton
class RealmListSkeleton extends StatelessWidget {
  const RealmListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
            width: 150,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingSkeleton(
                height: 120,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings skeleton
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section
          Center(
            child: Column(
              children: [
                LoadingSkeleton(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(40),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  width: 120,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                LoadingSkeleton(
                  width: 80,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Settings sections
          ...List.generate(
            4,
            (index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: 100,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LoadingSkeleton(
                      height: 50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Analytics skeleton
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 90,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 90,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LoadingSkeleton(
                  height: 90,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingSkeleton(
                  height: 90,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart section
          LoadingSkeleton(
            width: 150,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          LoadingSkeleton(
            height: 200,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 24),
          // List section
          LoadingSkeleton(
            width: 120,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}
