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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/utilities/common_variables.dart';
import 'package:musify/widgets/section_header.dart';
import 'package:musify/widgets/song_bar.dart';
import 'package:musify/widgets/spinner.dart';

class WrappedPage extends StatefulWidget {
  const WrappedPage({super.key, this.year});

  final int? year;

  @override
  State<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends State<WrappedPage> {
  late int selectedYear;
  late Future<WrappedStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.year ?? DateTime.now().year;
    _loadStats();
  }

  void _loadStats() {
    _statsFuture = ListeningStatsService.instance.getWrappedStats(selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.wrapped),
        actions: [
          // Year selector
          PopupMenuButton<int>(
            icon: const Icon(FluentIcons.calendar_24_regular),
            onSelected: (year) {
              setState(() {
                selectedYear = year;
                _loadStats();
              });
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return [
                for (var year = currentYear; year >= currentYear - 2; year--)
                  PopupMenuItem(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontWeight: year == selectedYear
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: year == selectedYear
                            ? colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<WrappedStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Spinner());
          }

          if (snapshot.hasError) {
            logger.log('Error loading wrapped stats', snapshot.error, snapshot.stackTrace);
            return Center(
              child: Text(
                context.l10n!.error,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          final stats = snapshot.data!;

          if (stats.isEmpty) {
            return _buildEmptyState(context, colorScheme);
          }

          return _buildWrappedContent(context, stats, colorScheme);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.music_note_off_24_filled,
              size: 80,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n!.noWrappedData,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrappedContent(
    BuildContext context,
    WrappedStats stats,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: commonSingleChildScrollViewPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with year and description
          _buildHeader(context, stats, colorScheme),
          const SizedBox(height: 24),

          // Stats overview cards
          _buildStatsCards(context, stats, colorScheme),
          const SizedBox(height: 24),

          // Top Songs section
          if (stats.topSongs.isNotEmpty) ...[
            SectionHeader(
              title: context.l10n!.topSongs,
              icon: FluentIcons.music_note_1_24_filled,
            ),
            _buildTopSongsList(context, stats.topSongs),
            const SizedBox(height: 24),
          ],

          // Top Artists section
          if (stats.topArtists.isNotEmpty) ...[
            SectionHeader(
              title: context.l10n!.topArtists,
              icon: FluentIcons.person_24_filled,
            ),
            _buildTopArtistsList(context, stats.topArtists, colorScheme),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WrappedStats stats,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedYear',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n!.wrappedDescription,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                FluentIcons.timer_24_filled,
                color: colorScheme.onPrimaryContainer,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n!.totalListeningTime,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    stats.formattedListeningTime,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    WrappedStats stats,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: FluentIcons.play_24_filled,
            label: context.l10n!.songsPlayed,
            value: stats.totalSongsPlayed.toString(),
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: FluentIcons.music_note_2_24_filled,
            label: context.l10n!.uniqueSongs,
            value: stats.uniqueSongsCount.toString(),
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: FluentIcons.people_24_filled,
            label: context.l10n!.uniqueArtists,
            value: stats.uniqueArtistsCount.toString(),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSongsList(BuildContext context, List<Map<String, dynamic>> songs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final playCount = song['playCount'] ?? 0;
        return SongBar(
          song,
          true,
          showMusicDuration: true,
          trailing: Text(
            context.l10n!.plays(playCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopArtistsList(
    BuildContext context,
    List<Map<String, dynamic>> artists,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length,
      padding: commonListViewBottmomPadding,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final playCount = artist['playCount'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  artist['artist']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                context.l10n!.plays(playCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
