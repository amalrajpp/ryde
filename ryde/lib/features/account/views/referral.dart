import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ryde/shared/utils/custom_button.dart';
import 'package:ryde/shared/utils/custom_text.dart';

class AccountModuleReferralPage extends StatelessWidget {
  static const String routeName = '/account_module/referral';
  const AccountModuleReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final code = 'REF-ABCD-1234';
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: Column(
        children: [
          Container(
            height: 110,
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.045),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'Earn 10% on referrals',
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                //ClipRRect(child: Image.asset(AppImages.referralGenius)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size.width * 0.05),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: MyText(text: code)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied')),
                    );
                  },
                  child: const Text('Copy'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: CustomButton(
              buttonName: 'Share',
              //onTap: () =>
              //Share.share('Use my code $code and get a discount!')
            ),
          ),
        ],
      ),
    );
  }
}
