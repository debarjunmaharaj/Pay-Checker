import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'connect_website_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Widget _buildFeatureChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  Image.asset(
                    'assets/icon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pay Checker',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatic Payment Verification\nfor Your Business',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureChip(Icons.flash_on, 'Fast'),
                  _buildFeatureChip(Icons.security, 'Secure'),
                  _buildFeatureChip(Icons.verified, 'Reliable'),
                  _buildFeatureChip(Icons.star, 'Easy to Use'),
                ],
              ),
              Column(
                children: [
                  CustomButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConnectWebsiteScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Smarter Payments, Happier Business',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
