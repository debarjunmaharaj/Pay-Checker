import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/payment_transaction.dart';
import 'status_pill.dart';

class PaymentCard extends StatelessWidget {
  final PaymentTransaction payment;
  final VoidCallback onTap;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
  });

  IconData _getProviderIcon(String provider) {
    final p = provider.toLowerCase();
    if (p == 'bkash') return Icons.account_balance_wallet;
    if (p == 'nagad') return Icons.mobile_friendly;
    if (p == 'rocket') return Icons.flash_on;
    if (p == 'upay') return Icons.send_to_mobile;
    return Icons.payment;
  }

  Color _getProviderColor(String provider) {
    final p = provider.toLowerCase();
    if (p == 'bkash') return const Color((0xFFE2136E));
    if (p == 'nagad') return const Color(0xFFF7921E);
    if (p == 'rocket') return const Color(0xFF8C3494);
    if (p == 'upay') return const Color(0xFF00A2E8);
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('MMM dd, hh:mm a').format(payment.receivedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getProviderColor(payment.provider).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getProviderIcon(payment.provider),
                color: _getProviderColor(payment.provider),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.provider.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '৳${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.sender.isNotEmpty ? payment.sender : 'Sender: Unknown',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      StatusPill(status: payment.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TrxID: ${payment.trxId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (payment.orderId != null && payment.orderId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order #${payment.orderId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
