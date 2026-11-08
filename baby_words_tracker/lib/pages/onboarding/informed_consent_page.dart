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
  
  final Email email = Email(
    body: 'Hello and Welcome to WordBuds! \n WordBuds is an IRB Certified Research Project hosted by the Literacy Education and Cognitive Science (LECS) lab. Please take the time to fill out the following informed consent form. \n /link goes here/',
    subject: 'Email subject',
    recipients: ['example@example.com'],
  );

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

      )
      //put the main page in heref
    );
  }

}