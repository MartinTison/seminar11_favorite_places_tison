import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.isSelecting = true,
    this.location = const PlaceLocation(
      latitude: 37.422,
      longitude: -122.084,
      address: '',
    ),
  });

  final bool isSelecting;
  final PlaceLocation location;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedPosition;

  // Vrátime vybrané súradnice na predchádzajúcu obrazovku.
  void _saveLocation() {
    if (_selectedPosition == null) {
      return;
    }

    Navigator.of(context).pop(_selectedPosition);
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = LatLng(
      widget.location.latitude,
      widget.location.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSelecting ? 'Pick your Location' : 'Your Location',
        ),
        actions: [
          if (widget.isSelecting)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _selectedPosition == null ? null : _saveLocation,
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 16,
        ),
        onTap: widget.isSelecting
            ? (position) {
                setState(() {
                  _selectedPosition = position;
                });
              }
            : null,
        markers: {
          if (!widget.isSelecting)
            Marker(
              markerId: const MarkerId('saved-location'),
              position: initialPosition,
            ),
          if (widget.isSelecting && _selectedPosition != null)
            Marker(
              markerId: const MarkerId('selected-location'),
              position: _selectedPosition!,
            ),
        },
      ),
    );
  }
}
