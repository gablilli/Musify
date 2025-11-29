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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/listening_stats_service.dart';
import 'package:musify/widgets/no_artwork_cube.dart';
import 'package:musify/widgets/spinner.dart';

class WrappedPage extends StatefulWidget {
  const WrappedPage({super.key, required this.year});

  final int year;

  @override
  State<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends State<WrappedPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  WrappedStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await listeningStatsService.getWrappedStats(widget.year);
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.year} Wrapped')),
        body: const Center(child: Spinner()),
      );
    }

    if (_stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.year} Wrapped')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.music_note_off_24_filled,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n!.wrappedNoData,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cards = _buildCards(_stats!);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  _previousPage();
                } else {
                  _nextPage();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return cards[index];
                },
              ),
            ),
            // Progress indicators at the top
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(cards.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  FluentIcons.dismiss_24_filled,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards(WrappedStats stats) {
    return [
      _WelcomeCard(year: stats.year),
      _TotalListeningCard(stats: stats),
      _TopSongsCard(stats: stats),
      _TopArtistsCard(stats: stats),
      _StatsOverviewCard(stats: stats),
      _SummaryCard(stats: stats),
    ];
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _WrappedCardBase(
      gradientColors: [
        colorScheme.primaryContainer,
        colorScheme.secondaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.music_note_2_24_filled,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            context.l10n!.wrappedTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            year.toString(),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontSize: 72,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n!.wrappedSubtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TotalListeningCard extends StatelessWidget {
  const _TotalListeningCard({required this.stats});

  final WrappedStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _WrappedCardBase(
      gradientColors: [
        colorScheme.tertiaryContainer,
        colorScheme.primaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.timer_24_filled,
            size: 64,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n!.wrappedListeningTime,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            stats.formattedListeningTime,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBadge(
                icon: FluentIcons.music_note_1_24_filled,
                value: stats.totalSongsPlayed.toString(),
                label: context.l10n!.songs.toLowerCase(),
              ),
              _StatBadge(
                icon: FluentIcons.headphones_24_filled,
                value: stats.totalListeningHours.toString(),
                label: context.l10n!.hours.toLowerCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopSongsCard extends StatelessWidget {
  const _TopSongsCard({required this.stats});

  final WrappedStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topSongs = stats.topSongs.take(5).toList();

    return _WrappedCardBase(
      gradientColors: [
        colorScheme.secondaryContainer,
        colorScheme.tertiaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.star_24_filled,
            size: 48,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n!.wrappedTopSongs,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...topSongs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _SongListItem(
              rank: index + 1,
              song: song,
              isTopSong: index == 0,
            );
          }),
        ],
      ),
    );
  }
}

class _TopArtistsCard extends StatelessWidget {
  const _TopArtistsCard({required this.stats});

  final WrappedStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topArtists = stats.topArtists.take(5).toList();

    return _WrappedCardBase(
      gradientColors: [
        colorScheme.primaryContainer,
        colorScheme.secondaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.person_star_24_filled,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n!.wrappedTopArtists,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...topArtists.asMap().entries.map((entry) {
            final index = entry.key;
            final artist = entry.value;
            return _ArtistListItem(
              rank: index + 1,
              artist: artist,
              isTopArtist: index == 0,
            );
          }),
        ],
      ),
    );
  }
}

class _StatsOverviewCard extends StatelessWidget {
  const _StatsOverviewCard({required this.stats});

  final WrappedStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthNames = [
      '',
      context.l10n!.wrappedJanuary,
      context.l10n!.wrappedFebruary,
      context.l10n!.wrappedMarch,
      context.l10n!.wrappedApril,
      context.l10n!.wrappedMay,
      context.l10n!.wrappedJune,
      context.l10n!.wrappedJuly,
      context.l10n!.wrappedAugust,
      context.l10n!.wrappedSeptember,
      context.l10n!.wrappedOctober,
      context.l10n!.wrappedNovember,
      context.l10n!.wrappedDecember,
    ];

    return _WrappedCardBase(
      gradientColors: [
        colorScheme.tertiaryContainer,
        colorScheme.secondaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.data_bar_vertical_24_filled,
            size: 48,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n!.wrappedYourYear,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LargeStatBadge(
                value: stats.uniqueSongsPlayed.toString(),
                label: context.l10n!.wrappedUniqueSongs,
                color: colorScheme.primary,
              ),
              _LargeStatBadge(
                value: stats.uniqueArtistsPlayed.toString(),
                label: context.l10n!.wrappedUniqueArtists,
                color: colorScheme.secondary,
              ),
            ],
          ),
          if (stats.topMonth > 0) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n!.wrappedTopMonth,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    monthNames[stats.topMonth],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${stats.topMonthMinutes} ${context.l10n!.minutes.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final WrappedStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topSong = stats.topSongs.isNotEmpty ? stats.topSongs.first : null;
    final topArtist =
        stats.topArtists.isNotEmpty ? stats.topArtists.first : null;

    return _WrappedCardBase(
      gradientColors: [
        colorScheme.primaryContainer,
        colorScheme.tertiaryContainer,
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${stats.year}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Text(
            context.l10n!.wrappedSummary,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _SummaryItem(
            icon: FluentIcons.timer_24_filled,
            label: context.l10n!.wrappedListeningTime,
            value: stats.formattedListeningTime,
          ),
          const SizedBox(height: 12),
          _SummaryItem(
            icon: FluentIcons.music_note_1_24_filled,
            label: context.l10n!.wrappedTotalSongs,
            value: stats.totalSongsPlayed.toString(),
          ),
          if (topSong != null) ...[
            const SizedBox(height: 12),
            _SummaryItem(
              icon: FluentIcons.star_24_filled,
              label: context.l10n!.wrappedTopSong,
              value: topSong.title,
            ),
          ],
          if (topArtist != null) ...[
            const SizedBox(height: 12),
            _SummaryItem(
              icon: FluentIcons.person_star_24_filled,
              label: context.l10n!.wrappedTopArtist,
              value: topArtist.artist,
            ),
          ],
          const SizedBox(height: 32),
          Icon(
            FluentIcons.heart_24_filled,
            size: 32,
            color: colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n!.wrappedThankYou,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper widgets

class _WrappedCardBase extends StatelessWidget {
  const _WrappedCardBase({required this.gradientColors, required this.child});

  final List<Color> gradientColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: child,
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeStatBadge extends StatelessWidget {
  const _LargeStatBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SongListItem extends StatelessWidget {
  const _SongListItem({
    required this.rank,
    required this.song,
    this.isTopSong = false,
  });

  final int rank;
  final SongStat song;
  final bool isTopSong;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTopSong
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopSong
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTopSong
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: song.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: song.thumbnailUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const NullArtworkWidget(iconSize: 20, size: 40),
                  )
                : const NullArtworkWidget(iconSize: 20, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isTopSong ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.artist != null)
                  Text(
                    song.artist!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${song.playCount}x',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistListItem extends StatelessWidget {
  const _ArtistListItem({
    required this.rank,
    required this.artist,
    this.isTopArtist = false,
  });

  final int rank;
  final ArtistStat artist;
  final bool isTopArtist;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTopArtist
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopArtist
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTopArtist
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.person_24_filled,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.artist,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isTopArtist ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${artist.playCount} ${context.l10n!.wrappedPlays}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${artist.totalMinutes}m',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
