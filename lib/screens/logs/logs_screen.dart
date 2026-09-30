import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/logs_provider.dart';
import '../../models/app_log.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  Color _getLogTypeColor(LogType type) {
    switch (type) {
      case LogType.sms:
        return const Color(0xFF00A2E8);
      case LogType.api:
        return AppTheme.primaryBlue;
      case LogType.verification:
        return AppTheme.verifiedGreen;
      case LogType.error:
        return AppTheme.unmatchedRed;
      case LogType.warning:
        return AppTheme.pendingOrange;
      case LogType.info:
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getLogTypeIcon(LogType type) {
    switch (type) {
      case LogType.sms:
        return Icons.sms;
      case LogType.api:
        return Icons.cloud_sync;
      case LogType.verification:
        return Icons.check_circle;
      case LogType.error:
        return Icons.error;
      case LogType.warning:
        return Icons.warning;
      case LogType.info:
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsProv = Provider.of<LogsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          if (logsProv.logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await logsProv.clearLogs();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs cleared')),
                  );
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: logsProv.logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No system logs recorded yet',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logsProv.logs.length,
                itemBuilder: (context, index) {
                  final log = logsProv.logs[index];
                  final color = _getLogTypeColor(log.type);
                  final timeFormatted = DateFormat('MMM dd, hh:mm:ss a').format(log.timestamp);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getLogTypeIcon(log.type), color: color, size: 20),
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
                                    log.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (log.details != null && log.details!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.details!,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
