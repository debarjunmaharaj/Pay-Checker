import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/domain_normalizer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_layout.dart';

class ConnectWebsiteScreen extends StatefulWidget {
  const ConnectWebsiteScreen({super.key});

  @override
  State<ConnectWebsiteScreen> createState() => _ConnectWebsiteScreenState();
}

class _ConnectWebsiteScreenState extends State<ConnectWebsiteScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController(text: 'Android-Phone');
  String _previewNormalized = '';

  @override
  void initState() {
    super.initState() ;
    _urlController.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {
      _previewNormalized = DomainNormalizer.normalizeUrl(_urlController.text);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your website URL')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.connectAndRegister(
      rawDomain: _urlController.text.trim(),
      deviceName: _deviceNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Connection failed. Check URL and plugin status.'),
          backgroundColor: AppTheme.unmatchedRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Your Website'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your website URL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your domain (e.g. netfiemart.com or https://netfiemart.com). We will automatically connect to Netfie Pay API.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _urlController,
                label: 'Website Domain / URL',
                hint: 'netfiemart.com',
                prefixIcon: Icons.link,
              ),
              if (_previewNormalized.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'API Path: $_previewNormalized',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              CustomTextField(
                controller: _deviceNameController,
                label: 'Device Name',
                hint: 'Merchant Phone',
                prefixIcon: Icons.smartphone,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Connect & Register',
                isLoading: authProvider.isLoading,
                onPressed: _handleConnect,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Don\'t have the plugin installed yet? Install Netfie Pay WooCommerce Plugin on your WordPress site.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
