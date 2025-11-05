import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/video_picker.dart';
import 'package:baby_words_tracker/video/media_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UploadVideoPage extends StatefulWidget {
  static const routeName = '/uploadvideo';
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final TextEditingController _fileController = TextEditingController();
  List<WordTracker> _words = const [];
  String? _selectedWordId;
  VideoSelectionResult? _selectedVideo;

  String? _lastChildId;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentChildrenService = context.watch<CurrentChildrenService>();
    final childId = currentChildrenService.getCurrChild()?.id;

    if (childId != _lastChildId) {
      _lastChildId = childId;
      if (childId != null) {
        _loadWords(childId);
      } else {
        setState(() {
          _words = const [];
          _selectedWordId = null;
        });
      }
    }
  }

  Future<void> _loadWords(String childId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final childService = context.read<ChildDataService>();
      final words = await childService.getAllKnownWords(childId);
      setState(() {
        _words = words;
        if (words.isEmpty) {
          _selectedWordId = null;
        } else if (_selectedWordId == null ||
            !_words.any((word) => word.id == _selectedWordId)) {
          _selectedWordId = words.first.id;
        }
      });
    } catch (error) {
      debugPrint('UploadVideoPage: Failed to load words - $error');
      if (mounted) {
        await showAlertIfMounted(
          context,
          'Unable to load words',
          'Please try again later.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVideoSelection(
    LocalizationService localizationService,
    MediaStorageService videoStorage,
  ) async {
    if (!videoStorage.isFeatureEnabled) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Video attachments are not available right now.",
      );
      return;
    }

    try {
      final result = await pickLocalVideo();
      if (result == null) {
        return;
      }
      setState(() {
        _selectedVideo = result;
        _fileController.text = result.displayName;
      });
    } on VideoSelectionException catch (error) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        error.message,
      );
    } catch (_) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Something went wrong while selecting the video. Please try again.",
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedVideo = null;
      _fileController.clear();
    });
  }

  Future<void> _saveVideo(
    LocalizationService localizationService,
    MediaStorageService videoStorage,
    CurrentChildrenService currentChildrenService,
  ) async {
    final childId = currentChildrenService.getCurrChild()?.id;
    if (childId == null) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Please add a child before attaching a video.",
      );
      return;
    }

    if (_selectedWordId == null) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Select a word before attaching a video.",
      );
      return;
    }

    if (_selectedVideo == null) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Choose a video to attach.",
      );
      return;
    }

    if (!videoStorage.isReady) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "We couldn't store the video yet. Please try again after your profile finishes loading.",
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await videoStorage.saveMediaForWord(
        childId: childId,
        wordId: _selectedWordId!,
        sourceFile: _selectedVideo!.file,
      );
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_added"),
        localizationService.translate("add_file_success"),
      );
      _clearSelection();
    } catch (_) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "We couldn't save the video. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, CurrentChildrenService,
        MediaStorageService>(
      builder: (context, localizationService, currentChildrenService,
          videoStorage, child) {
        final theme = Theme.of(context);
        final childId = currentChildrenService.getCurrChild()?.id;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar:
              TopBar(pageName: localizationService.translate("upload_video")),
          bottomNavigationBar: const CustomBottomBar(UploadVideoPage.routeName),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!videoStorage.isFeatureEnabled || kIsWeb)
                  _buildUnavailableBanner(theme)
                else if (childId == null)
                  _buildActionCard(
                    theme,
                    localizationService.translate("file_not_added"),
                    "Add a child to start attaching videos.",
                  )
                else if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_words.isEmpty)
                  _buildActionCard(
                    theme,
                    localizationService.translate("file_not_added"),
                    "Add a word first, then attach a video.",
                  )
                else
                  ..._buildForm(
                    theme,
                    localizationService,
                    currentChildrenService,
                    videoStorage,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnavailableBanner(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Video attachments are disabled.",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "You can re-enable them by flipping the feature flag once the workflow is ready for testing.",
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildForm(
    ThemeData theme,
    LocalizationService localizationService,
    CurrentChildrenService currentChildrenService,
    MediaStorageService videoStorage,
  ) {
    return [
      Text(
        "Attach a video to one of your child's saved words.",
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedWordId,
        items: _words
            .where((word) => word.id != null)
            .map(
              (word) => DropdownMenuItem<String>(
                value: word.id,
                child: Text(word.id!),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedWordId = value;
          });
        },
        decoration: const InputDecoration(
          labelText: "Select word",
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _fileController,
        readOnly: true,
        onTap: () => _handleVideoSelection(localizationService, videoStorage),
        decoration: InputDecoration(
          labelText: localizationService.translate("choose_file"),
          suffixIcon: _selectedVideo != null
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _clearSelection,
                )
              : Icon(
                  Icons.attach_file,
                  color: theme.colorScheme.primary,
                ),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _isSaving
            ? null
            : () => _saveVideo(
                  localizationService,
                  videoStorage,
                  currentChildrenService,
                ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(localizationService.translate("submit")),
      ),
    ];
  }

  Widget _buildActionCard(ThemeData theme, String title, String description) {
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
