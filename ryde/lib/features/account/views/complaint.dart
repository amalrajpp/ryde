import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_button.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleComplaintPage extends StatefulWidget {
  static const String routeName = '/account_module/complaint';
  const AccountModuleComplaintPage({super.key});

  @override
  State<AccountModuleComplaintPage> createState() =>
      _AccountModuleComplaintPageState();
}

class _AccountModuleComplaintPageState
    extends State<AccountModuleComplaintPage> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: CustomAppBar(title: 'Complaint', automaticallyImplyLeading: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.03),
            MyText(
              text: 'Complaint Title',
              textStyle: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.02),
            Container(
              height: size.width * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write your complaint',
                  ),
                ),
              ),
            ),
            SizedBox(height: size.width * 0.1),
            Center(
              child: CustomButton(buttonName: 'Submit', onTap: _submit),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint must be at least 10 characters'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint submitted (dummy)')),
    );
    Navigator.pop(context);
  }
}
