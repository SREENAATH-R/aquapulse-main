import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDatabase {
  static CollectionReference announcements =
      FirebaseFirestore.instance.collection('announcement');

  static Future<void> addAnnouncement(Map<String, dynamic> newAnnouncement) async {
    await announcements.add(newAnnouncement);
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UpdateAnnouncementsPage(),
    );
  }
}

class UpdateAnnouncementsPage extends StatefulWidget {
  const UpdateAnnouncementsPage({super.key});

  @override
  _UpdateAnnouncementsPageState createState() =>
      _UpdateAnnouncementsPageState();
}

class _UpdateAnnouncementsPageState extends State<UpdateAnnouncementsPage> {
  final TextEditingController _newAnnouncementController = TextEditingController();
  late String adminLocation;

  @override
  void initState() {
    super.initState();
    fetchAdminData(); // Call to fetch admin data when the widget initializes
  }

  void fetchAdminData() async {
    var user = FirebaseAuth.instance.currentUser;
    var snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user!.email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        adminLocation = snapshot.docs.first['location'];
      });
    } else {
      setState(() {
        adminLocation = ''; // Set adminLocation to an appropriate default value
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Update Announcements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 3.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: AnnouncementDatabase.announcements.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    var announcementDocs = snapshot.data!.docs;
                    var filteredAnnouncements = announcementDocs
                        .where((doc) => doc['location'] == adminLocation)
                        .toList();

                    return ListView.builder(
                      itemCount: filteredAnnouncements.length,
                      itemBuilder: (context, index) {
                        var announcementData =
                            filteredAnnouncements[index].data() as Map<String, dynamic>;

                        return Dismissible(
                          key: Key(filteredAnnouncements[index].id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            deleteAnnouncement(filteredAnnouncements[index].id);
                          },
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.lightBlueAccent,
                            child: ListTile(
                              title: Text(
                                announcementData['announcement'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                announcementData['location'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Material(
              elevation: 3.0,
              child: TextField(
                controller: _newAnnouncementController,
                decoration: InputDecoration(
                  labelText: 'New Announcement',
                  hintText: 'Type your announcement here',
                  labelStyle: const TextStyle(color: Colors.blue),
                  hintStyle: const TextStyle(color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      sendNewAnnouncement();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendNewAnnouncement() async {
    String newAnnouncement = _newAnnouncementController.text.trim();
    if (newAnnouncement.isNotEmpty) {
      Map<String, dynamic> announcementData = {
        'announcement': newAnnouncement,
        'location': adminLocation,
      };
      await AnnouncementDatabase.addAnnouncement(announcementData);
      _newAnnouncementController.clear();
      setState(() {});
    }
  }

  void deleteAnnouncement(String announcementId) async {
    await AnnouncementDatabase.announcements.doc(announcementId).delete();
    setState(() {});
  }
}
