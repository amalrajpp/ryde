import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_button.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleSOSPage extends StatefulWidget {
  static const String routeName = '/account_module/sos';
  const AccountModuleSOSPage({super.key});

  @override
  State<AccountModuleSOSPage> createState() => _AccountModuleSOSPageState();
}

class _AccountModuleSOSPageState extends State<AccountModuleSOSPage> {
  List<Map<String, String>> contacts = [
    {'name': 'Police', 'phone': '100'},
    {'name': 'Ambulance', 'phone': '101'},
    {'name': 'Fire', 'phone': '102'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'SOS', automaticallyImplyLeading: true),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final c = contacts[idx];
                  return ListTile(
                    tileColor: Theme.of(context).cardColor,
                    leading: const Icon(Icons.contact_phone),
                    title: MyText(text: c['name']!),
                    subtitle: MyText(text: c['phone']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pretend calling ${c['phone']}'),
                            ),
                          ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomButton(
                  buttonName: 'Add Contact',
                  onTap: _addManual,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addManual() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(hintText: 'Phone'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty)
                    setState(
                      () => contacts.add({
                        'name': nameCtrl.text,
                        'phone': phoneCtrl.text,
                      }),
                    );
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
