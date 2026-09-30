import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/payment_transaction.dart';

class StatusPill extends StatelessWidget {
  final PaymentStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case PaymentStatus.verified:
      case PaymentStatus.completed:
        bg = AppTheme.verifiedGreenBg;
        text = AppTheme.verifiedGreen;
        label = 'Verified';
        break;
      case PaymentStatus.waiting:
      case PaymentStatus.received:
      case PaymentStatus.matching:
        bg = AppTheme.pendingOrangeBg;
        text = AppTheme.pendingOrange;
        label = 'Pending';
        break;
      case PaymentStatus.unmatched:
      case PaymentStatus.rejected:
      case PaymentStatus.duplicate:
      case PaymentStatus.failed:
      case PaymentStatus.expired:
      default:
        bg = AppTheme.unmatchedRedBg;
        text = AppTheme.unmatchedRed;
        label = 'Unmatched';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
