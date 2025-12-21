import 'package:flutter/material.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_button.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleWalletPage extends StatefulWidget {
  static const String routeName = '/account_module/wallet';

  /// Optional initial balance to display
  final double? initialBalance;

  const AccountModuleWalletPage({super.key, this.initialBalance});

  @override
  State<AccountModuleWalletPage> createState() =>
      _AccountModuleWalletPageState();
}

class _AccountModuleWalletPageState extends State<AccountModuleWalletPage> {
  late double balance;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: CustomAppBar(title: 'Wallet', automaticallyImplyLeading: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(size.width * 0.05),
                child: Column(
                  children: [
                    MyText(
                      text: 'Wallet Balance',
                      textStyle: const TextStyle(color: AppColors.white),
                    ),
                    SizedBox(height: size.width * 0.02),
                    MyText(
                      text: '\$${balance.toStringAsFixed(2)}',
                      textStyle: const TextStyle(
                        color: AppColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Add Money',
                      onTap: () => _addMoneySheet(),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Transfer',
                      onTap: () => _showTransferDialog(),
                      buttonColor: AppColors.white,
                      textColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.width * 0.04),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: MyText(
                text: 'Recent Transactions',
                textStyle: Theme.of(context).textTheme.bodyMedium!,
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(size.width * 0.04),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: size.width * 0.03),
              itemBuilder: (ctx, idx) => ListTile(
                tileColor: Theme.of(context).cardColor,
                title: MyText(text: 'Transaction ${idx + 1}'),
                subtitle: MyText(
                  text:
                      'Payment • ${DateTime.now().toIso8601String().split('T').first}',
                ),
                trailing: MyText(text: '-\$${(10 + idx).toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    balance = widget.initialBalance ?? 124.50;
  }

  void _addMoneySheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  buttonName: 'Pay',
                  onTap: () {
                    final val = double.tryParse(ctrl.text) ?? 0;
                    if (val > 0) setState(() => balance += val);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferDialog() {
    final toCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toCtrl,
              decoration: const InputDecoration(hintText: 'Phone/Email'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text) ?? 0;
              if (val > 0 && val <= balance) {
                setState(() => balance -= val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
