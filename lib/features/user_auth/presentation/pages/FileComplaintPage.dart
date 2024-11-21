import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class UserProfile {
  final String email;
  final String location;

  UserProfile({
    required this.email,
    required this.location,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FileComplaintPage(),
    );
  }
}

class FileComplaintPage extends StatefulWidget {
  const FileComplaintPage({super.key});

  @override
  _FileComplaintPageState createState() => _FileComplaintPageState();
}

class _FileComplaintPageState extends State<FileComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Retrieve additional user details (location in this case) from Firestore
        DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userProfileSnapshot.exists) {
          return UserProfile(
            email: user.email ?? '',
            location: userProfileSnapshot['location'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _sendComplaint(String complaint) async {
    try {
      // Access Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get the current user profile
      UserProfile? userProfile = await getUserProfile();

      if (userProfile != null) {
        // Add a document with a generated ID
        await firestore.collection('complaints').add({
          'complaint': complaint,
          'email': userProfile.email,
          'location': userProfile.location,
        });

        // Print a success message
        print('Complaint sent successfully!');
      } else {
        // User not authenticated or profile not found
        print('User not authenticated or profile not found.');
      }
    } catch (e) {
      // Print an error message
      print('Error sending complaint: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'File Complaint Page',
          style: TextStyle(color: Colors.lightBlue),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            "assets/image02.jpg",
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 150.0,
              width: 400.0,
              child: Card(
                color: Colors.white,
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView(
                    children: [
                      TextField(
                        controller: _complaintController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        autocorrect: true,
                        inputFormatters: [
                          WordLimitAndSpaceInputFormatter(500),
                        ],
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Type your complaint here (max 500 words)',
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Access user's complaint using _complaintController.text
                          String userComplaint = _complaintController.text;
                          _sendComplaint(userComplaint);
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                // When the button is pressed, change color to green
                                return Colors.green;
                              }
                              // Otherwise, use the default color (blue)
                              return const Color.fromARGB(255, 135, 203, 234);
                            },
                          ),
                        ),
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WordLimitAndSpaceInputFormatter extends TextInputFormatter {
  final int maxWords;

  WordLimitAndSpaceInputFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Limit total words to the specified word limit
    List<String> words = newValue.text.trim().split(' ');
    if (words.length > maxWords) {
      words = words.sublist(0, maxWords);
    }

    String formattedText = words.join(' ');

    return TextEditingValue(
      text: formattedText,
      selection: newValue.selection,
    );
  }
}
