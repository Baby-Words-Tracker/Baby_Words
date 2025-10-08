import 'dart:async';
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Email verification step in onboarding flow
/// Sends verification email and waits for user to verify
class EmailVerificationPage extends StatefulWidget {
  static const routeName = '/onboarding/email-verification';
  
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isResending = false;
  bool _isChecking = false;
  bool _isSkipping = false;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    // Send initial verification email
    _sendVerificationEmail(isInitial: true);
    // Start auto-checking for verification
    _startAutoCheck();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    // Check every 3 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkEmailVerified(isManualCheck: false);
      }
    });
  }

  Future<void> _checkEmailVerified({bool isManualCheck = true}) async {
    if (_isChecking) return;
    
    // Only show loading state for manual checks (button clicks)
    // Auto-checks happen silently in background
    if (isManualCheck && mounted) {
      setState(() {
        _isChecking = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Reload user to get latest verification status
        await user.reload();
        
        // Get fresh user object
        final freshUser = FirebaseAuth.instance.currentUser;
        
        if (freshUser?.emailVerified == true) {
          debugPrint('✅ EmailVerificationPage: Email verified!');
          
          // Stop auto-checking
          _autoCheckTimer?.cancel();
          
          // Reload to trigger userChanges() stream in AuthGate
          // This will automatically advance to the next step
          await freshUser!.reload();
          
          debugPrint('✅ AuthGate will now detect verification and advance');
          
          // The AuthGate's userChanges() stream will fire and move to next step
        }
      }
    } catch (e) {
      debugPrint('❌ EmailVerificationPage: Error checking verification: $e');
    } finally {
      if (mounted && isManualCheck) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _forceVerifyEmail() async {
    if (_isSkipping) return;

    setState(() {
      _isSkipping = true;
    });

    try {
      // Call Cloud Function to force verify email (uses Admin SDK)
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('forceVerifyEmail');
      
      debugPrint('🚧 DEV: Calling forceVerifyEmail Cloud Function...');
      final result = await callable.call();
      
      debugPrint('🚧 DEV: ${result.data['message']}');
      
      // Reload user to get updated emailVerified status
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! (DEV MODE)'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // The userChanges() stream will detect this and advance to next step
      debugPrint('✅ Email verification skipped successfully');
      
    } catch (e) {
      debugPrint('❌ Error forcing email verification: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSkipping = false;
        });
      }
    }
  }

  Future<void> _sendVerificationEmail({bool isInitial = false}) async {
    if (_isResending && !isInitial) return;

    setState(() {
      _isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (mounted && !isInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        debugPrint('📧 EmailVerificationPage: Verification email sent to ${user.email}');
        debugPrint('📧 Check your email inbox and click the verification link');
        debugPrint('📧 After clicking the link, return to this screen');
      }
    } catch (e) {
      debugPrint('❌ EmailVerificationPage: Error sending verification email: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthenticationService>().signOut();
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
              children: [
                // Icon
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Instructions
                Text(
                  'We\'ve sent a verification email to:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Email address
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Steps card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Steps:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStep('1', 'Check your email inbox'),
                        const SizedBox(height: 12),
                        _buildStep('2', 'Click the verification link'),
                        const SizedBox(height: 12),
                        _buildStep('3', 'Return to this app'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Auto-checking indicator (subtle, no rebuilding)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-checking every 3 seconds',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Resend button
                OutlinedButton.icon(
                  onPressed: _isResending ? null : () => _sendVerificationEmail(),
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
                
                // Skip button (development only) - Actually verifies email using Cloud Function
                FilledButton.icon(
                  onPressed: _isSkipping ? null : _forceVerifyEmail,
                  icon: _isSkipping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.verified),
                  label: Text(_isSkipping ? 'Verifying...' : 'Skip - Verify Email (DEV ONLY)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Help text
                Text(
                  'Didn\'t receive the email? Check your spam folder or try resending.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

