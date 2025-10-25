import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//displays a datepicker, then changes the TextController to be a text representation of the date
Future<void> selectDate(
    BuildContext context, TextEditingController dateController) async {
  final now = DateTime.now();
  final initialDate = DateTime.now().subtract(const Duration(days: 180));
  final earliestDate = DateTime(2000);

  Future<void> updateController(DateTime? selected) async {
    if (selected != null) {
      dateController.text =
          selected.toLocal().toString().split(' ')[0]; // Format date
    }
  }

  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    DateTime tempDate = initialDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 320,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  updateController(tempDate);
                },
                child: const Text('Done'),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: earliestDate,
                maximumDate: now,
                onDateTimeChanged: (value) => tempDate = value,
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: now,
    );
    await updateController(pickedDate);
  }
}

Future<void> showAlertMessage(
  BuildContext context,
  String title,
  String message,
) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      }
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<void> showAlertIfMounted(
  BuildContext context,
  String title,
  String message,
) {
  if (!context.mounted) {
    return Future.value();
  }
  return showAlertMessage(context, title, message);
}

Future<bool> showConfirmationDialog(BuildContext context, String message,
    {String? title}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        return CupertinoAlertDialog(
          title: Text(title ?? 'Confirm Action'),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      }
      return AlertDialog(
        title: Text(title ?? 'Confirm Action'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
