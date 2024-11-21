import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async' show Completer, Future;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:math' as Math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Marker> markers = [];
  final Completer<BitmapDescriptor> _customIcon = Completer<BitmapDescriptor>();
  late GoogleMapController mapController;
  List<LatLng> polylinePoints = [];
  double pH = -7.0 + 14.0 * Math.Random().nextDouble();

  HomePage({super.key}) {
    _loadCustomIcon();
  }

  Future<void> _loadCustomIcon() async {
    final ByteData data = await rootBundle.load('assets/picon.png');
    final Uint8List bytes = data.buffer.asUint8List();

    final BitmapDescriptor bitmapDescriptor = BitmapDescriptor.fromBytes(bytes);

    _customIcon.complete(bitmapDescriptor);
  }

  final List<String> timeIntervals = [
    '12am to 2am',
    '2am to 4am',
    '4am to 6am',
    '6am to 8am',
    '8am to 10am',
    '10am to 12pm',
    '12pm to 2pm',
    '2pm to 4pm',
    '4pm to 6pm',
    '6pm to 8pm',
    '8pm to 10pm',
    '10pm to 12am',
    'Once in 2 days',
    'Once in 5 days',
    'Once in a week',
    'Once in 2 weeks',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Aqua Pulse',
          style: TextStyle(color: Colors.lightBlue),
        ),
        leading: Tooltip(
          message: 'Water Pressure Status',
          child: IconButton(
            icon: const Icon(Icons.timelapse),
            onPressed: () {
              // Add your action when the water pressure icon is clicked
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Profile') {
                _scaffoldKey.currentState?.openDrawer();
              } else if (value == 'Announcements') {
                Navigator.pushNamed(context, '/announcement');
              } else if (value == 'Nearby Water Resources') {
                // Handle Nearby Water Resources button click
              } else if (value == 'Complaints') {
                Navigator.pushNamed(context, '/complaint');
              } else if (value == 'Logout') {
                _signOut(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'Profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Announcements',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.yellow),
                    SizedBox(width: 8),
                    Text('Announcements'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Nearby Water Resources',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Nearby Water Resources'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Complaints',
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Complaints'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.report_problem),
            onPressed: () {
              _showComplaintDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Marker>>(
        future: _fetchMarkers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            polylinePoints = _calculatePolylinePoints(snapshot.data!);

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
                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          currentPosition.latitude, currentPosition.longitude),
                      zoom: 19.0,
                    ),
                    zoomControlsEnabled: false,
                    //markers: Set<Marker>.from(snapshot.data!),
                  );
                } else {
                  return const Center(child: Text('No data available.'));
                }
              },
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
      bottomSheet: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 1.0,
        builder: (BuildContext context, ScrollController scrollController) {
          return ListView.builder(
            controller: scrollController,
            itemCount: timeIntervals.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(timeIntervals[index]),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      drawer: ProfileDrawer(),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            _showOptionsDialog(context);
          },
          child: Text('Show Options'),
        ),
      ],
    );
  }

  List<LatLng> _calculatePolylinePoints(List<Marker> markers) {
    List<LatLng> points = [];
    for (int i = 0; i < markers.length - 1; i++) {
      Marker currentMarker = markers[i];
      Marker nextMarker = markers[i + 1];
      double distance = _calculateDistance(
        currentMarker.position.latitude,
        currentMarker.position.longitude,
        nextMarker.position.latitude,
        nextMarker.position.longitude,
      );
      // Only connect if the next marker is the nearest neighbor
      if (i == 0 ||
          distance <
              _calculateDistance(
                currentMarker.position.latitude,
                currentMarker.position.longitude,
                points.last.latitude,
                points.last.longitude,
              )) {
        points.add(currentMarker.position);
        points.add(nextMarker.position);
      }
    }
    return points;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Radius of the earth in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_degToRad(lat1)) *
            Math.cos(_degToRad(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    double distance = R * c;
    return distance;
  }

  double _degToRad(double deg) {
    return deg * (Math.pi / 180);
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Navigate to TaxDetails page
                  Navigator.pushNamed(context, '/taxDetails');
                },
                child: Text('Tax Details'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Navigate to TaxPending page
                  Navigator.pushNamed(context, '/taxPending');
                },
                child: Text('Tax Pending'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _recenterMap() async {
    try {
      Position currentPosition = await _getCurrentLocation();
      if (currentPosition != null && mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          )),
        );
      } else {
        print('Current position or mapController is null');
      }
    } catch (e) {
      print('Error recentering map: $e');
    }
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

  Future<List<Marker>> _fetchMarkers() async {
    try {
      final QuerySnapshot junctionResult =
          await _firestore.collection('junctionLocation').get();
      final QuerySnapshot tankResult =
          await _firestore.collection('storageLocation').get();
      final QuerySnapshot pipeResult =
          await _firestore.collection('outletsLocation').get();
      final List<DocumentSnapshot> junctionDocuments = junctionResult.docs;
      final List<DocumentSnapshot> tankDocuments = tankResult.docs;
      final List<DocumentSnapshot> pipeDocuments = pipeResult.docs;

      List<Marker> markers = [];

      for (var document in junctionDocuments) {
        int markerPH = -7 + Math.Random().nextInt(15); // Integer range: -7 to 7
        int markerPressure = 30 + Math.Random().nextInt(71);

        bool isOutOfRange =
            markerPH < pH - 3.0 || markerPH > pH + 3.0 || markerPressure < 30.0;

        Color markerColor = isOutOfRange ? Colors.orange : Colors.green;

        String snippetText =
            "pH: ${markerPH.toStringAsFixed(2)}, Pressure: ${markerPressure.toStringAsFixed(2)}\n${document['geopoint'].latitude},${document['geopoint'].longitude}";

        if (isOutOfRange) {
          snippetText =
              "alert !! pH: ${markerPH.toStringAsFixed(2)}\npH index problem";
        }

        markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: LatLng(
              document['geopoint'].latitude,
              document['geopoint'].longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOutOfRange
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: "junction",
              snippet: snippetText,
            ),
          ),
        );
      }
      for (var document in tankDocuments) {
        int markerPH = -7 + Math.Random().nextInt(15); // Integer range: -7 to 7
        int markerPressure = 30 + Math.Random().nextInt(71);

        bool isOutOfRange =
            markerPH < pH - 3.0 || markerPH > pH + 3.0 || markerPressure < 30.0;

        Color markerColor =
            isOutOfRange ? Colors.orange : Color.fromARGB(255, 44, 51, 237);

        String snippetText =
            "pH: ${markerPH.toStringAsFixed(2)}, Pressure: ${markerPressure.toStringAsFixed(2)}\n${document['geopoint'].latitude},${document['geopoint'].longitude}";

        if (isOutOfRange) {
          snippetText =
              "alert !! pH: ${markerPH.toStringAsFixed(2)}\npH index problem";
        }

        markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: LatLng(
              document['geopoint'].longitude,
              document['geopoint'].latitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOutOfRange
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: "Tank",
              snippet: snippetText,
            ),
          ),
        );
      }

      for (var document in pipeDocuments) {
        int markerPH = -7 + Math.Random().nextInt(15); // Integer range: -7 to 7
        int markerPressure = 30 + Math.Random().nextInt(71);

        bool isOutOfRange =
            markerPH < pH - 3.0 || markerPH > pH + 3.0 || markerPressure < 30.0;

        Color markerColor =
            isOutOfRange ? Colors.orange : Color.fromARGB(255, 211, 255, 54);

        String snippetText =
            "pH: ${markerPH.toStringAsFixed(2)}, Pressure: ${markerPressure.toStringAsFixed(2)}\n${document['geopoint'].latitude},${document['geopoint'].longitude}";

        if (isOutOfRange) {
          snippetText =
              "alert !! pH: ${markerPH.toStringAsFixed(2)}\npH index problem";
        }

        markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: LatLng(
              document['geopoint'].latitude,
              document['geopoint'].longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOutOfRange
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: "junction",
              snippet: snippetText,
            ),
          ),
        );
      }
      for (var document in tankDocuments) {
        int markerPH = -7 + Math.Random().nextInt(15); // Integer range: -7 to 7
        int markerPressure = 30 + Math.Random().nextInt(71);

        bool isOutOfRange =
            markerPH < pH - 3.0 || markerPH > pH + 3.0 || markerPressure < 30.0;

        Color markerColor =
            isOutOfRange ? Colors.orange : Color.fromARGB(255, 44, 51, 237);

        String snippetText =
            "pH: ${markerPH.toStringAsFixed(2)}, Pressure: ${markerPressure.toStringAsFixed(2)}\n${document['geopoint'].latitude},${document['geopoint'].longitude}";

        if (isOutOfRange) {
          snippetText =
              "alert !! pH: ${markerPH.toStringAsFixed(2)}\npH index problem";
        }

        markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: LatLng(
              document['geopoint'].latitude,
              document['geopoint'].longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOutOfRange
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: "Tank",
              snippet: snippetText,
            ),
          ),
        );
      }

      for (var document in pipeDocuments) {
        int markerPH = -7 + Math.Random().nextInt(15); // Integer range: -7 to 7
        int markerPressure = 30 + Math.Random().nextInt(71);

        bool isOutOfRange =
            markerPH < pH - 3.0 || markerPH > pH + 3.0 || markerPressure < 30.0;

        Color markerColor =
            isOutOfRange ? Colors.orange : Color.fromARGB(255, 211, 255, 54);

        String snippetText =
            "pH: ${markerPH.toStringAsFixed(2)}, Pressure: ${markerPressure.toStringAsFixed(2)}\n${document['geopoint'].latitude},${document['geopoint'].longitude}";

        if (isOutOfRange) {
          snippetText =
              "alert !! pH: ${markerPH.toStringAsFixed(2)}\npH index problem";
        }

        markers.add(
          Marker(
            markerId: MarkerId(document.id),
            position: LatLng(
              document['geopoint'].latitude,
              document['geopoint'].longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOutOfRange
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: "Outlets",
              snippet: snippetText,
            ),
          ),
        );
      }

      return markers;
    } catch (e) {
      print('Error fetching markers: $e');
      return [];
    }
  }

  Future<String> _getTankLocationSnippet(GeoPoint tankLocation) async {
    try {
      // Fetch additional information from Firebase based on tankLocation
      QuerySnapshot tankInfo =
          await FirebaseFirestore.instance.collection('storageLocation').get();

      if (tankInfo.docs.isNotEmpty) {
        // Extract additional information (replace 'fieldName' with the actual field name)
        var additionalInfo = tankInfo.docs.first['fieldName'];

        // Include latitude and longitude information in the snippet
        var latitude = tankLocation.latitude;
        var longitude = tankLocation.longitude;

        // You can customize the snippet based on the retrieved information
        return 'Additional Info: $additionalInfo\nLocation: Latitude $latitude, Longitude $longitude';
      } else {
        return 'No additional information available';
      }
    } catch (e) {
      print('Error fetching tank location snippet: $e');
      return 'Error fetching location';
    }
  }

  Future<bool> fetchWaterSupplyAvailability(String timeInterval) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showComplaintDialog(BuildContext context) {
    String complaintText = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report a Complaint'),
          content: TextField(
            maxLines: 3,
            maxLength: 60,
            onChanged: (value) {
              complaintText = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter your complaint (max 60 words)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _reportComplaint(complaintText);
                Navigator.of(context).pop();
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _reportComplaint(String complaintText) async {
    try {
      Position currentPosition = await _getCurrentLocation();
      await _firestore.collection('complaints').add({
        'loc': GeoPoint(currentPosition.latitude, currentPosition.longitude),
        'complaint': complaintText,
      });
      print('Complaint reported successfully');
    } catch (e) {
      print('Error reporting complaint: $e');
    }
  }
}

class ProfileDrawer extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const CircleAvatar(
                    radius: 25.0,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Hero(
              tag: 'profileImage',
              child: CircleAvatar(
                radius: 50.0,
                backgroundImage: NetworkImage(
                  'https://example.com/new_profile_icon.jpg',
                ),
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: _firestore
                  .collection('users')
                  .where('email', isEqualTo: _auth.currentUser?.email)
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else {
                  if (snapshot.hasError) {
                    return const Text('Error loading user data');
                  } else {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.docs.isNotEmpty) {
                      var userData =
                          snapshot.data!.docs[0].data() as Map<String, dynamic>;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome, ${userData['username']}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'PAN NUMBER: ${userData['taxId']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Location: ${userData['location']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const Text('No user data found');
                    }
                  }
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  _signOut(context);
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}

class CustomInfoWindow extends StatelessWidget {
  final String title;
  final String snippet;

  CustomInfoWindow({
    required this.title,
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 177, 48, 48),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            snippet,
            style: TextStyle(fontSize: 14.0),
          ),
        ],
      ),
    );
  }
}
