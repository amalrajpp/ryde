import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ryde/core/constants/app_colors.dart';
import 'package:ryde/shared/utils/custom_text.dart';
import 'package:ryde/features/account/models/account_user.dart';
import 'package:ryde/features/account/controllers/account_controller.dart';
import 'package:ryde/features/account/widgets/edit_options.dart';
import 'package:ryde/features/account/widgets/top_bar.dart';

class AccountModuleProfilePage extends StatefulWidget {
  static const String routeName = '/account_module/profile';
  final AccountUser? user;
  const AccountModuleProfilePage({super.key, this.user});
  @override
  State<AccountModuleProfilePage> createState() =>
      _AccountModuleProfilePageState();
}

class _AccountModuleProfilePageState extends State<AccountModuleProfilePage> {
  final AccountController _accountController = Get.put(AccountController());

  @override
  // (initState already defined below, remove this duplicate)
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Scaffold(
        body: Obx(() {
          final user = _accountController.user.value;
          final isLoading = _accountController.isLoading.value;
          final error = _accountController.error.value;
          return Column(
            children: [
              Container(
                width: size.width,
                height: size.width * 0.37,
                color: Theme.of(context).primaryColor,
                child: ModuleTopBar(
                  title: 'Personal Information',
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error.isNotEmpty)
                Expanded(child: Center(child: Text(error)))
              else if (user == null)
                const Expanded(child: Center(child: Text('No user data')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.width * 0.08),
                          Container(
                            padding: EdgeInsets.all(size.width * 0.05),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: size.width * 0.12,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).dividerColor,
                                  backgroundImage:
                                      (user.profileImage != null &&
                                          user.profileImage!.isNotEmpty)
                                      ? (user.profileImage!.startsWith('http')
                                            ? NetworkImage(user.profileImage!)
                                            : AssetImage(user.profileImage!)
                                                  as ImageProvider)
                                      : null,
                                  child:
                                      (user.profileImage == null ||
                                          user.profileImage!.isEmpty)
                                      ? Center()
                                      : null,
                                ),
                                SizedBox(height: size.width * 0.04),
                                MyText(
                                  text: 'Add profile photo',
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.width * 0.06),
                          Container(
                            padding: EdgeInsets.all(size.width * 0.025),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                ModuleEditOptions(
                                  header: 'Name',
                                  text: user.name,
                                  onTap: () => _editField('Name'),
                                ),
                                ModuleEditOptions(
                                  header: 'Mobile',
                                  text: user.mobile,
                                  onTap: () => _editField('Mobile'),
                                ),
                                ModuleEditOptions(
                                  header: 'Email',
                                  text: user.email,
                                  onTap: () => _editField('Email'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.width * 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // (_editField already defined below, remove this duplicate)

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _accountController.setUser(widget.user);
    }
  }

  void _editField(String field) async {
    final user = _accountController.user.value;
    if (user == null) return;
    final controller = TextEditingController(
      text: field == 'Name'
          ? user.name
          : (field == 'Mobile' ? user.mobile : user.email),
    );
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      final updatedUser = AccountUser(
        name: field == 'Name' ? res : user.name,
        mobile: field == 'Mobile' ? res : user.mobile,
        email: field == 'Email' ? res : user.email,
        profileImage: user.profileImage,
        walletBalance: user.walletBalance,
      );
      _accountController.setUser(updatedUser);
    }
  }
}
