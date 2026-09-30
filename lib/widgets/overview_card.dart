import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class OverviewCard extends StatelessWidget {
  final int total;
  final int verified;
  final int pending;
  final int unmatched;

  const OverviewCard({
    super.key,
    required this.total,
    required this.verified,
    required this.pending,
    required this.unmatched,
  });

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Payments', total.toString(), AppTheme.textPrimary),
              Container(width: 1, height: 28, color: AppTheme.borderLight),
              _buildStatItem('Verified', verified.toString(), AppTheme.verifiedGreen),
              Container(width: 1, height: 28, color: AppTheme.borderLight),
              _buildStatItem('Pending', pending.toString(), AppTheme.pendingOrange),
              Container(width: 1, height: 28, color: AppTheme.borderLight),
              _buildStatItem('Unmatched', unmatched.toString(), AppTheme.unmatchedRed),
            ],
          ),
        ],
      ),
    );
  }
}
