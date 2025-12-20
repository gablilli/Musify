/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:hive/hive.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';

/// Service to track and calculate listening statistics for Musify Wrapped
class ListeningStatsService {
  ListeningStatsService._();

  static final ListeningStatsService _instance = ListeningStatsService._();
  static ListeningStatsService get instance => _instance;

  /// Records a play event for a song
  /// This should be called when a song starts playing
  Future<void> recordPlay({
    required String ytid,
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    try {
      final year = DateTime.now().year;
      final statsBox = await _openStatsBox();

      // Get or create song stats
      final songKey = 'song_${year}_$ytid';
      final existingData = statsBox.get(songKey, defaultValue: <String, dynamic>{});
      final songData = Map<String, dynamic>.from(existingData);

      songData['ytid'] = ytid;
      songData['title'] = title;
      songData['artist'] = artist;
      songData['playCount'] = (songData['playCount'] ?? 0) + 1;
      songData['lastPlayed'] = DateTime.now().millisecondsSinceEpoch;
      if (durationSeconds != null) {
        songData['totalSeconds'] = (songData['totalSeconds'] ?? 0) + durationSeconds;
      }

      await statsBox.put(songKey, songData);

      // Update artist stats
      final artistKey = 'artist_${year}_${artist.toLowerCase().trim()}';
      final existingArtistData = statsBox.get(artistKey, defaultValue: <String, dynamic>{});
      final artistData = Map<String, dynamic>.from(existingArtistData);

      artistData['artist'] = artist;
      artistData['playCount'] = (artistData['playCount'] ?? 0) + 1;
      if (durationSeconds != null) {
        artistData['totalSeconds'] = (artistData['totalSeconds'] ?? 0) + durationSeconds;
      }

      await statsBox.put(artistKey, artistData);

      // Update total minutes for the year
      final totalKey = 'total_$year';
      final totalSeconds = statsBox.get(totalKey, defaultValue: 0) as int;
      await statsBox.put(totalKey, totalSeconds + (durationSeconds ?? 0));

    } catch (e, stackTrace) {
      logger.log('Error recording play stats', e, stackTrace);
    }
  }

  /// Gets the Wrapped summary for a specific year
  Future<WrappedStats> getWrappedStats(int year) async {
    try {
      final statsBox = await _openStatsBox();

      // Collect all song stats for the year
      final songs = <Map<String, dynamic>>[];
      final artists = <Map<String, dynamic>>[];

      for (final key in statsBox.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('song_${year}_')) {
          final data = statsBox.get(key);
          if (data != null) {
            songs.add(Map<String, dynamic>.from(data));
          }
        } else if (keyStr.startsWith('artist_${year}_')) {
          final data = statsBox.get(key);
          if (data != null) {
            artists.add(Map<String, dynamic>.from(data));
          }
        }
      }

      // Sort songs by play count
      songs.sort((a, b) => (b['playCount'] ?? 0).compareTo(a['playCount'] ?? 0));

      // Sort artists by play count
      artists.sort((a, b) => (b['playCount'] ?? 0).compareTo(a['playCount'] ?? 0));

      // Get total listening time
      final totalSeconds = statsBox.get('total_$year', defaultValue: 0) as int;
      final totalMinutes = totalSeconds ~/ 60;

      return WrappedStats(
        year: year,
        totalMinutes: totalMinutes,
        totalSongsPlayed: songs.fold(0, (sum, s) => sum + ((s['playCount'] ?? 0) as int)),
        topSongs: songs.take(10).toList(),
        topArtists: artists.take(10).toList(),
        uniqueSongsCount: songs.length,
        uniqueArtistsCount: artists.length,
      );
    } catch (e, stackTrace) {
      logger.log('Error getting wrapped stats', e, stackTrace);
      return WrappedStats.empty(year);
    }
  }

  /// Checks if there is enough data for a meaningful Wrapped
  Future<bool> hasEnoughData(int year) async {
    try {
      final stats = await getWrappedStats(year);
      return stats.totalMinutes >= 60; // At least 1 hour of listening
    } catch (e) {
      return false;
    }
  }

  Future<Box> _openStatsBox() async {
    const boxName = 'listeningStats';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName);
  }
}

/// Data class for Wrapped statistics
class WrappedStats {
  final int year;
  final int totalMinutes;
  final int totalSongsPlayed;
  final List<Map<String, dynamic>> topSongs;
  final List<Map<String, dynamic>> topArtists;
  final int uniqueSongsCount;
  final int uniqueArtistsCount;

  WrappedStats({
    required this.year,
    required this.totalMinutes,
    required this.totalSongsPlayed,
    required this.topSongs,
    required this.topArtists,
    required this.uniqueSongsCount,
    required this.uniqueArtistsCount,
  });

  factory WrappedStats.empty(int year) => WrappedStats(
        year: year,
        totalMinutes: 0,
        totalSongsPlayed: 0,
        topSongs: [],
        topArtists: [],
        uniqueSongsCount: 0,
        uniqueArtistsCount: 0,
      );

  bool get isEmpty => totalMinutes == 0 && totalSongsPlayed == 0;

  /// Gets formatted total listening time as a string (e.g., "5h 30m")
  String get formattedListeningTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
