import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).checkPermissions();
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, {IconData? icon, bool isCopyable = false, BuildContext? context}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              if (isCopyable && context != null) ...[
                const SizedBox(width: 8),
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

  Widget _buildPermissionTile({
    required String title,
    required String explanation,
    required IconData icon,
    required bool isGranted,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppTheme.borderLight : Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: isGranted ? AppTheme.primaryBlue : Colors.amber.shade800, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              isGranted
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.verifiedGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, size: 14, color: AppTheme.verifiedGreen),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(fontSize: 12, color: AppTheme.verifiedGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(60, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  void _showAutostartGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.memory, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Background Autostart Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Some phone manufacturers (Xiaomi, Vivo, Oppo, Samsung) aggressively kill background payment listeners. Enable Autostart:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text('• Xiaomi/MIUI: Settings → Apps → Permissions → Autostart → Enable Pay Checker.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 6),
            Text('• Samsung: Settings → Battery → Background usage limits → Never sleeping apps → Add Pay Checker.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 6),
            Text('• Vivo/Oppo: Settings → Battery → High background power consumption → Enable Pay Checker.', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final siteName = auth.websiteConfig?.siteName ?? 'Not Connected';
    final apiEndpoint = auth.websiteConfig?.apiEndpoint ?? 'N/A';
    final deviceId = auth.deviceDetails?.deviceId ?? 'N/A';
    final token = auth.deviceDetails?.token ?? '';
    final tokenMasked = token.length > 10 ? '${token.substring(0, 8)}...' : token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Permissions Status',
            onPressed: () => settings.checkPermissions(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Website Information'),
              _buildInfoTile('Connected Site', siteName, icon: Icons.language),
              _buildInfoTile('API Endpoint', apiEndpoint, icon: Icons.api, isCopyable: true, context: context),

              _buildSectionHeader('Device & Security'),
              _buildInfoTile('Device ID', deviceId, icon: Icons.smartphone, isCopyable: true, context: context),
              _buildInfoTile('Device Token', tokenMasked, icon: Icons.key, isCopyable: true, context: context),

              _buildSectionHeader('Permissions & Background Setup'),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Soft Permission Strategy: Grant permissions only when ready for payment detection. You can toggle them anytime below.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              _buildPermissionTile(
                title: 'SMS Permission',
                explanation: 'Allows Pay Checker to read incoming payment SMS from bKash, Nagad, Rocket, and Upay in real time.',
                icon: Icons.sms,
                isGranted: settings.smsPermissionGranted,
                actionLabel: 'Grant',
                onTap: () => settings.requestSmsPermission(),
              ),

              _buildPermissionTile(
                title: 'Push Notifications',
                explanation: 'Displays instant status alerts when payments are verified or require manual review.',
                icon: Icons.notifications_active,
                isGranted: settings.notificationPermissionGranted,
                actionLabel: 'Enable',
                onTap: () => settings.requestNotificationPermission(),
              ),

              _buildPermissionTile(
                title: 'Battery Optimization Whitelist',
                explanation: 'Disables system battery restrictions so payment detection runs smoothly when your phone is locked or idle.',
                icon: Icons.battery_saver,
                isGranted: settings.isIgnoringBatteryOpt,
                actionLabel: 'Configure',
                onTap: () => settings.requestBatteryOptimization(),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.memory, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Autostart & Background Guide', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Tips for Xiaomi, Vivo, Oppo & Samsung', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAutostartGuide(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(50, 32),
                      ),
                      child: const Text('View', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: 'Test Connection',
                isOutlined: true,
                icon: Icons.refresh,
                onPressed: () async {
                  final res = await auth.testConnection();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res ? 'Connection active!' : 'Connection check failed.'),
                        backgroundColor: res ? AppTheme.verifiedGreen : AppTheme.unmatchedRed,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Disconnect Website',
                color: AppTheme.unmatchedRed,
                icon: Icons.logout,
                onPressed: () async {
                  await auth.disconnect();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
