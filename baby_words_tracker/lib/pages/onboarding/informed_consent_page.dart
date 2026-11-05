import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

/*
Requirements for this page:

- send docusign to provided email
- keep tabs of whether or not info can be stored and used in firebase
- determine whether an action has happened within the email 
  - or make a "honor system" button 
*/ 

class InformedConsentPage extends StatefulWidget {
  static const routeName = '/onboarding/informed-consent';
  
  const InformedConsentPage({super.key});

  @override
  State<InformedConsentPage> createState() => _InformedConsentPageState();
}

class _InformedConsentPageState extends State<InformedConsentPage> {
  // what variables do we need? idk
}