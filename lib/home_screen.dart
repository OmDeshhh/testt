import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 📆 For Date Formatting
import 'profile_screen.dart'; // ✅ Profile Screen Import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String status = "Available";
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> saveAvailability() async {
    if (user == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time!")),
      );
      return;
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    String formattedTime = selectedTime!.format(context);

    await FirebaseFirestore.instance.collection("pathologists").doc(user!.uid).set({
      "availability": {
        "date": formattedDate,
        "time": formattedTime,
        "status": status,
      },
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Availability updated!")),
    );
  }

  Future<void> uploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      String fileName = file.name;

      UploadTask uploadTask = FirebaseStorage.instance
          .ref("pathologists/${user!.uid}/$fileName")
          .putData(file.bytes!);

      await uploadTask;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF Uploaded Successfully!")),
      );
    }
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: confirmLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set Availability",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 📆 Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(selectedDate == null
                  ? "Select Date"
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: pickDate,
            ),

            // ⏰ Time Picker
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(selectedTime == null
                  ? "Select Time"
                  : selectedTime!.format(context)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: pickTime,
            ),

            const SizedBox(height: 10),

            // Availability Status Dropdown
            DropdownButtonFormField<String>(
              value: status,
              items: ["Available", "Not Available"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  status = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Availability Status",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Save Availability Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveAvailability,
                child: const Text("Save Availability"),
              ),
            ),

            const SizedBox(height: 20),

            // Upload PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: uploadPDF,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Test Report (PDF)"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}