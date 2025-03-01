import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String name = "";
  String specialization = "";
  String certifications = "";
  String location = "";
  bool isEditing = false;
  bool isLoading = false;
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc["name"] ?? "Unknown";
          emailController.text = userDoc["email"] ?? user!.email!;
          phoneController.text = userDoc["phone"] ?? "";
          specialization = userDoc["specialization"] ?? "Not specified";
          certifications = userDoc["certifications"] ?? "Not specified";
          location = userDoc["location"] ?? "Not available";
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection("users").doc(user!.uid).update({
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
      });

      await user!.updateEmail(emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      setState(() {
        isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
        readOnly: true,
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        controller: controller,
        keyboardType: label == "Phone" ? TextInputType.phone : TextInputType.emailAddress,
        enabled: isEditing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                if (isEditing) {
                  _updateProfile();
                } else {
                  isEditing = true;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Profile Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildReadOnlyField("Name", name),
            _buildEditableField("Email", emailController),
            _buildEditableField("Phone", phoneController),
            _buildReadOnlyField("Specialization", specialization),
            _buildReadOnlyField("Certifications", certifications),
            _buildReadOnlyField("Location", location),

            const SizedBox(height: 20),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : isEditing
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          child: const Text("Save Changes"),
                        ),
                      )
                    : Container(), // Hide Save button when not editing
          ],
        ),
      ),
    );
  }
}
