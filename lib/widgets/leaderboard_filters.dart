import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

class LeaderboardFilters extends StatelessWidget {
  final String scope;
  final String type;
  final String period;
  final Function(String) onScopeChanged;
  final Function(String) onTypeChanged;
  final Function(String) onPeriodChanged;

  const LeaderboardFilters({
    super.key,
    required this.scope,
    required this.type,
    required this.period,
    required this.onScopeChanged,
    required this.onTypeChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterRow('Scope', scope, ['National', 'State', 'School', 'Classroom'], onScopeChanged),
        const SizedBox(height: 8),
        _buildFilterRow('Type', type, ['All', 'Solo'], onTypeChanged),
        const SizedBox(height: 8),
        _buildFilterRow('Period', period, ['Week', 'Month', 'All Time'], onPeriodChanged),
      ],
    );
  }

  Widget _buildFilterRow(String label, String selected, List<String> options, Function(String) onChanged) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = selected.toLowerCase() == option.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (_) => onChanged(option.toLowerCase()),
                    selectedColor: AppDesignSystem.primaryIndigo,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppDesignSystem.textPrimary),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

