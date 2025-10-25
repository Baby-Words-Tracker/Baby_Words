import 'dart:io';

import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/video/local_video_entry.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class WordDetailSheet extends StatelessWidget {
  const WordDetailSheet({
    super.key,
    required this.displayWord,
    required this.tracker,
    required this.languageLabel,
    required this.dateLabel,
    required this.localization,
    this.attachment,
    this.onOpenAttachment,
  });

  final String displayWord;
  final WordTracker tracker;
  final String languageLabel;
  final String dateLabel;
  final LocalizationService localization;
  final LocalVideoEntry? attachment;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayWord,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            WordDetailInfoRow(
              icon: Icons.language,
              label: localization.translate('log_details_language'),
              value: languageLabel,
            ),
            WordDetailInfoRow(
              icon: Icons.calendar_month_outlined,
              label: localization
                  .translate('log_details_recorded')
                  .replaceFirst('{date}', dateLabel),
            ),
            if (tracker.phraseText != null && tracker.phraseText!.isNotEmpty)
              WordDetailInfoRow(
                icon: Icons.menu_book_outlined,
                label: localization.translate('log_details_phrase_source'),
                value: '"${tracker.phraseText!}"',
              ),
            const SizedBox(height: 16),
            WordNoteSection(
              note: tracker.note,
              localization: localization,
            ),
            const SizedBox(height: 16),
            WordAttachmentSection(
              attachment: attachment,
              localization: localization,
              onOpenAttachment: onOpenAttachment,
            ),
          ],
        ),
      ),
    );
  }
}

class WordEditResult {
  WordEditResult({
    required this.word,
    required this.language,
    required this.note,
  });

  final String word;
  final LanguageCode? language;
  final String note;
}

class WordEditSheet extends StatefulWidget {
  const WordEditSheet({
    super.key,
    required this.initialWord,
    required this.initialLanguage,
    required this.availableLanguages,
    required this.initialNote,
    required this.localization,
  });

  final String initialWord;
  final LanguageCode? initialLanguage;
  final List<LanguageCode> availableLanguages;
  final String? initialNote;
  final LocalizationService localization;

  @override
  State<WordEditSheet> createState() => _WordEditSheetState();
}

class _WordEditSheetState extends State<WordEditSheet> {
  late final TextEditingController _wordController;
  late final TextEditingController _noteController;
  late LanguageCode? _selectedLanguage;
  String? _wordError;

  List<LanguageCode> get _languages => widget.availableLanguages.isNotEmpty
      ? widget.availableLanguages
      : LanguageCode.values;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.initialWord);
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedLanguage = widget.initialLanguage ??
        (widget.availableLanguages.isNotEmpty
            ? widget.availableLanguages.first
            : LanguageCode.en);
  }

  @override
  void dispose() {
    _wordController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final rawWord = _wordController.text.trim();
    if (rawWord.isEmpty) {
      setState(() => _wordError =
          widget.localization.translate('validation_word_required'));
      return;
    }

    Navigator.of(context).pop(
      WordEditResult(
        word: rawWord,
        language: _selectedLanguage,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.localization.translate('log_edit_word_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wordController,
              decoration: InputDecoration(
                labelText: widget.localization.translate('log_edit_word_label'),
                errorText: _wordError,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_wordError != null) {
                  setState(() => _wordError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LanguageCode>(
              value: _selectedLanguage,
              items: _languages
                  .map(
                    (code) => DropdownMenuItem<LanguageCode>(
                      value: code,
                      child: Text(code.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedLanguage = value),
              decoration: InputDecoration(
                labelText: widget.localization.translate('select_language'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.localization.translate('note_optional'),
              ),
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(widget.localization.translate('cancel')),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _handleSave,
                  child: Text(widget.localization.translate('save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WordNoteSection extends StatelessWidget {
  const WordNoteSection({
    super.key,
    required this.note,
    required this.localization,
  });

  final String? note;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (note == null || note!.trim().isEmpty) {
      return Text(
        localization.translate('log_details_no_note'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('log_details_note_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              note!.trim(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class WordAttachmentSection extends StatelessWidget {
  const WordAttachmentSection({
    super.key,
    required this.attachment,
    required this.localization,
    required this.onOpenAttachment,
  });

  final LocalVideoEntry? attachment;
  final LocalizationService localization;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('log_details_attachment_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (attachment == null)
          Text(
            localization.translate('log_details_no_attachment'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(
                _isImageFile(attachment!.filePath)
                    ? Icons.photo_camera_outlined
                    : Icons.play_circle_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                p.basename(attachment!.filePath),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                localization.translate('log_details_view_media_subtitle'),
              ),
              trailing: Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
              ),
              onTap: onOpenAttachment,
            ),
          ),
      ],
    );
  }
}

class WordDetailInfoRow extends StatelessWidget {
  const WordDetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class WordMediaPreviewSheet extends StatefulWidget {
  const WordMediaPreviewSheet({
    super.key,
    required this.entry,
  });

  final LocalVideoEntry entry;

  @override
  State<WordMediaPreviewSheet> createState() => _WordMediaPreviewSheetState();
}

class _WordMediaPreviewSheetState extends State<WordMediaPreviewSheet> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = false;
  bool _isVideo = false;
  bool _isImage = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final path = widget.entry.filePath;
    _isVideo = _isVideoFile(path);
    _isImage = _isImageFile(path);

    if (_isVideo) {
      _initialiseVideo();
    }
  }

  Future<void> _initialiseVideo() async {
    if (kIsWeb) {
      setState(() {
        _error = 'log_details_attachment_unsupported';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.entry.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'log_details_attachment_missing';
        });
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
    } catch (_) {
      setState(() {
        _error = 'log_details_attachment_missing';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = context.read<LocalizationService>();
    final fileName = p.basename(widget.entry.filePath);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fileName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Text(
              localization.translate(_error!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else if (_isVideo && _chewieController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            )
          else if (_isImage)
            kIsWeb
                ? Text(
                    localization
                        .translate('log_details_attachment_unsupported'),
                    style: theme.textTheme.bodyMedium,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.entry.filePath),
                      fit: BoxFit.cover,
                    ),
                  )
          else
            Text(
              localization.translate('log_details_attachment_unsupported'),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

bool _isImageFile(String path) {
  final extension = p.extension(path).toLowerCase();
  return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(extension);
}

bool _isVideoFile(String path) {
  final extension = p.extension(path).toLowerCase();
  return ['.mp4', '.mov', '.m4v'].contains(extension);
}
