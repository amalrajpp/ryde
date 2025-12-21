import 'package:flutter/material.dart';
import 'package:ryde/shared/utils/custom_appbar.dart';
import 'package:ryde/shared/utils/custom_button.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModulePaymentGatewaysPage extends StatelessWidget {
  static const String routeName = '/account_module/payment_gateways';
  const AccountModulePaymentGatewaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleGateways = ['Stripe', 'PayPal', 'ExamplePay'];
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment Gateways',
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: sampleGateways.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) => ListTile(
                  tileColor: Theme.of(context).cardColor,
                  title: MyText(text: sampleGateways[idx]),
                ),
              ),
            ),
            SafeArea(
              child: CustomButton(
                buttonName: 'Simulate Payment Success',
                onTap: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
