import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AnnouncementPage(),
    );
  }
}

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _fetchAnnouncements();
  }
Future<List<Announcement>> _fetchAnnouncements() async {
  try {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('announcement')
        .get();

    List<Announcement> announcements = querySnapshot.docs.map((doc) {
      String announcement = doc['announcement'];
      String location = doc['location'];

      return Announcement(announcement, location);
    }).toList();

    return announcements;
  } catch (e) {
    print('Error fetching announcements: $e');
    return [];
  }
}


  Future<String> _fetchUserLocation() async {
    User? user = FirebaseAuth.instance.currentUser; // Changed 'var' to 'User?' for explicit typing
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Changed to 'user.uid' for the document ID
          .get();

      return userData['location'];
    } else {
      return 'Default Location'; // Provide a default location if user is not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.blue,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add your notification icon tap logic here
              // For example, you can show a notification popup or navigate to a notification page.
            },
          ),
        ],
        elevation: 5.0,
        backgroundColor: Colors.white,
        shadowColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            "assets/image01.jpg",
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Content
          Center(
            child: FutureBuilder<List<Announcement>>(
              future: _announcementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No announcements available.'),
                  );
                } else {
                  List<Announcement> announcements = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: announcements.map((announcement) {
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            Card(
                              elevation: 10.0,
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      announcement.title,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      announcement.details,
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Announcement {
  final String title;
  final String details;

  Announcement(this.title, this.details);
}
