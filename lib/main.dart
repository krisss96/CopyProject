import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

void main() {
  runApp(MaterialApp(home: MyMapPage()));
}

//Rivals
class Rival {
  final ll.LatLng position; // final- variable, can only be set once, cannot change
  final Color color;
  Rival({required this.position, required this.color});
}

class MyMapPage extends StatefulWidget { // StatefulWidget - widget that can change over time
  const MyMapPage({super.key});
  @override
  State<MyMapPage> createState() => _MyMapPageState(); // creates the state for this widget, which is defined in the _MyMapPageState class
}

class _MyMapPageState extends State<MyMapPage> {
  // this class holds the state of the MyMapPage widget, including the current position and the logic to update it
  // variables:

  final String _myMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#8b7474"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#e6dcdc"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2b525e"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1d3f49"}]}
]
''';

  gmaps.LatLng _toGmaps(ll.LatLng p) => gmaps.LatLng(p.latitude, p.longitude);
  bool isBattleActive = false;
  double playerProgress = 0;
  double rivalProgress = 0;
  ll.LatLng? battleStartPoint;
  Rival? currentRival;
  // ? - Nullable Type, currently can be null

  // Rivals
  final List<Rival> rivals = [
    Rival(position: const ll.LatLng(51.451333, 5.480772), color: Colors.redAccent),
    // Fontys
    Rival(position: ll.LatLng(51.430280, 5.499215), color: Colors.redAccent),
    // park
    Rival(position: ll.LatLng(51.4460, 5.4850), color: Colors.redAccent),
    // City Center
    Rival(position: const ll.LatLng(51.411092, 5.457458),
        color: Colors.purpleAccent),
    Rival(position: const ll.LatLng(51.477588, 5.493336),
        color: Colors.purpleAccent),
    // Lidl
  ];

  List<ll.LatLng> capturedPoi = []; // keeping track on captured poi
  ll.LatLng myPosition = ll.LatLng(51.4416, 5.4897); // initial position

  // POI
  final List<ll.LatLng> poi = [
    // POI; LatLng - class, represents a geographical point with latitude and longitude
    const ll.LatLng(51.4485, 5.4571),
    // Strijp-S
    const ll.LatLng(51.4411, 5.4772),
    // The Blob
    const ll.LatLng(51.4417, 5.4674),
    // Philips Stadium
    const ll.LatLng(51.416659, 5.478230),
    const ll.LatLng(51.422788, 5.499913),
    const ll.LatLng(51.435511, 5.461900),
    const ll.LatLng(51.464703, 5.473595),
    const ll.LatLng(51.426775, 5.508957),
    const ll.LatLng(51.434882, 5.513163),
  ];

  @override
  void initState() {
    // initialization method, called once when the widget is first created,
    // used to set up any necessary state or start any processes that should run when the widget is displayed
    super.initState(); // standard background setup
    // !! ALWAYS CALL SUPER.INITSTATE() FIRST !!
    _initLocation();
  }

  void _initLocation() async {
    // await _determinePosition(); // shows the request box - not using for now
    _determinePosition();
    _startTracking();
  }

  // Tracking user's location
  void _startTracking() {
    //tells the app to listen to the GPS constantly
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // temp variable for testing
        distanceFilter: 0,
        // distanceFilter: 5, // updates every 5 meters moved
      ),
    ).listen((
        Position position) { // Every time the phone moves the code runs automatically
      ll.LatLng newPoint = ll.LatLng(position.latitude,
          position.longitude); // converts new position to LatLng format

      setState(() {
        myPosition = newPoint;
      });

      // Battle logic
      if (isBattleActive && battleStartPoint != null) {
        double movedDistance = Geolocator.distanceBetween(
          battleStartPoint!.latitude, battleStartPoint!.longitude,
          newPoint.latitude, newPoint.longitude,
        );

        setState(() {
          playerProgress = movedDistance;
          rivalProgress += 3.0;
        });

        if (playerProgress >= 500) {
          endBattle(true, currentRival!);
        } else if (rivalProgress >= 500) {
          endBattle(false, currentRival!);
        }
      }

      // check every hub in the list
      for (var hub in poi) {
        if (checkIfInsideHub(newPoint,
            hub)) { // checks if the new point is within 50m of the hub
          if (!capturedPoi.contains(hub)) {
            print("You just captured a new territory!");

            setState(() {
              capturedPoi.add(hub); // save to memory
            });
          }
        }
      }

      // checks rival location for battle challenge
      for (var rival in rivals) {
        double dist = Geolocator.distanceBetween(
            newPoint.latitude, newPoint.longitude,
            rival.position.latitude, rival.position.longitude
        );

        if (dist < 100 && !isBattleActive) {
          showBattleDialog(rival);
        }
      }

      setState(() { // updates the position
        myPosition = newPoint;
      });
    });
  }

  // Check if player is within 50 meters of a POI
  bool checkIfInsideHub(ll.LatLng playerPos, ll.LatLng poiPos) {
    double distance = Geolocator
        .distanceBetween( // double - Double-Precision Floating Point - n with decimals
      // distanceBetween - calculates the distance in meters between two geographical points - the Haversine formula
      playerPos.latitude,
      playerPos.longitude,
      poiPos.latitude,
      poiPos.longitude,
    );
    return distance < 50;
  }

  Future<Position> _determinePosition() async {
    // Future - this function will return a position later
    bool serviceEnabled = await Geolocator
        .isLocationServiceEnabled(); // checks if the location services are enabled
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    // Check for permissions
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // This function is not used in the current implementation, but it can be called to get the current position once, instead of listening to a stream of updates. It checks for permissions and returns the current position if everything is in order
  void updateLocation() async {
    Position position = await _determinePosition();
    setState(() {
      myPosition = ll.LatLng(position.latitude, position.longitude);
    });
  }

  // Battle logic
  void showBattleDialog(Rival rival) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog( // AlertDialog - a pop-up dialog box that can display information and actions to the user
            title: Text("Enemy Territory!"),
            content: Text(
                "This area belongs to the ${rival.color == Colors.redAccent
                    ? 'Red'
                    : 'Purple'} Rival. Challenge them to a territory battle?"),

            actions: [ // list of buttons
              TextButton(onPressed: () => Navigator.pop(context),
                  // onPressed: () => ... - one line function
                  child: Text("Dismiss")),
              ElevatedButton( // ElevatedButton - a button with a background color, used for primary actions
                onPressed: () {
                  // onPressed: () { ... } - multi-line action
                  Navigator.pop(context); // closes the dialog
                  startBattle(rival);
                },
                child: Text("START BATTLE!"),
              ),
            ],
          ),
    );
  }

  // Battle state
  void startBattle(Rival rival) {
    setState(() {
      isBattleActive = true;
      currentRival = rival;
      playerProgress = 0;
      rivalProgress = 0;
      battleStartPoint = myPosition;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Battle started! Walk 500 meters to win!"),
          duration: Duration(seconds: 2)),
    );
  }

  //End battle
  void endBattle(bool playerWon, Rival rival) {
    setState(() {
      isBattleActive = false;
    });

    if (playerWon) {
      setState(() {
        capturedPoi.add(rival.position);
        rivals.remove(rival);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Congratulations! You conquered new territory"),
            duration: Duration(seconds: 3)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You lost the battle"),
            duration: Duration(seconds: 3)),
      );
    }

    playerProgress = 0;
    rivalProgress = 0;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: gmaps.GoogleMap(
      style: _myMapStyle,
      initialCameraPosition: gmaps.CameraPosition(
        target: _toGmaps(myPosition),
        zoom: 14.0,
      ),
      myLocationEnabled: true,
      onMapCreated: (controller) {},

      // PRESERVED MARKER LOGIC: User, POIs, and Rivals
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('player'),
          position: _toGmaps(myPosition),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),

        ...poi.map((p) => gmaps.Marker(
              markerId: gmaps.MarkerId('poi_${p.latitude}_${p.longitude}'),
              position: _toGmaps(p),
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueOrange,
              ),
            )),

        ...rivals.map((r) => gmaps.Marker(
              markerId: gmaps.MarkerId(
                'rival_${r.position.latitude}_${r.position.longitude}',
              ),
              position: _toGmaps(r.position),
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueRed,
              ),
            )),
      },

      // PRESERVED TERRITORY LOGIC: Circles for you and rivals
      circles: {
        ...capturedPoi.map((pos) => gmaps.Circle(
              circleId: gmaps.CircleId('captured_${pos.latitude}_${pos.longitude}'),
              center: _toGmaps(pos),
              radius: 350,
              fillColor: Colors.blueAccent.withValues(alpha: 0.3),
              strokeWidth: 2,
              strokeColor: Colors.blueAccent,
            )),

        ...rivals.map((r) => gmaps.Circle(
              circleId: gmaps.CircleId(
                'rival_territory_${r.position.latitude}_${r.position.longitude}',
              ),
              center: _toGmaps(r.position),
              radius: 350,
              fillColor: r.color.withValues(alpha: 0.2),
              strokeWidth: 2,
              strokeColor: r.color,
            )),
      },
    ),
  );
}
}