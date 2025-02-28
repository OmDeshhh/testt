import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController certificationsController = TextEditingController();
  String location = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      location = "${position.latitude}, ${position.longitude}";
    });
  }

  Future<void> submitDetails() async {
    await FirebaseFirestore.instance.collection("users").doc(widget.userId).update({
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "specialization": specializationController.text.trim(),
      "certifications": certificationsController.text.trim(),
      "location": location,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Details submitted. Waiting for admin approval.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: specializationController, decoration: const InputDecoration(labelText: "Specialization")),
            TextField(controller: certificationsController, decoration: const InputDecoration(labelText: "Certifications")),
            const SizedBox(height: 20),
            Text("Location: $location"),
            ElevatedButton(onPressed: submitDetails, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}
