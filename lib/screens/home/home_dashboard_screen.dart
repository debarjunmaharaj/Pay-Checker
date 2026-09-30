import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/overview_card.dart';
import '../../widgets/payment_card.dart';
import '../payments/payment_details_dialog.dart';
import '../settings/settings_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  Widget _buildMethodItem(String name, Color color, bool isListening) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isListening ? AppTheme.verifiedGreenBg : AppTheme.unmatchedRedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isListening ? 'Listening' : 'Off',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isListening ? AppTheme.verifiedGreen : AppTheme.unmatchedRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final paymentsProv = Provider.of<PaymentsProvider>(context);

    final siteName = auth.websiteConfig?.siteName ?? 'Netfie Mart';
    final domain = auth.websiteConfig?.domain ?? 'netfiemart.com';
    final deviceId = auth.deviceDetails?.deviceId ?? 'NF-ANDROID';

    final recentList = paymentsProv.allPayments.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (auth.websiteConfig != null && auth.deviceDetails != null) {
              await paymentsProv.syncWithServer(
                apiEndpoint: auth.websiteConfig!.apiEndpoint,
                deviceId: auth.deviceDetails!.deviceId,
                deviceToken: auth.deviceDetails!.token,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConnectionBanner(
                  isConnected: auth.isConnected,
                  siteName: siteName,
                  domain: domain,
                  deviceId: deviceId,
                  onTest: () async {
                    final res = await auth.testConnection();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res ? 'Connection active!' : 'Connection error!'),
                          backgroundColor: res ? AppTheme.verifiedGreen : AppTheme.unmatchedRed,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    if (settings.smsPermissionGranted && settings.isIgnoringBatteryOpt) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soft Setup Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Enable SMS permission & battery settings in Settings when ready.',
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(60, 30),
                              elevation: 0,
                            ),
                            child: const Text('Setup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    final isListening = settings.smsPermissionGranted;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMethodItem('bKash', const Color(0xFFE2136E), isListening),
                          const SizedBox(width: 8),
                          _buildMethodItem('Nagad', const Color(0xFFF7921E), isListening),
                          const SizedBox(width: 8),
                          _buildMethodItem('Rocket', const Color(0xFF8C3494), isListening),
                          const SizedBox(width: 8),
                          _buildMethodItem('Upay', const Color(0xFF00A2E8), isListening),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OverviewCard(
                  total: paymentsProv.totalCount,
                  verified: paymentsProv.verifiedCount,
                  pending: paymentsProv.pendingCount,
                  unmatched: paymentsProv.unmatchedCount,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Payments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${paymentsProv.allPayments.length} Total',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recentList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No payment SMS received yet',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When a customer pays via bKash, Nagad or Rocket, it will automatically appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentList.length,
                    itemBuilder: (context, index) {
                      final p = recentList[index];
                      return PaymentCard(
                        payment: p,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => PaymentDetailsDialog(payment: p),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
