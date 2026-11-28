import 'dart:async';
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/util/policies_and_consent/consent_form_information.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

//await context.read<AuthenticationService>().signOut();

///Informed Consent form in Onboarding Flow
class InformedConsentPage extends StatefulWidget {
  static const routeName = '/onboarding/informed-consent';
  
  const InformedConsentPage({super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _hasReadForm = false;
  bool _completedConsentForm = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openConsentForm() async {
    final url = Uri.parse(ConsentFormInformation.consentFormUrl);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open consent form link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('InformedConsentPage: Error opening URL: $e');
    }
  }

  Future<void> _completeConsentForm() async {  
    if (!_hasReadForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you have read and signed the consent form'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
      setState(() {
        _completedConsentForm = true;
      });

      try {

        final userModelService = context.read<UserProfileModelService>();
        await userModelService.acceptConsentForm();

        debugPrint('InformedConsentPage: Consent Form Completed');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consent Form Completed'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // AuthGate will automatically navigate to next step
      } catch (e) {
        debugPrint('InformedConsentPage: Error completing form: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing form: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _completedConsentForm = false;
          });
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    
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
                  'Signing out will take you back to the sign-in screen. You\'ll need to restart onboarding if you come back later.',
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
                  Icons.checklist,
                  size: 100,
                  color: Theme.of(context). colorScheme.primary,
                ),
                const SizedBox(height:24),
                //Title
                Text(
                  'Informed Consent Collection',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                //Instructions
                Text(
                  'As this is an IRB-certified research project, we ask that you please read and sign the consent form found by clicking the button below',
                  style:Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                 OutlinedButton.icon(
                  onPressed: () => _openConsentForm(),
                  icon:
                    const Icon(Icons.open_in_browser),
                    label: Text('View Form'),
                ),
              const SizedBox(height: 16),

              // Checkbox to confirm reading
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: CheckboxListTile(
                  value: _hasReadForm,
                  onChanged: (value) {
                    setState(() {
                      _hasReadForm = value ?? false;
                    });
                  },
                  title: const Text(
                    'I certify that I have read and signed the consent form',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 24),

               FilledButton.icon(
                  onPressed: (_completedConsentForm || !_hasReadForm)
                      ? null
                      : _completeConsentForm,
                  icon: _completedConsentForm
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                      _completedConsentForm ? 'Accepting...' : 'Accept and Continue'),
                ),

              ],
            )
          ),
        ),
      ),
    );
  }
 
}