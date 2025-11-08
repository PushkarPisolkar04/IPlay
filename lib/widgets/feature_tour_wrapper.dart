import 'package:flutter/material.dart';
import '../services/app_tour_service.dart';
import 'app_tour_tooltip.dart';

/// Wrapper widget that shows a tour tooltip for new features
class FeatureTourWrapper extends StatefulWidget {
  final String featureId;
  final String tooltipMessage;
  final Widget child;

  const FeatureTourWrapper({
    super.key,
    required this.featureId,
    required this.tooltipMessage,
    required this.child,
  });

  @override
  State<FeatureTourWrapper> createState() => _FeatureTourWrapperState();
}

class _FeatureTourWrapperState extends State<FeatureTourWrapper> {
  final _appTourService = AppTourService();
  bool _showTour = false;

  @override
  void initState() {
    super.initState();
    _checkTourStatus();
  }

  Future<void> _checkTourStatus() async {
    final completed = await _appTourService.isFeatureTourCompleted(widget.featureId);
    if (mounted) {
      setState(() {
        _showTour = !completed;
      });
    }
  }

  Future<void> _dismissTour() async {
    await _appTourService.markFeatureTourCompleted(widget.featureId);
    if (mounted) {
      setState(() {
        _showTour = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTourTooltip(
      message: widget.tooltipMessage,
      show: _showTour,
      onDismiss: _dismissTour,
      child: widget.child,
    );
  }
}
