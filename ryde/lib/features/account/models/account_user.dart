class AccountUser {
  final String name;
  final String mobile;
  final String email;
  final String? profileImage; // local asset path or network
  final double? walletBalance;

  const AccountUser({
    required this.name,
    required this.mobile,
    required this.email,
    this.profileImage,
    this.walletBalance,
  });
}
