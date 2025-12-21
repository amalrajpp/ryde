import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleSupportTicketPage extends StatefulWidget {
  static const String routeName = '/account_module/support_ticket';
  const AccountModuleSupportTicketPage({super.key});

  @override
  State<AccountModuleSupportTicketPage> createState() =>
      _AccountModuleSupportTicketPageState();
}

class _AccountModuleSupportTicketPageState
    extends State<AccountModuleSupportTicketPage> {
  List<Map<String, String>> tickets = [
    {'title': 'Payment not received', 'status': 'Open'},
    {'title': 'Driver issue', 'status': 'Closed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Support Tickets',
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: tickets.isEmpty
            ? Center(child: MyText(text: 'No tickets'))
            : ListView.separated(
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) => ListTile(
                  tileColor: Theme.of(context).cardColor,
                  title: MyText(text: tickets[idx]['title']!),
                  subtitle: MyText(text: tickets[idx]['status']!),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTicket,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createTicket() {
    final controller = TextEditingController();
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
                controller: controller,
                decoration: const InputDecoration(hintText: 'Issue'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty)
                    setState(
                      () => tickets.add({
                        'title': controller.text,
                        'status': 'Open',
                      }),
                    );
                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
