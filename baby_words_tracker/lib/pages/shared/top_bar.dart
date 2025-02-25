
import 'package:flutter/material.dart';

AppBar topBar(var context, String pageName){
  return AppBar(
        title: Text(pageName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profilepage');
            },
          )
        ],
        automaticallyImplyLeading: true,
      );
}
