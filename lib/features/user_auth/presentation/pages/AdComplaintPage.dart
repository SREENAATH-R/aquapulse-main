import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({Key? key}) : super(key: key);

  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late CollectionReference<Map<String, dynamic>> _complaintsCollection;

  @override
  void initState() {
    super.initState();
    _complaintsCollection = FirebaseFirestore.instance.collection('complaints');
  }

  Future<void> _refreshComplaints() async {
    // Manually trigger a data refresh
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaints',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4.0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _complaintsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No complaints available.'));
          }

          List<Map<String, dynamic>> complaints =
              snapshot.data!.docs.map((doc) {
            final data = doc.data()!;
            return {
              'username': data['username'] ?? '',
              'complaint': data['complaint'] ?? '',
              'location': data['loc'] ?? '', // Add location data
            };
          }).toList();
          return RefreshIndicator(
            onRefresh: _refreshComplaints,
            child: ListView.builder(
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      'Complaint: ${complaints[index]['complaint']}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Location: ${_formatGeoPoint(complaints[index]['location'])}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      _showFullComplaintDialog(complaints[index]);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatGeoPoint(GeoPoint geoPoint) {
    return 'Latitude: ${geoPoint.latitude}, Longitude: ${geoPoint.longitude}';
  }

  void _showFullComplaintDialog(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Complaint'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complaint: ${complaint['complaint']}'),
              const SizedBox(height: 8),
              Text('Location: ${_formatGeoPoint(complaint['loc'])}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
