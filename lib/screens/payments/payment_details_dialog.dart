import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/payment_transaction.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/custom_button.dart';

class PaymentDetailsDialog extends StatelessWidget {
  final PaymentTransaction payment;

  const PaymentDetailsDialog({super.key, required this.payment});

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              if (isCopyable && context != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied $value to clipboard')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 16, color: AppTheme.primaryBlue),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receivedFormatted = DateFormat('MMM dd, yyyy hh:mm a').format(payment.receivedAt);
    final processedFormatted = payment.processedAt != null
        ? DateFormat('MMM dd, yyyy hh:mm a').format(payment.processedAt!)
        : 'Pending';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(status: payment.status),
              const SizedBox(height: 12),
              Text(
                '৳${payment.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                payment.provider.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderLight),
              _buildDetailRow('Order Number', payment.orderId != null && payment.orderId!.isNotEmpty ? '#${payment.orderId}' : 'N/A'),
              _buildDetailRow('Transaction ID (TrxID)', payment.trxId, isCopyable: true, context: context),
              _buildDetailRow('Sender Number', payment.sender.isNotEmpty ? payment.sender : 'Unknown', isCopyable: true, context: context),
              _buildDetailRow('Received At', receivedFormatted),
              _buildDetailRow('Processed At', processedFormatted),
              const Divider(color: AppTheme.borderLight),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Raw SMS Body:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      payment.rawSms,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
