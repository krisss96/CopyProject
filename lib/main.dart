import 'package:flutter/material.dart'; // basic flutter widgets
import 'package:flutter_map/flutter_map.dart'; // map widget
import 'package:latlong2/latlong.dart'; // helps map understand coordinates
import 'package:geolocator/geolocator.dart'; // GPS functionality

void main() {
  runApp(MaterialApp(home: MyMapPage()));
}
class MyMapPage extends StatefulWidget { // StatefulWidget - widget that can change over time
  const MyMapPage({super.key});

  @override
  State<MyMapPage> createState() => _MyMapPageState(); // creates the state for this widget, which is defined in the _MyMapPageState class
}

class _MyMapPageState extends State<MyMapPage> { // this class holds the state of the MyMapPage widget, including the current position and the logic to update it
  LatLng myPosition = LatLng(51.4416, 5.4897); // initial position

  @override
  void initState() { // auto-start
    super.initState();
    _startTracking(); // start the automatic GPS stream
  }

  void _startTracking() { //tells the app to listen to the GPS constantly
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // updates every 5 meters moved
      ),
    ).listen((Position position) { // Every time the phone moves the code runs automatically
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<Position> _determinePosition() async {// Future - this function will return a position later
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void updateLocation() async {
    Position position = await _determinePosition();
    setState(() {
      myPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override // build method describes how to display the widget
  Widget build(BuildContext context) { // this method is called every time the state changes, and it rebuilds the UI with the new state
    return Scaffold(
      body: FlutterMap( // main map widget
        options: const MapOptions( // map options
          initialCenter: LatLng(51.4416, 5.4697), // center of Eindhoven
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: myPosition,
                child: const Icon( // styling of icon
                  Icons.location_history,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}