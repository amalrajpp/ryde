import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers to handle user input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isEmailVerified = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 1. Fetch Data from Firebase
  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get Auth data
        setState(() {
          _isEmailVerified = user.emailVerified;
          _emailController.text = user.email ?? "";
        });

        // Get Firestore data (assuming collection is 'users' and doc is uid)
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _firstNameController.text = data['firstName'] ?? "";
            _lastNameController.text = data['lastName'] ?? "";
            _phoneController.text = data['phone'] ?? "";
            _profileImageUrl = data['photoUrl']; // optional
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 2. Update Data to Firebase
  Future<void> _updateUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text
            .trim(), // Optional: updating email in firestore only
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // Remove focus to hide keyboard
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9), // Light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your profile',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  // Added a small Save button to trigger the update explicitly
                  TextButton(
                    onPressed: _updateUserData,
                    child: const Text("Save", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 2. Avatar Section
              Center(
                child: Stack(
                  children: [
                    // Profile Image
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(
                            _profileImageUrl ??
                                "https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Edit Icon (Camera/Gallery)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: InkWell(
                        onTap: () {
                          // TODO: Implement Image Picker here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Image Picker would open here"),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name
                    _buildProfileField(
                      label: "First name",
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    _buildProfileField(
                      label: "Last name",
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: 20),

                    // Email (Usually Read-only from Auth, but editable here if you want to sync to Firestore)
                    _buildProfileField(
                      label: "Email",
                      controller: _emailController,
                      isReadOnly: true, // Keeping email read-only is safer
                    ),
                    const SizedBox(height: 20),

                    // Email Status (Custom Widget)
                    const Text(
                      "Email status",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isEmailVerified
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isEmailVerified
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isEmailVerified ? Icons.check : Icons.close,
                                  color: _isEmailVerified
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isEmailVerified ? "Verified" : "Unverified",
                                  style: TextStyle(
                                    color: _isEmailVerified
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    _buildProfileField(
                      label: "Phone number",
                      controller: _phoneController,
                      isPhone: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the text fields consistently
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    bool isReadOnly = false,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          // Auto-save when user presses "Done" on keyboard
          onFieldSubmitted: (value) => _updateUserData(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA), // Very light grey input fill
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // Rounded pills
              borderSide: BorderSide.none,
            ),
            // The suffix icon acts as a submit button visual cue
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.edit_document, // Edit icon
                color: Colors.black54,
                size: 20,
              ),
              onPressed: () {
                // If we want the icon to trigger save:
                _updateUserData();
              },
            ),
          ),
        ),
      ],
    );
  }
}
