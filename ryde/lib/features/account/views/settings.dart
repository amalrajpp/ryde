import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_text.dart';

// imports kept minimal for module
import '../widgets/menu_options.dart';

class AccountModuleSettingsPage extends StatefulWidget {
  static const String routeName = '/account_module/settings';
  const AccountModuleSettingsPage({super.key});

  @override
  State<AccountModuleSettingsPage> createState() =>
      _AccountModuleSettingsPageState();
}

class _AccountModuleSettingsPageState extends State<AccountModuleSettingsPage> {
  bool darkTheme = false;

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ModuleMenuOptions(
              label: 'Theme',
              icon: darkTheme ? Icons.dark_mode : Icons.light_mode,
              onTap: () => setState(() => darkTheme = !darkTheme),
            ),
            ModuleMenuOptions(
              label: 'FAQ',
              icon: Icons.question_answer,
              onTap: () {},
            ),
            ModuleMenuOptions(
              label: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {},
            ),
            ModuleMenuOptions(
              label: 'Logout',
              icon: Icons.logout,
              onTap: () => _showLogout(),
            ),
            const Spacer(),
            Center(
              child: MyText(
                text: 'V 1.0.0',
                textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
