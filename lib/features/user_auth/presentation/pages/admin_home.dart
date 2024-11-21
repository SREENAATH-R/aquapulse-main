import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  List<Marker> markers = [];
  int randomValue = Random().nextInt(15) - 7;

  Map<String, Color> markerColors = {
    'storage': Colors.blue,
    'junction': Colors.green,
    'outlets': Colors.orange,
  };
  Future<void> _fetchStorageUnitLocations() async {
    try {
      // Fetch the documents from 'StorageUnitLocation' collection
      QuerySnapshot storageSnapshot =
          await _firestore.collection('StorageUnitLocation').get();

      // Loop through the documents and add markers for each location
      storageSnapshot.docs.forEach((DocumentSnapshot document) {
        // Extract latitude and longitude from the document
        double latitude = document['geopoint']['latitude'];
        double longitude = document['geopoint']['longitude'];

        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId(document.id), // Use document ID as marker ID
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed, // Set marker color
              ),
              infoWindow:
                  InfoWindow(title: 'Storage Unit', snippet: "pH : 6.1"),
            ),
          );
        });
      });

      // Fetch and display markers for 'junctionLocation' collection
      QuerySnapshot junctionSnapshot =
          await _firestore.collection('junctionLocation').get();

      junctionSnapshot.docs.forEach((DocumentSnapshot document) {
        double latitude = document['geopoint']['latitude'];
        double longitude = document['geopoint']['longitude'];

        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId(document.id),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor
                    .hueGreen, // Different marker color for junctions
              ),
              infoWindow: InfoWindow(title: 'Junction', snippet: "pH : 4.2"),
            ),
          );
        });
      });

      // Fetch and display markers for 'outletsLocation' collectionq
      QuerySnapshot outletsSnapshot =
          await _firestore.collection('outletsLocation').get();

      outletsSnapshot.docs.forEach((DocumentSnapshot document) {
        double latitude = document['geopoint']['latitude'];
        double longitude = document['geopoint']['longitude'];

        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId(document.id),
              position: LatLng(latitude, longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor
                    .hueOrange, // Different marker color for outlets
              ),
              infoWindow: InfoWindow(title: 'Outlet', snippet: "pH : 3.7"),
            ),
          );
        });
      });
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStorageUnitLocations(); // Fetch and display all locations on init
  }

  // Function to add the current location to Firebase and mark it on the map
  Future<void> _addCurrentLocation(String option) async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      Position position = await Geolocator.getCurrentPosition();

      // Add the current location to the Firebase collection
      await _firestore.collection('${option}Location').add({
        'geopoint': GeoPoint(position.latitude, position.longitude),
      });

      // Mark the current location on the map
      setState(() {
        markers.add(
          Marker(
            markerId: MarkerId(option),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow:
                InfoWindow(title: option, snippet: "${randomValue}, 2000"),
          ),
        );
      });

      print('Location stored for $option');
    } catch (e) {
      print('Error storing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _addCurrentLocation(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'storage',
                  child: Text('Storage Units'),
                ),
                const PopupMenuItem<String>(
                  value: 'junction',
                  child: Text('Junction'),
                ),
                const PopupMenuItem<String>(
                  value: 'outlets',
                  child: Text('Outlets'),
                ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('admin')
            .where('email', isEqualTo: _auth.currentUser!.email)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Admin details not found.'));
          } else {
            LatLng initialLocation = LatLng(10, 78);

            return FutureBuilder<Position>(
              future: _getCurrentLocation(),
              builder: (context, positionSnapshot) {
                if (positionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (positionSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${positionSnapshot.error}'));
                } else if (positionSnapshot.hasData) {
                  Position currentPosition = positionSnapshot.data!;
                  initialLocation = LatLng(
                      currentPosition.latitude, currentPosition.longitude);

                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                    },
                    initialCameraPosition: CameraPosition(
                      target: initialLocation,
                      zoom: 13,
                    ),
                    markers: Set<Marker>.from(markers),
                    polylines: _createPolylines(),
                  );
                } else {
                  return const Center(child: Text('No data available.'));
                }
              },
            );
          }
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.blue),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _firestore
                    .collection('admin')
                    .where('email', isEqualTo: _auth.currentUser!.email)
                    .get()
                    .then((snapshot) {
                  if (snapshot.docs.isNotEmpty) {
                    var adminData = snapshot.docs.first.data();
                    Navigator.of(context).push(_profilePageRoute(adminData));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin details not found.')),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text('Update Announcement'),
              onTap: () {
                // Handle update announcement item click
                Navigator.pop(context);
                Navigator.pushNamed(context, '/updateAnnouncements');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.blue),
              title: const Text('Complaints'),
              onTap: () {
                // Handle complaints item click
                Navigator.pop(context);
                Navigator.pushNamed(
                    context, '/complaints'); // Navigate to ComplaintsPage
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.blue),
              title: const Text('Logout'),
              onTap: () {
                // Handle logout item click
                _auth.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};

    List<LatLng> allMarkerLocations = [];
    for (var marker in markers) {
      LatLng position = marker.position;
      allMarkerLocations.add(position);
    }

    // Create a single polyline connecting all marker positions
    if (allMarkerLocations.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('allMarkers'),
        points: allMarkerLocations,
        color: Colors.red, // Change the color as needed
        width: 3,
      ));
    }

    return polylines;
  }

  Future<Position> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      rethrow;
    }
  }

  Route _profilePageRoute(Map<String, dynamic> adminData) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ProfilePage(adminData),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset(0.0, 0.0);
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> adminData;

  const ProfilePage(this.adminData, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 300,
                      child: Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                  adminData['profileImageUrl'] ?? ''),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'ADMIN',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(height: 10),
                            buildDetailRow('Name', adminData['name']),
                            buildDetailRow('Email', adminData['email']),
                            buildDetailRow('Phone', adminData['ph_no']),
                            buildDetailRow('Location', adminData['location']),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.blue)),
          Text(
            value?.toString() ?? '',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Page"),
      ),
      body: Stack(
        children: [
          // Your existing map code goes here

          // ...

          // Buttons for adding elements
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // Add Water Tank logic
                    // ...
                  },
                  heroTag: 'addWaterTank',
                  tooltip: 'Add Water Tank',
                  child: const Icon(
                      Icons.local_drink), // Change the icon to a water tank
                ),
                const SizedBox(height: 16.0),
                FloatingActionButton(
                  onPressed: () {
                    // Add Pipeline Junction logic
                    // ...
                  },
                  heroTag: 'addPipelineJunction',
                  tooltip: 'Add Pipeline Junction',
                  child: const Icon(Icons.settings_input_component),
                ),
                const SizedBox(height: 16.0),
                FloatingActionButton(
                  onPressed: () {
                    // Add Pipeline logic
                    // ...
                  },
                  heroTag: 'addPipeline',
                  tooltip: 'Add Pipeline',
                  child: const Icon(Icons.timeline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
