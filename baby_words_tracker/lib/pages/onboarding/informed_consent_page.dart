import 'dart:async';

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:provider/provider.dart';

//await context.read<AuthenticationService>().signOut();

class InformedConsentPage extends StatefulWidget {
  static const routeName = '/onboarding/informed-consent';
  
  const InformedConsentPage({super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  final capabilities = FlutterEmailSender.getCapabilities();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Send initial verification email
    _sendInformedConsentEmail();
  }

  Future<void> _sendInformedConsentEmail() async {

    if (user != null) {
      final Email email = Email(
      body: 'Hello and Welcome to WordBuds!\nWordBuds is an IRB Certified Research Project hosted by the Literacy Education and Cognitive Science (LECS) lab. Please take the time to fill out the following informed consent form before using the app \n\nhttps://demo.docusign.net/Member/PowerFormSigning.aspx?PowerFormId=8e2e12d9-565e-42f9-ba5a-b8119aafe0d6&env=demo&acct=9cc9cbff-6e45-46a2-b9f7-4a598b1a8cb1&v=2',
      subject: 'WordBuds Informed Consent Form',
      recipients: ['${user!.email}'],
      );

      try {
        await FlutterEmailSender.send(email);
      } on FlutterEmailSenderNotAvailableException {
        debugPrint('Error: FlutterEmailSenderNotAvailableException');
      } on FlutterEmailSenderUnsupportedFeatureException catch (error) {
        debugPrint('Unsupported: ${error.unsupportedFeatures}');
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informed Consent',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Sign In',
          onPressed: () async {
            final authService = context.read<AuthenticationService>();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Return to Sign In'),
                content: const Text(
                  'Signing out will take you back to the sign-in screen so you can fix your email or start over.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (confirmed == true && mounted) {
              await authService.signOut();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthenticationService>().signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Theme.of(context). colorScheme.primary,
                ),
                const SizedBox(height:32),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                     children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: 
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const  SizedBox(width: 12),
                      Expanded(child: Text(
                        'Please fill out the form to make an account!',
                        style: Theme.of(context)
                          .textTheme
                          .bodyMedium?.copyWith(
                            color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          ),
                      ),)
                    ],),
                  ),
                ),
                const SizedBox(height: 24),

                //Title
                Text(
                  'Click the Button Below to Send your Informed Consent Form',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                //Instructions
                Text(
                  'We\'ve sent a DocuSign Link to email:',
                  style:Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                //Email address
                Text(
                  email!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                //Steps Card - 318
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Steps:',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _buildStep('1', 'Check your email inbox'),
                        const SizedBox(height: 12),
                        _buildStep('2', 'Fill out the linked form'),
                        const SizedBox(height: 12),
                        _buildStep('3', 'Return to this app'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                OutlinedButton.icon(
                  onPressed: () => _sendInformedConsentEmail(),
                  icon:
                    const Icon(Icons.refresh),
                    label: Text('Send Email'),
                ),
              const SizedBox(height: 16),

              //Help Text
              Text(
                'Didn\'t get an email? Check your spam folder or tap Send Email again. Resending an email does not invalidate the original.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              ],
            )
          ),
        ),
      ),
    );
  }
 
  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}