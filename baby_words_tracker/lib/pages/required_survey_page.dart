import 'package:baby_words_tracker/auth/new_user_model_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Placeholder survey screen that blocks access until survey is completed
/// This is a hard requirement from IRB
class RequiredSurveyPage extends StatefulWidget {
  static const routeName = '/required-survey';
  
  const RequiredSurveyPage({super.key});

  @override
  State<RequiredSurveyPage> createState() => _RequiredSurveyPageState();
}

class _RequiredSurveyPageState extends State<RequiredSurveyPage> {
  bool _isSubmitting = false;

  Future<void> _completeSurvey() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userModelService = context.read<NewUserModelService>();
      
      // TODO: Replace with actual survey data collection
      // For now, just mark as complete
      await userModelService.completeSurvey(surveyVersion: 'v1.0-placeholder');
      
      // Navigation will happen automatically via AuthGate listening to profile changes
      debugPrint('RequiredSurveyPage: Survey marked as complete');
    } catch (e) {
      debugPrint('RequiredSurveyPage: Error completing survey: $e');
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Survey'),
        automaticallyImplyLeading: false, // Can't go back without completing
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
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Survey Required',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Before you can use the app, you must complete a brief survey. '
                  'This is required by our Institutional Review Board (IRB) for research purposes.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Placeholder survey content
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Survey Placeholder',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This is a placeholder for the actual survey. '
                          'The real survey will be integrated from another branch.',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Questions to include:\n'
                          '• Demographics\n'
                          '• Child information\n'
                          '• Language background\n'
                          '• Research consent',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                FilledButton(
                  onPressed: _isSubmitting ? null : _completeSurvey,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Complete Survey (Placeholder)'),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Note: You cannot proceed without completing this survey.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
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
}

