import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleOutstationPage extends StatelessWidget {
  static const String routeName = '/account_module/outstation';
  const AccountModuleOutstationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = List.generate(
      5,
      (i) => {
        'pickup': 'Outstation Pickup ${i + 1}',
        'drop': 'Outstation Drop ${i + 1}',
        'date': '2025-12-${(i % 28) + 1}',
      },
    );
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Outstation',
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          itemCount: sample.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => Card(
            child: ListTile(
              title: MyText(text: sample[idx]['pickup']!),
              subtitle: MyText(
                text: '${sample[idx]['drop']} • ${sample[idx]['date']}',
              ),
              onTap: () => showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Trip'),
                  content: Text(
                    '${sample[idx]['pickup']}\n${sample[idx]['drop']}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
