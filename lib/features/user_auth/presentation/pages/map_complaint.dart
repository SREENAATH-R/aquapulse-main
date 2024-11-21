import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapComplaintPage extends StatefulWidget {
  const MapComplaintPage({Key? key}) : super(key: key);

  @override
  _MapComplaintPageState createState() => _MapComplaintPageState();
}

class _MapComplaintPageState extends State<MapComplaintPage> {
  late GoogleMapController mapController;
  TextEditingController complaintController = TextEditingController();
  LatLng? markerLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint by Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            markers: markerLocation != null
                ? {
                    Marker(
                        markerId: MarkerId('complaint'),
                        position: markerLocation!)
                  }
                : {},
            onTap: (position) {
              _addMarker(position);
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                _openComplaintDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Complaint'),
            ),
          ),
        ],
      ),
    );
  }

  void _addMarker(LatLng position) {
    setState(() {
      markerLocation = position;
    });
  }

  void _openComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: complaintController,
                decoration: const InputDecoration(labelText: 'Complaint'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _submitComplaint();
                  Navigator.pop(context);
                },
                child: const Text('Submit Complaint'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitComplaint() {
    if (markerLocation != null && complaintController.text.isNotEmpty) {
      // Save complaint and markerLocation to Firestore or perform any other actions
      print('Complaint: ${complaintController.text}');
      print('Location: ${markerLocation.toString()}');
    } else {
      // Handle missing complaint or marker location
    }
  }
}
