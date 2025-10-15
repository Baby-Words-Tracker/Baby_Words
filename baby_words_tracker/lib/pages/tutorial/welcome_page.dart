import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Welcome screen shown to new users after completing onboarding
/// Introduces them to WordBuds and sets expectations
class WelcomePage extends StatelessWidget {
  static const routeName = '/tutorial/welcome';
  
  final VoidCallback onComplete;
  
  const WelcomePage({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Mascot/Logo at top
              Expanded(
                flex: 3,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/lecs_mascot_overlap.svg',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              
              // Welcome content
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to WordBuds!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Track your child\'s language development journey with ease',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Feature highlights
                    _buildFeatureItem(
                      context,
                      Icons.child_care,
                      'Track multiple children',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.chat_bubble_outline,
                      'Record words and milestones',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.insights,
                      'View progress and insights',
                    ),
                  ],
                ),
              ),
              
              // Get Started button
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Get Started'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
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

