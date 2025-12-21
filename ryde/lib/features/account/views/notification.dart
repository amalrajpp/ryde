import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleNotificationPage extends StatefulWidget {
  static const String routeName = '/account_module/notification';
  const AccountModuleNotificationPage({super.key});

  @override
  State<AccountModuleNotificationPage> createState() =>
      _AccountModuleNotificationPageState();
}

class _AccountModuleNotificationPageState
    extends State<AccountModuleNotificationPage> {
  List<Map<String, String>> items = List.generate(
    6,
    (i) => {
      'title': 'Notification ${i + 1}',
      'subtitle': 'This is a sample notification message for item ${i + 1}',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        automaticallyImplyLeading: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //Image.asset(AppImages.notificationsNoData),
                    const SizedBox(height: 16),
                    MyText(
                      text: 'No notifications',
                      textStyle: Theme.of(context).textTheme.bodyMedium!,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item['title']! + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => setState(() => items.removeAt(index)),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    tileColor: Theme.of(context).cardColor,
                    title: MyText(text: item['title']!),
                    subtitle: MyText(text: item['subtitle']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptions(index),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => items.removeAt(index));
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear all'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => items.clear());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
