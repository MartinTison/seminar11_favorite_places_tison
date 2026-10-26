import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import '../models/place.dart';
import '../screens/map_screen.dart';

const googleApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

class LocationInput extends StatefulWidget {
  const LocationInput({super.key, required this.onSelectLocation});

  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  PlaceLocation? pickedLocation;
  bool isGettingLocation = false;

  // Vytvoríme URL mapového obrázka podľa GPS súradníc.
  String get locationImage {
    if (pickedLocation == null) {
      return '';
    }

    final lat = pickedLocation!.latitude;
    final lng = pickedLocation!.longitude;

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=16&size=600x300&maptype=roadmap'
        '&markers=color:red%7Clabel:A%7C$lat,$lng'
        '&key=$googleApiKey';
  }

  // Získame aktuálnu polohu zariadenia.
  Future<void> _getCurrentLocation() async {
    final location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();

      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (permissionGranted != PermissionStatus.granted) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isGettingLocation = true;
    });

    try {
      final locationData = await location.getLocation();

      final lat = locationData.latitude;
      final lng = locationData.longitude;

      await _getAddress(lat, lng);
    } catch (error) {
      debugPrint('Nepodarilo sa získať polohu: $error');
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // Otvoríme mapu a prevezmeme vybrané súradnice.
  Future<void> _selectOnMap() async {
    final selectedPosition = await Navigator.of(context)
        .push<LatLng>(MaterialPageRoute(builder: (ctx) => const MapScreen()));

    if (selectedPosition == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isGettingLocation = true;
    });

    try {
      await _getAddress(selectedPosition.latitude, selectedPosition.longitude);
    } catch (error) {
      debugPrint('Nepodarilo sa získať adresu: $error');
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // Prevedieme súradnice na adresu a uložíme vybranú polohu.
  Future<void> _getAddress(double lat, double lng) async {
    if (googleApiKey.isEmpty) {
      debugPrint('Google Maps API kľúč nie je nastavený.');
      return;
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': googleApiKey,
    });

    final response = await http.get(url);

    if (response.statusCode != 200) {
      debugPrint('HTTP chyba: ${response.statusCode}');
      return;
    }

    final resData = jsonDecode(response.body);

    if (resData['status'] != 'OK' ||
        resData['results'] is! List ||
        (resData['results'] as List).isEmpty) {
      debugPrint('Geocoding API: ${resData['status']}');
      return;
    }

    final String address = resData['results'][0]['formatted_address'];

    final userLocation = PlaceLocation(
      latitude: lat,
      longitude: lng,
      address: address,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      pickedLocation = userLocation;
    });

    // Odovzdáme polohu obrazovke Add New Place.
    widget.onSelectLocation(userLocation);

    debugPrint('Latitude: $lat, Longitude: $lng');
    debugPrint('Address: $address');
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = Text(
      'No location chosen.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.onSurface),
    );

    if (isGettingLocation) {
      previewContent = const CircularProgressIndicator();
    } else if (pickedLocation != null) {
      previewContent = Image.network(
        locationImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Text('Map preview could not be loaded.'));
        },
      );
    }

    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.2),
            ),
          ),
          child: previewContent,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: isGettingLocation ? null : _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
            ),
            TextButton.icon(
              onPressed: isGettingLocation ? null : _selectOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
            ),
          ],
        ),
      ],
    );
  }
}
