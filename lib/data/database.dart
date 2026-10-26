import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class PlacesDatabase {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();

    return openDatabase(
      path.join(dbPath, 'places.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE user_places('
          'id TEXT PRIMARY KEY, '
          'title TEXT, '
          'image TEXT, '
          'lat REAL, '
          'lng REAL, '
          'address TEXT'
          ')',
        );
      },
      version: 1,
    );
  }
}
