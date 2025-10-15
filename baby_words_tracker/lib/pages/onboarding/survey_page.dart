import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/util/html_view_registry.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Research survey step in onboarding flow.
/// Displays the Qualtrics survey and records completion for parents.
class SurveyPage extends StatefulWidget {
  static const routeName = '/onboarding/survey';

  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  static const _qualtricsUrl =
      'https://universityofalabama.az1.qualtrics.com/jfe/form/SV_5vYPatDEkugyDQy';

  static int _viewTypeId = 0;

  bool _isSubmitting = false;
  bool _hasConsented = false;
  bool _isSurveyLoading = !kIsWeb;

  WebViewController? _webViewController;
  String? _iframeViewType;

  @override
  void initState() {
    super.initState();
    _initializeSurveyView();
  }

  void _initializeSurveyView() {
    if (kIsWeb) {
      _isSurveyLoading = false;
      final viewType = 'qualtrics-survey-${_viewTypeId++}';
      _iframeViewType = viewType;

      registerHtmlViewFactory(viewType, (int _) {
        final element = html.IFrameElement()
          ..src = _qualtricsUrl
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      });
    } else {
      final controller = WebViewController()
        ..setBackgroundColor(Colors.transparent)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isSurveyLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              if (!mounted) return;
              setState(() {
                _isSurveyLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to load survey: ${error.description}',
                  ),
                ),
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(_qualtricsUrl));

      _webViewController = controller;
    }
  }

  Future<void> _completeSurvey() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userModelService = context.read<UserProfileModelService>();
      await userModelService.completeSurvey(surveyVersion: 'qualtrics-v1');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey marked as complete. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openSurveyExternally() async {
    final uri = Uri.parse(_qualtricsUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open survey in a new tab.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Survey'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 96,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Research Survey',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please complete the Qualtrics survey below. This is required by our Institutional Review Board (IRB) before you can access the app.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _SurveyContainer(
                  isLoading: _isSurveyLoading,
                  iframeViewType: _iframeViewType,
                  webViewController: _webViewController,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _openSurveyExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open survey in browser'),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _hasConsented,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _hasConsented = value ?? false;
                          });
                        },
                  title: const Text(
                    'I certify that I have completed and signed the study consent form.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: (!_hasConsented || _isSubmitting)
                      ? null
                      : _completeSurvey,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Continue',
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Once you finish the Qualtrics survey, tap Continue to let us know it is complete. '
                            'The app will automatically advance you to the next onboarding step.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade900,
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
    );
  }
}

class _SurveyContainer extends StatelessWidget {
  const _SurveyContainer({
    required this.isLoading,
    required this.iframeViewType,
    required this.webViewController,
  });

  final bool isLoading;
  final String? iframeViewType;
  final WebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 520,
        child: Stack(
          children: [
            Positioned.fill(
              child: iframeViewType != null
                  ? HtmlElementView(viewType: iframeViewType!)
                  : (webViewController != null
                      ? WebViewWidget(controller: webViewController!)
                      : const SizedBox.shrink()),
            ),
            if (isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
