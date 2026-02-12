import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Guided tutorial page for adding first child
/// Shows helpful instructions and simplified UI
class AddFirstChildPage extends StatefulWidget {
  static const routeName = '/tutorial/add-first-child';

  const AddFirstChildPage({super.key});

  @override
  State<AddFirstChildPage> createState() => _AddFirstChildPageState();
}

class _AddFirstChildPageState extends State<AddFirstChildPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedBirthday;
  final List<LanguageCode> _selectedLanguages = [LanguageCode.en];
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: DateTime.now(),
      helpText: 'Select Birthday',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a birthday'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      // Use existing child creation logic
      await addChildToCurrParent(
        context,
        _nameController.text.trim(),
        _selectedBirthday!,
        _selectedLanguages,
      );

      debugPrint('✅ First child added successfully!');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${_nameController.text}! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Give user a moment to see success message
        await Future.delayed(const Duration(seconds: 1));

        // Tutorial is automatically complete when child is added
        // (TutorialFlowManager checks childIDs.isNotEmpty)
        // AuthGate will detect this and navigate to home
      }
    } catch (e) {
      debugPrint('❌ Error adding first child: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding child: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text( //const
                  'Add Your First Child',
                  style: TextStyle(
                    color: Colors.black,
                  ),
              ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction text
                Text(
                  'Let\'s get started! 🎈',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 35, 35, 35),
                      ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Add your child to start tracking their language development',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color.fromARGB(255, 95, 95, 95),
                      ),
                ),
                const SizedBox(height: 32),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Child\'s Name',
                    hintText: 'Enter your child\'s name',
                    prefixIcon: Icon(Icons.child_care),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isAdding,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Birthday selector
                InkWell(
                  onTap: _isAdding ? null : _selectBirthday,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedBirthday != null
                          ? DateFormat('MMMM d, yyyy')
                              .format(_selectedBirthday!)
                          : 'Tap to select birthday',
                      style: TextStyle(
                        color: _selectedBirthday != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Language selector
                const Text(
                  'Primary Language(s)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLanguageChip('English', LanguageCode.en),
                    _buildLanguageChip('Spanish', LanguageCode.es),
                    //Mandarin and French dictionaries not connected yet
                    //_buildLanguageChip('Mandarin', LanguageCode.zh),
                    //_buildLanguageChip('French', LanguageCode.fr),
                    // Add more as needed
                  ],
                ),

                const SizedBox(height: 32),

                // Helper text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can add more children later in Settings',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Add child button
                FilledButton.icon(
                  onPressed: _isAdding ? null : _addChild,
                  icon: _isAdding
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
                  label: Text(_isAdding ? 'Adding...' : 'Add Child & Continue'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip button (for shared children scenario)
                TextButton(
                  onPressed: _isAdding
                      ? null
                      : () {
                          debugPrint(
                              'Tutorial: User skipped adding first child');
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                  child: const Text('Skip - I\'ll add a child later'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String label, LanguageCode code) {
    final isSelected = _selectedLanguages.contains(code);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: _isAdding
          ? null
          : (selected) {
              setState(() {
                if (selected) {
                  _selectedLanguages.add(code);
                } else {
                  // Keep at least one language selected
                  if (_selectedLanguages.length > 1) {
                    _selectedLanguages.remove(code);
                  }
                }
              });
            },
    );
  }
}
