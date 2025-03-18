import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> callFunction(
  BuildContext context,
  String functionName,
  Map<String, dynamic> arguments,
) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable(functionName);
  try {
    debugPrint('Calling function $functionName with arguments $arguments');
    final response = await function.call(arguments);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.data['message'])));
    } else {
      debugPrint(response.data['message']);
    }
    return response.data;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } else {
      debugPrint('Error: $error');
    }
    return null;
  }
  return {};
}
