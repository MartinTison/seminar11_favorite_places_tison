import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../models/place.dart';

class UserPlacesNotifier extends Notifier<List<Place>> {
  Future<void>? _loadingFuture;

  @override
  List<Place> build() {
    return [];
  }

  // Načítame uložené miesta z databázy.
  Future<void> loadPlaces() {
    return _loadingFuture ??= _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final db = await PlacesDatabase.getDatabase();
      final data = await db.query('user_places');

      final appPlaces = data.map((row) {
        return Place(
          id: row['id'] as String,
          title: row['title'] as String,
          image: File(row['image'] as String),
          location: PlaceLocation(
            latitude: (row['lat'] as num).toDouble(),
            longitude: (row['lng'] as num).toDouble(),
            address: row['address'] as String,
          ),
        );
      }).toList();

      state = appPlaces;
    } catch (error) {
      debugPrint('Nepodarilo sa načítať uložené miesta: $error');
    }
  }

  // Uložíme fotografiu aj údaje o novom mieste.
  Future<void> addPlace(
    String title,
    File image,
    PlaceLocation location,
  ) async {
    // Počkáme na načítanie existujúcich miest.
    await loadPlaces();

    final appDir = await getApplicationDocumentsDirectory();

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${path.extension(image.path)}';

    final savedImage = await image.copy(path.join(appDir.path, fileName));

    final newPlace = Place(title: title, image: savedImage, location: location);

    final db = await PlacesDatabase.getDatabase();

    await db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': savedImage.path,
      'lat': location.latitude,
      'lng': location.longitude,
      'address': location.address,
    });

    state = [newPlace, ...state];
  }
}

final userPlacesProvider = NotifierProvider<UserPlacesNotifier, List<Place>>(
  UserPlacesNotifier.new,
);
