import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ComplaintPage(),
    );
  }
}

class ComplaintPage extends StatelessWidget {
  const ComplaintPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaint Page',
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
          Image.asset(
            "assets/image03.jpg",
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
              ),
              const Expanded(
                child: ComplaintList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String> _getUsername(User user) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.get('username');
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw 'Location permission denied';
    }

    return await Geolocator.getCurrentPosition();
  }
}

class ComplaintList extends StatelessWidget {
  const ComplaintList({Key? key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var complaintData = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.white,
                elevation: 4.0,
                child: ListTile(
                  title: Text('Complaint: ${complaintData['complaint']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Location: ${complaintData['loc']}'),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
