import 'package:flutter/material.dart';
import 'package:flutter_google_maps/flutter_google_maps.dart';
import 'package:hawk_fab_menu/hawk_fab_menu.dart';
import 'package:location/location.dart';
import 'constraints.dart';

void main() {
  GoogleMap.init('AIzaSyCcPspDHrDaZS3UfOWWmq59cKsvV2Hye0k');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final key = GlobalKey<GoogleMapStateBase>();
  bool _polygonAdded = false;
  bool _darkMapStyle = false;
  String _mapStyle;
  double latitude;
  double longitude;

  Future getLocation() async {
    try {
      var userLocation = await Location().getLocation();
      setState(() {
        longitude = userLocation.longitude;
        latitude = userLocation.latitude;
      });
    } on Exception catch (e) {
      print('Could not get location: ${e.toString()}');
    }
  }

  @override
  void initState() {
    getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: _drawer(),
        appBar: AppBar(
          title: Text('Google Map Demo'),
        ),
        body: HawkFabMenu(
          items: [
            HawkFabMenuItem(
              label: 'Add Polygon',
              ontap: () {
                if (!_polygonAdded) {
                  GoogleMap.of(key).addPolygon(
                    '1',
                    polygon,
                    onTap: (polygonId) async {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(
                            'This dialog was opened by tapping on the polygon!\n'
                            'Polygon ID is $polygonId',
                          ),
                          actions: <Widget>[
                            FlatButton(
                              onPressed: Navigator.of(context).pop,
                              child: Text('CLOSE'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  GoogleMap.of(key).editPolygon(
                    '1',
                    polygon,
                    fillColor: Colors.purple,
                    strokeColor: Colors.purple,
                  );
                }

                setState(() => _polygonAdded = true);
              },
              icon: Icon(
                Icons.crop_square,
              ),
            ),
            HawkFabMenuItem(
              label: 'Info Demo',
              ontap: () {
                GoogleMap.of(key).addMarkerRaw(
                  GeoCoord(latitude, longitude),
                  info: 'test info',
                  onInfoWindowTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Palace Info..."),
                        content:
                            Text('Latitude:$latitude\nLongitude:$longitude'),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: Navigator.of(context).pop,
                            child: Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                );

                GoogleMap.of(key).addMarkerRaw(
                  GeoCoord(33.775513, -117.450257),
                  icon: 'assets/images/map-marker-warehouse.png',
                  info: contentString,
                );
              },
              icon: Icon(Icons.pin_drop),
            ),
            HawkFabMenuItem(
              label: 'Directions',
              ontap: () {
                GoogleMap.of(key).addDirection(
                  'San Francisco, CA',
                  'San Jose, CA',
                  startLabel: '1',
                  startInfo: 'San Francisco, CA',
                  endIcon:
                      'https://cdn0.iconfinder.com/data/icons/map-markers-2-1/512/xxx018-512.png',
                  endInfo: 'San Jose, CA',
                );
              },
              icon: Icon(Icons.directions),
            ),
          ],
          body: (latitude == null && longitude == null)
              ? Padding(
                  padding: const EdgeInsets.only(top: 100, left: 180),
                  child: Text(
                    "Loading...",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : Stack(
                  children: <Widget>[
                    GoogleMap(
                      key: key,
                      markers: {
                        Marker(
                          GeoCoord(latitude, longitude),
                        ),
                      },
                      initialZoom: 12,
                      initialPosition: GeoCoord(latitude, longitude),
                      mapType: _mapType == null ? MapType.roadmap : _mapType,
                      mapStyle: _mapStyle,
                      interactive: true,
                      onTap: (geo) {
                        setState(() {
                          longitude = geo.longitude;
                          latitude = geo.latitude;
                        });
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(geo?.toString()),
                          duration: const Duration(seconds: 2),
                        ));
                        GoogleMap.of(key)
                            .addMarkerRaw(GeoCoord(latitude, longitude));
                        polygon.add(GeoCoord(latitude, longitude));
                        print(polygon.length);
                      },
                      mobilePreferences: const MobileMapPreferences(
                          trafficEnabled: true, zoomControlsEnabled: false),
                      webPreferences: WebMapPreferences(
                        fullscreenControl: true,
                        zoomControl: true,
                      ),
                    ),
                    Positioned(
                        top: 15,
                        right: 20,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: Text("Map Style"),
                                    content: Container(
                                      height: mapType.length * 64.0,
                                      width: 100,
                                      child: ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return Card(
                                            child: ListTile(
                                              title: Text(mapTypeName[index]),
                                              onTap: () {
                                                setState(() {
                                                  _mapType = mapType[index];
                                                });
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          );
                                        },
                                        itemCount: mapType.length,
                                      ),
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("CANCEL"),
                                      )
                                    ],
                                  );
                                });
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.filter_none,
                              color: Colors.blue,
                            ),
                          ),
                        ))
                  ],
                ),
        ));
  }

  Widget _drawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            height: 100,
            color: Colors.green,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 60),
              child: Text(
                "Maps Demo in Flutter",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 25),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.wb_sunny,
              color: _darkMapStyle ? Colors.deepOrange : Colors.black,
            ),
            onTap: () {
              Navigator.of(context).pop();
              if (_darkMapStyle) {
                GoogleMap.of(key).changeMapStyle(null);
                _mapStyle = null;
              } else {
                GoogleMap.of(key).changeMapStyle(darkMapStyle);
                _mapStyle = darkMapStyle;
              }

              setState(() => _darkMapStyle = !_darkMapStyle);
            },
            title:
                Text(_darkMapStyle ? "Enable Light Mode" : "Enable Dark Mode"),
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            title: Text("Move camera bound"),
            leading: Icon(
              Icons.camera_enhance,
              color: Colors.red,
            ),
            onTap: () {
              Navigator.of(context).pop();
              final bounds = GeoCoordBounds(
                northeast: GeoCoord(34.021307, -117.432317),
                southwest: GeoCoord(33.835745, -117.712785),
              );
              GoogleMap.of(key).moveCameraBounds(bounds);
              GoogleMap.of(key).addMarkerRaw(
                GeoCoord(
                  (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                  (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                ),
                onTap: (markerId) async {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(
                        'This dialog was opened by tapping on the marker!\n'
                        'Marker ID is $markerId',
                      ),
                      actions: <Widget>[
                        FlatButton(
                          onPressed: Navigator.of(context).pop,
                          child: Text('CLOSE'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            title: Text("Clear Polygons"),
            leading: Icon(
              Icons.crop_square,
              color: Colors.blue,
            ),
            onTap: () {
              GoogleMap.of(key).clearPolygons();
              Navigator.of(context).pop();
              setState(() {
                polygon = [];
                _polygonAdded = false;
              });
            },
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            title: Text("Clear Markers"),
            leading: Icon(
              Icons.location_off,
              color: Colors.green,
            ),
            onTap: () {
              GoogleMap.of(key).clearMarkers();
              Navigator.of(context).pop();
            },
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            title: Text("Clear Directions"),
            leading: Icon(
              Icons.directions,
              color: Colors.orangeAccent,
            ),
            onTap: () {
              GoogleMap.of(key).clearDirections();
              Navigator.of(context).pop();
            },
          ),
          Divider(
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

List<GeoCoord> polygon = <GeoCoord>[];

List<MapType> mapType = [
  MapType.hybrid,
  MapType.roadmap,
  MapType.satellite,
  MapType.terrain,
  MapType.none,
];
MapType _mapType = MapType.hybrid;
List<String> mapTypeName = [
  "Hybrid",
  "Roadmap",
  "Satellite",
  "Terrain",
  "None"
];
