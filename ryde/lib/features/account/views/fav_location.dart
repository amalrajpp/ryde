import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleFavLocationPage extends StatefulWidget {
  static const String routeName = '/account_module/fav_location';
  const AccountModuleFavLocationPage({super.key});

  @override
  State<AccountModuleFavLocationPage> createState() =>
      _AccountModuleFavLocationPageState();
}

class _AccountModuleFavLocationPageState
    extends State<AccountModuleFavLocationPage> {
  List<Map<String, String>> favs = [
    {'type': 'Home', 'address': '221B Baker Street, London'},
    {'type': 'Work', 'address': '1 Infinite Loop, Cupertino'},
    {'type': 'Other', 'address': 'Central Park, NYC'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Favorite Locations',
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final f = favs[idx];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: ListTile(
                    leading: Icon(
                      f['type'] == 'Home'
                          ? Icons.home
                          : f['type'] == 'Work'
                          ? Icons.work
                          : Icons.location_on,
                    ),
                    title: MyText(text: f['type']!),
                    subtitle: MyText(text: f['address']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _delete(idx),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addDummy,
              icon: const Icon(Icons.add),
              label: const Text('Add Location'),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(int idx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Remove this favorite location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => favs.removeAt(idx));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addDummy() => setState(
    () => favs.add({'type': 'Other', 'address': 'New Dummy Address'}),
  );
}
