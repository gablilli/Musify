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

/// Flag to enable fake data mode for testing the wrapped feature.
/// Set this to true to test the wrapped UI with mock data.
/// 
/// ⚠️ WARNING: This is set to TRUE for testing purposes.
/// MUST be set to FALSE before merging to main or creating production builds!
/// 
/// For production: const bool useWrappedTestData = false;
const bool useWrappedTestData = true;

/// Service for tracking listening statistics on-device
/// All data remains local and is never sent to any server
class ListeningStatsService {
  ListeningStatsService._();

  static final ListeningStatsService _instance = ListeningStatsService._();
  static ListeningStatsService get instance => _instance;

  static const String _statsBoxName = 'listeningStats';

  /// Track a song play
  Future<void> trackSongPlay({
    required String songId,
    required String songTitle,
    required String? artist,
    required String? thumbnailUrl,
    required int durationInSeconds,
  }) async {
    try {
      final box = await _openBox();
      final year = DateTime.now().year;
      final month = DateTime.now().month;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get or create yearly stats
      final yearlyStats = Map<String, dynamic>.from(
        box.get('yearlyStats_$year', defaultValue: <String, dynamic>{}),
      );

      // Update total listening time
      yearlyStats['totalListeningSeconds'] =
          (yearlyStats['totalListeningSeconds'] ?? 0) + durationInSeconds;

      // Update total songs played
      yearlyStats['totalSongsPlayed'] =
          (yearlyStats['totalSongsPlayed'] ?? 0) + 1;

      // Update song play counts
      final songPlays = Map<String, dynamic>.from(
        yearlyStats['songPlays'] ?? <String, dynamic>{},
      );
      if (songPlays.containsKey(songId)) {
        songPlays[songId]['playCount'] =
            (songPlays[songId]['playCount'] ?? 0) + 1;
        songPlays[songId]['lastPlayed'] = timestamp;
      } else {
        songPlays[songId] = {
          'songId': songId,
          'title': songTitle,
          'artist': artist,
          'thumbnailUrl': thumbnailUrl,
          'playCount': 1,
          'firstPlayed': timestamp,
          'lastPlayed': timestamp,
        };
      }
      yearlyStats['songPlays'] = songPlays;

      // Update artist play counts
      if (artist != null && artist.isNotEmpty) {
        final artistPlays = Map<String, dynamic>.from(
          yearlyStats['artistPlays'] ?? <String, dynamic>{},
        );
        final artistKey = artist.toLowerCase().trim();
        if (artistPlays.containsKey(artistKey)) {
          artistPlays[artistKey]['playCount'] =
              (artistPlays[artistKey]['playCount'] ?? 0) + 1;
          artistPlays[artistKey]['totalSeconds'] =
              (artistPlays[artistKey]['totalSeconds'] ?? 0) + durationInSeconds;
        } else {
          artistPlays[artistKey] = {
            'artist': artist,
            'playCount': 1,
            'totalSeconds': durationInSeconds,
          };
        }
        yearlyStats['artistPlays'] = artistPlays;
      }

      // Update monthly breakdown
      final monthlyBreakdown = Map<String, dynamic>.from(
        yearlyStats['monthlyBreakdown'] ?? <String, dynamic>{},
      );
      final monthKey = month.toString();
      monthlyBreakdown[monthKey] = {
        'songsPlayed': (monthlyBreakdown[monthKey]?['songsPlayed'] ?? 0) + 1,
        'listeningSeconds':
            (monthlyBreakdown[monthKey]?['listeningSeconds'] ?? 0) +
            durationInSeconds,
      };
      yearlyStats['monthlyBreakdown'] = monthlyBreakdown;

      // Save updated stats
      await box.put('yearlyStats_$year', yearlyStats);
    } catch (e, stackTrace) {
      logger.log('Error tracking song play', e, stackTrace);
    }
  }

  /// Get wrapped stats for a specific year
  Future<WrappedStats?> getWrappedStats(int year) async {
    // Return fake data for testing if the flag is enabled
    if (useWrappedTestData) {
      return _generateFakeWrappedStats(year);
    }

    try {
      final box = await _openBox();
      final yearlyStats = Map<String, dynamic>.from(
        box.get('yearlyStats_$year', defaultValue: <String, dynamic>{}),
      );

      if (yearlyStats.isEmpty) {
        return null;
      }

      // Parse song plays
      final songPlays = Map<String, dynamic>.from(
        yearlyStats['songPlays'] ?? <String, dynamic>{},
      );
      final topSongs =
          songPlays.entries.map((e) {
            return SongStat(
              songId: e.value['songId'] ?? e.key,
              title: e.value['title'] ?? 'Unknown',
              artist: e.value['artist'],
              thumbnailUrl: e.value['thumbnailUrl'],
              playCount: e.value['playCount'] ?? 0,
            );
          }).toList()
            ..sort((a, b) => b.playCount.compareTo(a.playCount));

      // Parse artist plays
      final artistPlays = Map<String, dynamic>.from(
        yearlyStats['artistPlays'] ?? <String, dynamic>{},
      );
      final topArtists =
          artistPlays.entries.map((e) {
            return ArtistStat(
              artist: e.value['artist'] ?? 'Unknown',
              playCount: e.value['playCount'] ?? 0,
              totalSeconds: e.value['totalSeconds'] ?? 0,
            );
          }).toList()
            ..sort((a, b) => b.playCount.compareTo(a.playCount));

      // Parse monthly breakdown
      final monthlyBreakdown = Map<String, dynamic>.from(
        yearlyStats['monthlyBreakdown'] ?? <String, dynamic>{},
      );
      var topMonth = 0;
      var topMonthMinutes = 0;
      for (final entry in monthlyBreakdown.entries) {
        final minutes =
            ((entry.value['listeningSeconds'] ?? 0) as int) ~/ 60;
        if (minutes > topMonthMinutes) {
          topMonthMinutes = minutes;
          topMonth = int.tryParse(entry.key) ?? 0;
        }
      }

      return WrappedStats(
        year: year,
        totalListeningMinutes:
            (yearlyStats['totalListeningSeconds'] ?? 0) ~/ 60,
        totalSongsPlayed: yearlyStats['totalSongsPlayed'] ?? 0,
        topSongs: topSongs.take(10).toList(),
        topArtists: topArtists.take(10).toList(),
        topMonth: topMonth,
        topMonthMinutes: topMonthMinutes,
        uniqueSongsPlayed: songPlays.length,
        uniqueArtistsPlayed: artistPlays.length,
      );
    } catch (e, stackTrace) {
      logger.log('Error getting wrapped stats', e, stackTrace);
      return null;
    }
  }

  /// Check if there are stats available for a specific year
  Future<bool> hasStatsForYear(int year) async {
    // Return true for test mode
    if (useWrappedTestData) {
      return true;
    }

    try {
      final box = await _openBox();
      final yearlyStats = box.get('yearlyStats_$year');
      return yearlyStats != null &&
          yearlyStats is Map &&
          (yearlyStats['totalSongsPlayed'] ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get available years with stats
  Future<List<int>> getAvailableYears() async {
    // Return current year for test mode
    if (useWrappedTestData) {
      return [DateTime.now().year];
    }

    try {
      final box = await _openBox();
      final years = <int>[];
      for (final key in box.keys) {
        if (key.toString().startsWith('yearlyStats_')) {
          final year = int.tryParse(key.toString().replaceFirst('yearlyStats_', ''));
          if (year != null) {
            final stats = box.get(key);
            if (stats != null &&
                stats is Map &&
                (stats['totalSongsPlayed'] ?? 0) > 0) {
              years.add(year);
            }
          }
        }
      }
      years.sort((a, b) => b.compareTo(a)); // Most recent first
      return years;
    } catch (e) {
      return [];
    }
  }

  /// Generate fake wrapped stats for testing purposes
  WrappedStats _generateFakeWrappedStats(int year) {
    // Fake top songs with realistic data
    final fakeSongs = [
      SongStat(
        songId: 'fake_song_1',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        thumbnailUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
        playCount: 156,
      ),
      SongStat(
        songId: 'fake_song_2',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
        playCount: 134,
      ),
      SongStat(
        songId: 'fake_song_3',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        thumbnailUrl: 'https://i.ytimg.com/vi/JGwWNGJdvx8/hqdefault.jpg',
        playCount: 112,
      ),
      SongStat(
        songId: 'fake_song_4',
        title: 'Lose Yourself',
        artist: 'Eminem',
        thumbnailUrl: 'https://i.ytimg.com/vi/_Yhyp-_hX2s/hqdefault.jpg',
        playCount: 98,
      ),
      SongStat(
        songId: 'fake_song_5',
        title: 'Rolling in the Deep',
        artist: 'Adele',
        thumbnailUrl: 'https://i.ytimg.com/vi/rYEDA3JcQqw/hqdefault.jpg',
        playCount: 87,
      ),
      SongStat(
        songId: 'fake_song_6',
        title: 'Uptown Funk',
        artist: 'Bruno Mars',
        thumbnailUrl: 'https://i.ytimg.com/vi/OPf0YbXqDm0/hqdefault.jpg',
        playCount: 76,
      ),
      SongStat(
        songId: 'fake_song_7',
        title: 'Despacito',
        artist: 'Luis Fonsi',
        thumbnailUrl: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg',
        playCount: 65,
      ),
      SongStat(
        songId: 'fake_song_8',
        title: 'Smells Like Teen Spirit',
        artist: 'Nirvana',
        thumbnailUrl: 'https://i.ytimg.com/vi/hTWKbfoikeg/hqdefault.jpg',
        playCount: 54,
      ),
      SongStat(
        songId: 'fake_song_9',
        title: 'Billie Jean',
        artist: 'Michael Jackson',
        thumbnailUrl: 'https://i.ytimg.com/vi/Zi_XLOBDo_Y/hqdefault.jpg',
        playCount: 43,
      ),
      SongStat(
        songId: 'fake_song_10',
        title: 'Hotel California',
        artist: 'Eagles',
        thumbnailUrl: 'https://i.ytimg.com/vi/09839DpTctU/hqdefault.jpg',
        playCount: 38,
      ),
    ];

    // Fake top artists
    final fakeArtists = [
      ArtistStat(
        artist: 'Queen',
        playCount: 234,
        totalSeconds: 42120, // ~702 minutes
      ),
      ArtistStat(
        artist: 'The Weeknd',
        playCount: 189,
        totalSeconds: 34020, // ~567 minutes
      ),
      ArtistStat(
        artist: 'Ed Sheeran',
        playCount: 156,
        totalSeconds: 28080, // ~468 minutes
      ),
      ArtistStat(
        artist: 'Eminem',
        playCount: 143,
        totalSeconds: 25740, // ~429 minutes
      ),
      ArtistStat(
        artist: 'Adele',
        playCount: 121,
        totalSeconds: 21780, // ~363 minutes
      ),
      ArtistStat(
        artist: 'Bruno Mars',
        playCount: 98,
        totalSeconds: 17640, // ~294 minutes
      ),
      ArtistStat(
        artist: 'Michael Jackson',
        playCount: 87,
        totalSeconds: 15660, // ~261 minutes
      ),
      ArtistStat(
        artist: 'Coldplay',
        playCount: 76,
        totalSeconds: 13680, // ~228 minutes
      ),
      ArtistStat(
        artist: 'Taylor Swift',
        playCount: 65,
        totalSeconds: 11700, // ~195 minutes
      ),
      ArtistStat(
        artist: 'Daft Punk',
        playCount: 54,
        totalSeconds: 9720, // ~162 minutes
      ),
    ];

    return WrappedStats(
      year: year,
      totalListeningMinutes: 8745, // ~145 hours
      totalSongsPlayed: 2847,
      topSongs: fakeSongs,
      topArtists: fakeArtists,
      topMonth: 7, // July
      topMonthMinutes: 1234,
      uniqueSongsPlayed: 456,
      uniqueArtistsPlayed: 123,
    );
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_statsBoxName)) {
      return Hive.box(_statsBoxName);
    }
    return Hive.openBox(_statsBoxName);
  }
}

/// Model for wrapped statistics
class WrappedStats {
  const WrappedStats({
    required this.year,
    required this.totalListeningMinutes,
    required this.totalSongsPlayed,
    required this.topSongs,
    required this.topArtists,
    required this.topMonth,
    required this.topMonthMinutes,
    required this.uniqueSongsPlayed,
    required this.uniqueArtistsPlayed,
  });

  final int year;
  final int totalListeningMinutes;
  final int totalSongsPlayed;
  final List<SongStat> topSongs;
  final List<ArtistStat> topArtists;
  final int topMonth;
  final int topMonthMinutes;
  final int uniqueSongsPlayed;
  final int uniqueArtistsPlayed;

  /// Get total listening hours
  int get totalListeningHours => totalListeningMinutes ~/ 60;

  /// Get formatted listening time
  String get formattedListeningTime {
    if (totalListeningMinutes < 60) {
      return '$totalListeningMinutes min';
    } else if (totalListeningMinutes < 1440) {
      final hours = totalListeningMinutes ~/ 60;
      final minutes = totalListeningMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final days = totalListeningMinutes ~/ 1440;
      final hours = (totalListeningMinutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }
}

/// Model for song statistics
class SongStat {
  const SongStat({
    required this.songId,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    required this.playCount,
  });

  final String songId;
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final int playCount;
}

/// Model for artist statistics
class ArtistStat {
  const ArtistStat({
    required this.artist,
    required this.playCount,
    required this.totalSeconds,
  });

  final String artist;
  final int playCount;
  final int totalSeconds;

  /// Get total listening minutes for this artist
  int get totalMinutes => totalSeconds ~/ 60;
}

// Global instance for easy access
final listeningStatsService = ListeningStatsService.instance;
