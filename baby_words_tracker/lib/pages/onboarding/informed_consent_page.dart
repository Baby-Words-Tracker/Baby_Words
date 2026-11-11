import 'dart:async';

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:provider/provider.dart';

/*
Requirements for this page:

- send docusign to provided email
- keep tabs of whether or not info can be stored and used in firebase
- determine whether an action has happened within the email 
  - or make a "honor system" button 

considerations: 
- what if the email bounces?
- resending possibilities (answers to this in the flutter_email_sender library docs)
*/ 

class InformedConsentPage extends StatefulWidget {
  static const routeName = '/onboarding/informed-consent';
  
  const InformedConsentPage({super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  // what variables do we need? idk
  bool _isResending = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Send initial verification email
    _sendInformedConsentEmail(isInitial: true);
  }

  Future<void> _sendInformedConsentEmail({bool isInitial = false}) async {
    final capabilities = await FlutterEmailSender.getCapabilities();

    if (!capabilities.canSend) {
      // No configured mail account, simulator, or no available mail client.
      // need some kind of error message
    }
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final Email email = Email(
        body: 'Email body',
        subject: 'Email subject',
        recipients: ['${user.email}'],
        );

        //send email
        final result = await FlutterEmailSender.send(email);

        switch (result) {
          case EmailSendResult.sent:
          case EmailSendResult.saved:
          case EmailSendResult.cancelled:
            // iOS reports how the user left the composer.
            break;
          case EmailSendResult.unknown:
            // Other platforms do not report the outcome.
            break;
        }
      }
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';
    
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
                  'Fill Out The Form',
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
                  email,
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

                // THIS IS WHERE WE NEED TO DECIDE TO HONORS SYSTEM IT
                /*FilledButton.icon(
                 
                ),
                */
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: 
                    _isResending ? null : () => _sendInformedConsentEmail(),
                  icon: _isResending
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
                    label: Text(_isResending ? 'Sending...' : 'Resend Email'),
                ),

              const SizedBox(height: 16),

              //Help Text
              Text(
                'Didn\'t get an email? Check your spam folder or tap Resend Email, then use the newest email only.',
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