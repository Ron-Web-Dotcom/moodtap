import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Terms of Service screen displaying comprehensive legal terms
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service'), elevation: 0),
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
              'Agreement to Terms',
              'By accessing or using MoodTap ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.',
            ),
            _buildSection(
              context,
              'Description of Service',
              'MoodTap is a personal mood tracking application that allows you to:\n\n'
                  '• Log your daily mood on a 1-5 scale\n'
                  '• View mood history and trends\n'
                  '• Receive daily reminders to log your mood\n'
                  '• Export your mood data\n'
                  '• Sync data across devices (optional)\n\n'
                  'The App is provided "as is" for personal, non-commercial use only.',
            ),
            _buildSection(
              context,
              'User Responsibilities',
              'You agree to:\n\n'
                  '• Use the App only for lawful purposes\n'
                  '• Not attempt to reverse engineer or hack the App\n'
                  '• Not use the App to harm others or violate their rights\n'
                  '• Keep your device secure and protect your data\n'
                  '• Not share or distribute the App without authorization\n'
                  '• Comply with all applicable laws and regulations',
            ),
            _buildSection(
              context,
              'Intellectual Property',
              'All content, features, and functionality of MoodTap are owned by us and are protected by international copyright, trademark, and other intellectual property laws.\n\n'
                  'You may not:\n'
                  '• Copy, modify, or distribute the App\n'
                  '• Remove any copyright or proprietary notices\n'
                  '• Use our trademarks without permission\n'
                  '• Create derivative works based on the App',
            ),
            _buildSection(
              context,
              'User Data and Privacy',
              'Your use of the App is also governed by our Privacy Policy. By using the App, you consent to our collection and use of your data as described in the Privacy Policy.\n\n'
                  'You retain all rights to your mood data. We do not claim ownership of any data you create using the App.',
            ),
            _buildSection(
              context,
              'Disclaimer of Warranties',
              'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT:\n\n'
                  '• The App will be uninterrupted or error-free\n'
                  '• Defects will be corrected\n'
                  '• The App is free of viruses or harmful components\n'
                  '• Results from using the App will be accurate or reliable\n\n'
                  'MOODTAP IS NOT A MEDICAL DEVICE OR MENTAL HEALTH TREATMENT. IT IS FOR PERSONAL TRACKING ONLY.',
            ),
            _buildSection(
              context,
              'Medical Disclaimer',
              'IMPORTANT: MoodTap is NOT a substitute for professional medical advice, diagnosis, or treatment.\n\n'
                  '• Always seek the advice of qualified health providers\n'
                  '• Never disregard professional medical advice because of the App\n'
                  '• If you are experiencing a mental health crisis, contact emergency services immediately\n'
                  '• The App does not provide medical diagnoses or treatment recommendations',
            ),
            _buildSection(
              context,
              'Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:\n\n'
                  '• Any indirect, incidental, special, or consequential damages\n'
                  '• Loss of data, profits, or business opportunities\n'
                  '• Personal injury or property damage\n'
                  '• Any damages arising from your use of the App\n\n'
                  'Our total liability shall not exceed the amount you paid for the App (if any).',
            ),
            _buildSection(
              context,
              'Indemnification',
              'You agree to indemnify and hold us harmless from any claims, damages, losses, or expenses (including legal fees) arising from:\n\n'
                  '• Your use of the App\n'
                  '• Your violation of these Terms\n'
                  '• Your violation of any rights of others\n'
                  '• Any content you submit through the App',
            ),
            _buildSection(
              context,
              'Termination',
              'We reserve the right to terminate or suspend your access to the App at any time, without notice, for any reason, including violation of these Terms.\n\n'
                  'Upon termination:\n'
                  '• Your right to use the App immediately ceases\n'
                  '• You must delete the App from your device\n'
                  '• We may delete your data from our servers',
            ),
            _buildSection(
              context,
              'Changes to Terms',
              'We may modify these Terms at any time. Changes will be effective immediately upon posting. Your continued use of the App after changes constitutes acceptance of the modified Terms.\n\n'
                  'We will update the "Last Updated" date at the top of these Terms when changes are made.',
            ),
            _buildSection(
              context,
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate, without regard to conflict of law principles.\n\n'
                  'Any disputes shall be resolved in the courts of that jurisdiction.',
            ),
            _buildSection(
              context,
              'Severability',
              'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.',
            ),
            _buildSection(
              context,
              'Entire Agreement',
              'These Terms, together with our Privacy Policy, constitute the entire agreement between you and us regarding the use of the App and supersede all prior agreements and understandings.',
            ),
            _buildSection(
              context,
              'Contact Information',
              'If you have questions about these Terms, please contact us at:\n\n'
                  'Email: legal@moodtap.app\n'
                  'Website: https://moodtap.app/terms\n\n'
                  'We will respond to all inquiries within 30 days.',
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
