import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Privacy Policy screen displaying comprehensive privacy information
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: February 15, 2026',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 3.h),
            _buildSection(
              context,
              'Introduction',
              'MoodTap ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            _buildSection(
              context,
              'Information We Collect',
              'We collect the following types of information:\n\n'
                  '• Mood Data: Your daily mood ratings (1-5 scale) and timestamps\n'
                  '• Device Information: A unique device identifier generated locally\n'
                  '• Usage Data: App interaction patterns and feature usage\n\n'
                  'We do NOT collect:\n'
                  '• Personal identification information (name, email, phone)\n'
                  '• Location data\n'
                  '• Contact information\n'
                  '• Photos or media files',
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              'Your mood data is used exclusively for:\n\n'
                  '• Displaying your personal mood history and trends\n'
                  '• Generating weekly and monthly mood charts\n'
                  '• Providing personalized insights into your emotional patterns\n'
                  '• Syncing your data across your devices (optional)\n\n'
                  'We do NOT:\n'
                  '• Sell your data to third parties\n'
                  '• Use your data for advertising\n'
                  '• Share your data with other users\n'
                  '• Analyze your data for commercial purposes',
            ),
            _buildSection(
              context,
              'Data Storage and Security',
              'Your mood data is stored in two locations:\n\n'
                  '1. Local Storage: Encrypted on your device using SharedPreferences\n'
                  '2. Cloud Backup: Securely stored on Supabase servers with end-to-end encryption\n\n'
                  'Security Measures:\n'
                  '• All data transmission uses HTTPS encryption\n'
                  '• Database access is restricted with Row Level Security (RLS)\n'
                  '• Your device ID is cryptographically generated and cannot be traced to you\n'
                  '• We implement industry-standard security practices',
            ),
            _buildSection(
              context,
              'Your Data Rights',
              'You have complete control over your data:\n\n'
                  '• Access: View all your mood data anytime in the app\n'
                  '• Export: Download your complete mood history as CSV\n'
                  '• Delete: Permanently delete all your data from our servers\n'
                  '• Portability: Export and transfer your data to other services\n\n'
                  'To exercise these rights, use the Settings screen in the app.',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              'We use the following third-party services:\n\n'
                  '• Supabase: Cloud database and authentication (https://supabase.com)\n'
                  '• OpenAI: AI-powered motivational messages (optional feature)\n'
                  '• Google Gemini: Alternative AI provider (optional feature)\n\n'
                  'These services have their own privacy policies and security measures. We recommend reviewing their policies.',
            ),
            _buildSection(
              context,
              'Data Retention',
              'We retain your mood data for as long as you use the app. You can delete all your data at any time through the Settings screen. After deletion:\n\n'
                  '• Data is immediately removed from our servers\n'
                  '• Backups are purged within 30 days\n'
                  '• Local device data is cleared immediately',
            ),
            _buildSection(
              context,
              'Children\'s Privacy',
              'MoodTap is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
            ),
            _buildSection(
              context,
              'International Users',
              'Your data may be transferred to and stored on servers located outside your country. By using MoodTap, you consent to the transfer of your information to countries that may have different data protection laws.',
            ),
            _buildSection(
              context,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              context,
              'Contact Us',
              'If you have questions about this Privacy Policy or your data, please contact us at:\n\n'
                  'Email: privacy@moodtap.app\n'
                  'Website: https://moodtap.app/privacy\n\n'
                  'We will respond to all requests within 30 days.',
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                '© 2026 MoodTap. All rights reserved.',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
