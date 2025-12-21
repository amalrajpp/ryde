import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde/features/account/views/history.dart';
import 'package:ryde/features/account/views/profile.dart';
import 'package:ryde/features/account/widgets/top_bar.dart';
import 'package:ryde/features/account/widgets/menu_options.dart';
import 'package:ryde/features/account/widgets/edit_options.dart';
import 'package:ryde/features/account/models/account_user.dart';
// Import module pages directly so we can navigate to the widgets without named routes
import 'notification.dart';
// local history/wallet pages are not used (we use feature screens), keep module pages below
import 'fav_location.dart';
import 'referral.dart';
import 'sos.dart';
import 'help.dart';
import 'settings.dart';

/// Reusable Account Module Page - uses dummy data so it can be integrated into another app.
class AccountModulePage extends StatefulWidget {
  static const String routeName = '/accountModulePage';

  /// Optional account user data. Provide this when you want real data to
  /// be shown instead of the built-in placeholders.
  final AccountUser? user;

  const AccountModulePage({super.key, this.user});

  @override
  State<AccountModulePage> createState() => _AccountModulePageState();
}

class _AccountModulePageState extends State<AccountModulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  AccountUser? _user;

  @override
  void initState() {
    super.initState();
    // If caller provided a user, use it immediately and still try to refresh.
    _user = widget.user;
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      User? authUser = _auth.currentUser;
      if (authUser == null) {
        // No authenticated user => keep provided or dummy
        return;
      }

      final doc = await _firestore.collection('users').doc(authUser.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final first = (data['firstName'] ?? '').toString();
        final last = (data['lastName'] ?? '').toString();
        final name = (first.isNotEmpty || last.isNotEmpty)
            ? ('$first ${last}'.trim())
            : (authUser.displayName ?? '');
        final email =
            (data['email'] ?? authUser.email ?? 'john.doe@example.com')
                .toString();
        final phone =
            (data['phone'] ?? authUser.phoneNumber ?? '+1 555-123-4567')
                .toString();
        final photo = (data['photoUrl'] ?? '').toString().isNotEmpty
            ? data['photoUrl'] as String
            : null;

        setState(() {
          _user = AccountUser(
            name: name,
            mobile: phone,
            email: email,
            profileImage: photo,
            walletBalance: null,
          );
        });
      } else {
        // Firestore doc not found - use auth fallback
        setState(() {
          _user = AccountUser(
            name: authUser.displayName ?? '',
            mobile: authUser.phoneNumber ?? '+1 555-123-4567',
            email: authUser.email ?? 'john.doe@example.com',
            profileImage: authUser.photoURL,
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch account user: $e');
      // leave existing _user as-is (either provided or null)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Use fetched user data or fall back to provided user or dummy values
    final name = _user?.name ?? widget.user?.name ?? '';
    final mobile = _user?.mobile ?? widget.user?.mobile ?? '+1 555-123-4567';
    final email = _user?.email ?? widget.user?.email ?? 'john.doe@example.com';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top area (visual similar to original)
            Container(
              width: size.width,
              height: size.width * 0.37,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: ModuleTopBar(
                title: name,
                //onBack: () => Navigator.of(context).pop(),
                subTitleWidget: Padding(
                  padding: EdgeInsets.only(top: size.width * 0.02),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          mobile,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),

            Expanded(
              child: Container(
                width: size.width,
                padding: EdgeInsets.all(size.width * 0.05),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: size.width * 0.05),
                      ModuleMenuOptions(
                        label: 'Personal Information',

                        imagePath:
                            _user?.profileImage ?? widget.user?.profileImage,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        ),
                      ),
                      ModuleMenuOptions(
                        label: 'Notifications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AccountModuleNotificationPage(),
                          ),
                        ),
                      ),
                      ModuleMenuOptions(
                        label: 'History',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountModuleHistoryPage(),
                          ),
                        ),
                      ),

                      ModuleMenuOptions(
                        label: 'Favorite Location',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AccountModuleFavLocationPage(),
                          ),
                        ),
                      ),
                      SizedBox(height: size.width * 0.03),
                      Text(
                        'Benefits',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: size.width * 0.05),
                      ModuleMenuOptions(
                        label: 'Refer & Earn',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountModuleReferralPage(),
                          ),
                        ),
                      ),
                      ModuleMenuOptions(
                        label: 'SOS',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountModuleSOSPage(),
                          ),
                        ),
                      ),
                      SizedBox(height: size.width * 0.03),
                      Text(
                        'Preferences',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: size.width * 0.05),
                      ModuleMenuOptions(
                        label: 'Change Language',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountModuleHelpPage(),
                          ),
                        ),
                      ),
                      SizedBox(height: size.width * 0.03),
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: size.width * 0.05),
                      ModuleMenuOptions(
                        label: 'App Settings',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountModuleSettingsPage(),
                          ),
                        ),
                      ),
                      SizedBox(height: size.width * 0.05),
                      ModuleEditOptions(
                        header: 'Email',
                        text: email,
                        onTap: () {},
                      ),
                      ModuleEditOptions(
                        header: 'Phone',
                        text: mobile,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
