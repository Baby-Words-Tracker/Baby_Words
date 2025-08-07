import 'package:flutter/material.dart';

//displays a datepicker, then changes the TextController to be a text representation of the date
Future<void> selectDate(
    BuildContext context, TextEditingController dateController) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now().subtract(const Duration(days: 180)),
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );

  if (pickedDate != null) {
    dateController.text =
        pickedDate.toLocal().toString().split(' ')[0]; // Format date
  }
}

void showAlertMessage(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmationDialog(BuildContext context, String message,
    {String? title}) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
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
      ) ??
      false;
}

Widget loadToNextPage(BuildContext context, String nextPageRouteName) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).pushReplacementNamed(nextPageRouteName);
  });

  return const Center(child: CircularProgressIndicator());
}
