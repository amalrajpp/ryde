import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleAdminChatPage extends StatefulWidget {
  static const String routeName = '/account_module/admin_chat';
  const AccountModuleAdminChatPage({super.key});

  @override
  State<AccountModuleAdminChatPage> createState() =>
      _AccountModuleAdminChatPageState();
}

class _AccountModuleAdminChatPageState
    extends State<AccountModuleAdminChatPage> {
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hi, how can we help?', 'isMe': false},
    {'text': 'I have a problem with my last ride.', 'isMe': true},
  ];
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Chat',
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (ctx, idx) {
                final m = messages[idx];
                return Align(
                  alignment: m['isMe']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m['isMe']
                          ? Theme.of(context).primaryColor
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MyText(
                      text: m['text'],
                      textStyle: TextStyle(
                        color: m['isMe']
                            ? Colors.white
                            : Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              10,
              10,
              MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkGrey, width: 1.2),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type message',
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      InkWell(onTap: _send, child: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add({'text': text, 'isMe': true}));
    _ctrl.clear();
    // simulate reply
    Future.delayed(
      const Duration(milliseconds: 600),
      () => setState(
        () => messages.add({
          'text': 'Thanks — we will check on that.',
          'isMe': false,
        }),
      ),
    );
  }
}
