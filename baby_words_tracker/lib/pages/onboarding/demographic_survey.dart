import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Demographic survey step in onboarding flow.
/// Collects basic demographic information from parents.
class DemographicSurveyPage extends StatefulWidget {
  static const routeName = '/onboarding/demographic-survey';

  const DemographicSurveyPage({super.key});

  @override
  State<DemographicSurveyPage> createState() => _DemographicSurveyPageState();
}

class _DemographicSurveyPageState extends State<DemographicSurveyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one empty child to make the UI more user-friendly
    _childAges.add({'age': ''});
  }
  String? _ageRange;
  String? _gender;
  String? _otherDropdownValue; //other gender option
  String? _educationLevel;
  String? _otherParentEducation;
  String? _householdIncome;
  String? _primaryLanguages;
  String? _otherLanguages;
  String? _numAdults;
  List<Map<String, String>> _childAges = []; // Changed to list of child age maps
  List<String> _childCare = []; // Changed to list for multi-select
  String? _otherChildCare; // For "Other" option

  // Dropdown options
  final List<String> _ageRanges = [
    '18-24',
    '25-34',
    '35-44',
    '45+'
  ];

  final List<String> _genders = [
    'Female',
    'Male',
    'Other (specify if desired)'
  ];

  final List<String> _educationLevels = [
    'Some high school',
    'High school diploma/GED',
    'Some college',
    'Associate\'s degree',
    'Bachelor\'s degree',
    'Master\'s degree',
    'Doctoral/Professional degree'
  ];

  final List<String> _otherParentEducations = [
    'Some high school',
    'High school diploma/GED',
    'Some college',
    'Associate\'s degree',
    'Bachelor\'s degree',
    'Master\'s degree',
    'Doctoral/Professional degree',
    'Not applicable'
  ];

  final List<String> _incomeRanges = [
    'Under \$25,000',
    '\$25,000 - \$49,999',
    '\$50,000 - \$74,999',
    '\$75,000 - \$99,999',
    '\$100,000 - \$149,999',
    '\$150,000+',
    'Prefer not to answer'
  ];

  final List<String> _childCares = [
    'Home with parent/guardian',
    'Home with other family member',
    'Childcare center',
    'In-home daycare',
    'Preschool/Pre-K program',
    'With nanny/babysitter',
    'Other: '
  ];


  Future<void> _completeSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for child ages
    if (_childAges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one child and their age'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validChildren = _childAges.where((child) =>
      child['age'] != null && child['age']!.trim().isNotEmpty
    ).length;

    if (validChildren == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter ages for all children'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userModelService = context.read<UserProfileModelService>();

      // Save demographic data to user profile
      await userModelService.updateUserProfile({
        'demographicData': {
          'ageRange': _ageRange,
          'gender': _gender,
          'genderOther': _otherDropdownValue,
          'educationLevel': _educationLevel,
          'otherParentEducation': _otherParentEducation,
          'householdIncome': _householdIncome,
          'primaryLanguage': _primaryLanguages,
          'otherLanguages': _otherLanguages,
          'numberOfAdults': _numAdults,
          'childAges': _childAges.map((child) => child['age']).where((age) => age != null && age.isNotEmpty).toList(),
          'childCareArrangements': _childCare,
          'otherChildCare': _otherChildCare,
          'completedAt': DateTime.now().toIso8601String(),
        }
      });

      // Mark survey as complete
      await userModelService.completeSurvey(surveyVersion: 'demographic-v1');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demographic survey completed. Thank you!'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Demographic Survey',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black,
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Demographic Information',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thank you for your interest in participating in the WordBuds study on parent language use and child language development. Please complete this confidential form.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Parent/Guardian Information Section
                  _buildSectionHeader('Parent/Guardian Information'),
                  const SizedBox(height: 16),

                  // Age Range
                  _buildDropdownField(
                    label: 'Age',
                    value: _ageRange,
                    items: _ageRanges,
                    onChanged: (value) => setState(() => _ageRange = value),
                    validator: (value) => value == null ? 'Please select your age range' : null,
                  ),

                  // Gender
                  _buildDropdownField(
                    label: 'Gender',
                    value: _gender,
                    items: _genders,
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (value) => value == null ? 'Please select your gender' : null,
                    allowOther: true,
                  ),

                  // Education Level
                  _buildDropdownField(
                    label: 'Your Highest Education Level Completed',
                    value: _educationLevel,
                    items: _educationLevels,
                    onChanged: (value) => setState(() => _educationLevel = value),
                    validator: (value) => value == null ? 'Please select your education level' : null,
                  ),

                  // Education Level
                  _buildDropdownField(
                    label: 'Other Parent/Guardian\'s Highest Education Level (if applicable)',
                    value: _otherParentEducation,
                    items: _otherParentEducations,
                    onChanged: (value) => setState(() => _otherParentEducation = value),
                    validator: (value) => value == null ? 'Please select other parent/guardian\'s education level' : null,
                  ),

                  _buildSectionHeader('Household Information'),
                  const SizedBox(height: 16),

                  // Household Income
                  _buildDropdownField(
                    label: 'Annual Household Income',
                    value: _householdIncome,
                    items: _incomeRanges,
                    onChanged: (value) => setState(() => _householdIncome = value),
                    validator: (value) => value == null ? 'Please select your household income range' : null,
                  ),

                  // Primary Language
                  _buildTextField(
                    label: 'Primary Language(s) Spoken at Home',
                    value: _primaryLanguages,
                    hintText: 'e.g., Spanish, French, etc.',
                    onChanged: (value) => setState(() => _primaryLanguages = value),
                    validator: (value) => value == null ? 'Please select your primary languages' : null,
                  ),

                  // Other Languages (Text input)
                  _buildTextField(
                    label: 'Other Languages Regularly Used in Home',
                    value: _otherLanguages,
                    hintText: 'e.g., Spanish, French, etc.',
                    onChanged: (value) => setState(() => _otherLanguages = value),
                    validator: (value) => null,
                  ),

                  // Number of Adults (Text input for more flexibility)
                  _buildTextField(
                    label: 'Number of Adults in Household',
                    value: _numAdults,
                    hintText: 'e.g., 2',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _numAdults = value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the number of adults';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  // Child Information Section
                  _buildSectionHeader('Children in the Home'),
                  const SizedBox(height: 16),

                  // Child Ages (Structured list input)
                  _buildChildAgesField(),


                  //Child care
                  // Child Information Section
                  _buildSectionHeader('Child Care Arrangements'),
                  const SizedBox(height: 16),

                  // Child Care (Multi-select)
                  _buildMultiSelectField(
                    label: 'For your child(ren) under age 5, please select all that apply during a typical week',
                    selectedValues: _childCare,
                    allOptions: _childCares,
                    onChanged: (values) => setState(() => _childCare = values),
                    allowOther: true,
                    validator: (values) {
                      if (values == null || values.isEmpty) {
                        return 'Please select at least one child care arrangement';
                      }
                      return null;
                    },
                  ),
            

                  const SizedBox(height: 32),

                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _completeSurvey,
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
                      _isSubmitting ? 'Submitting...' : 'Complete Survey',
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
                              'Thank you for completing this form. All information provided will remain confidential and will be used only for research purposes related to the WordBuds study.',
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
      ),
    );
  }
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Color.fromARGB(255, 117, 17, 17),
          color: Color.fromARGB(255, 117, 17, 17), // Maroon color matching the app theme
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator, // ✅ made optional
    bool allowOther = false,
  }) {
    final isOtherSelected =
        allowOther && value != null && value.contains('Other');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),

          // Dropdown
          DropdownButtonFormField<String>(
            value: value, // ✅ use value (not initialValue)
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (newValue) {
              onChanged(newValue);

              if (allowOther) {
                setState(() {
                  if (newValue != null && newValue.contains('Other')) {
                    _otherDropdownValue ??= '';
                  } else {
                    _otherDropdownValue = null;
                  }
                });
              }
            },
            validator: validator,
          ),

          // Optional "Other" field
          if (isOtherSelected) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _otherDropdownValue,
              decoration: const InputDecoration(
                labelText: 'Please specify (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _otherDropdownValue = val;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required List<String> selectedValues,
    required List<String> allOptions,
    required ValueChanged<List<String>> onChanged,
    String? Function(List<String>?)? validator,
    bool allowOther = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: allOptions.map((option) {
                final isSelected = selectedValues.contains(option);
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  onChanged: (bool? checked) {
                    final newSelection = List<String>.from(selectedValues);
                    if (checked == true) {
                      newSelection.add(option);
                    } else {
                      newSelection.remove(option);
                    }
                    onChanged(newSelection);
                  },
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          if (allowOther && selectedValues.contains('Other: ')) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please specify other child care arrangements',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _otherChildCare,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _otherChildCare = value),
                  validator: (value) {
                    if (selectedValues.contains('Other: ') &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please specify other arrangements';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildAgesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ages of Children in Household',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._childAges.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Child ${index + 1}:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: child['age'] ?? '',
                      decoration: InputDecoration(
                        hintText: 'e.g., 2 years, 6 months',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _childAges[index]['age'] = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter age for Child ${index + 1}';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _childAges.removeAt(index);
                      });
                    },
                    tooltip: 'Remove child',
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _childAges.add({'age': ''});
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Child'),
          ),
        ],
      ),
    );
  }
}