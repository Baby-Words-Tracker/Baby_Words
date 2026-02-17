import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Phone verification step for 2FA setup
/// Collects phone number, sends SMS code, verifies it
class PhoneVerificationPage extends StatefulWidget {
  static const routeName = '/onboarding/phone-verification';

  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;
  String _currentUsDigits = '';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handlePhoneInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneInputChanged);
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handlePhoneInputChanged() {
    var digitsOnly = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 10 && digitsOnly.startsWith('1')) {
      digitsOnly = digitsOnly.substring(1);
    }

    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    final limited = digitsOnly;

    if (limited == _currentUsDigits) {
      return;
    }

    _currentUsDigits = limited;
    final formatted = _formatUsPhoneNumber(limited);

    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatUsPhoneNumber(String digits) {
    if (digits.isEmpty) {
      return '';
    }

    if (digits.length < 3) {
      return '($digits';
    }

    final buffer = StringBuffer()
      ..write('(')
      ..write(digits.substring(0, 3))
      ..write(')');

    if (digits.length == 3) {
      return buffer.toString();
    }

    if (digits.length <= 6) {
      buffer
        ..write(' ')
        ..write(digits.substring(3));
      return buffer.toString();
    }

    buffer
      ..write(' ')
      ..write(digits.substring(3, 6))
      ..write('-')
      ..write(digits.substring(6));

    return buffer.toString();
  }

  String? _getE164PhoneNumber() {
    if (_currentUsDigits.length != 10) {
      return null;
    }
    return '+1$_currentUsDigits';
  }

  String? _getDisplayPhoneNumber() {
    if (_currentUsDigits.isEmpty) {
      return null;
    }
    return '+1 ${_formatUsPhoneNumber(_currentUsDigits)}';
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phoneNumber = _getE164PhoneNumber();
    if (phoneNumber == null) {
      setState(() {
        _errorMessage = 'Enter a valid 10-digit US phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint('PhoneVerificationPage: Sending code to $phoneNumber');

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('PhoneVerificationPage: Auto-verification completed');
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
              'PhoneVerificationPage: Verification failed. Code: ${e.code}. Message: ${e.message}. Full error: $e');
          if (mounted) {
            setState(() {
              _errorMessage = e.message ?? 'Verification failed';
              _isLoading = false;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
              'PhoneVerificationPage: Code sent, verificationId: $verificationId');
          if (mounted) {
            setState(() {
              _codeSent = true;
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isLoading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('PhoneVerificationPage: Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('PhoneVerificationPage: Error sending code: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim();
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      await _linkPhoneCredential(credential);
    } catch (e) {
      debugPrint('PhoneVerificationPage: Error verifying code: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid verification code';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Link phone credential to existing account
      await user.linkWithCredential(credential);

      debugPrint('PhoneVerificationPage: Phone number linked successfully');

      // Update UserProfile to mark 2FA as enabled and save phone number
      if (mounted) {
        final userModelService = context.read<UserProfileModelService>();
        final normalizedPhone = _getE164PhoneNumber();
        await userModelService.enable2FA(phoneNumber: normalizedPhone);

        debugPrint(
            'PhoneVerificationPage: 2FA enabled in UserProfile with phone: ${normalizedPhone ?? 'unknown'}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // The AuthGate will automatically move to next step
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'PhoneVerificationPage: Firebase error linking credential: ${e.message}');

      if (mounted) {
        String message = 'Error verifying phone number';

        if (e.code == 'provider-already-linked') {
          message = 'This phone number is already linked to your account';
          // Still mark 2FA as enabled
          final userModelService = context.read<UserProfileModelService>();
          await userModelService.enable2FA();
        } else if (e.code == 'credential-already-in-use') {
          message = 'This phone number is already in use by another account';
        } else if (e.code == 'invalid-verification-code') {
          message = 'Invalid verification code';
        }

        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PhoneVerificationPage: Error linking credential: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Sign In',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Return to Sign In'),
                content: const Text(
                  'Signing out will take you back to the sign-in screen so you can restart setup or adjust your information.',
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

            if (confirmed == true && context.mounted) {
              await context.read<AuthenticationService>().signOut();
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.phone_android,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _codeSent
                        ? 'Enter Verification Code'
                        : 'Verify Phone Number',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code sent to ${_getDisplayPhoneNumber() ?? 'your phone number'}'
                        : 'We\u2019ll send a verification code to your US mobile number.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Phone number input (only show if code not sent yet)
                  if (!_codeSent) ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '(555) 123-4567',
                        prefixIcon: const Icon(Icons.phone),
                        prefixText: '+1 ',
                        helperText: 'US numbers only. Just type the digits.',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (_currentUsDigits.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (_currentUsDigits.length != 10) {
                          return 'Enter a 10-digit US phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _sendVerificationCode,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Sending...' : 'Send Code'),
                    ),
                  ],

                  // Code input (only show after code is sent)
                  if (_codeSent) ...[
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      enabled: !_isLoading,
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _verifyCode,
                      icon: _isLoading
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
                      label: Text(_isLoading ? 'Verifying...' : 'Verify Code'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _sendVerificationCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resend Code'),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Two-factor authentication adds an extra layer of security to your account',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
