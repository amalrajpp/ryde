import 'package:flutter/material.dart';

class AccountModuleHelpPage extends StatelessWidget {
  static const String routeName = '/account_module/help';
  const AccountModuleHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: const Center(child: Text('Dummy help and FAQ content')),
    );
  }
}
