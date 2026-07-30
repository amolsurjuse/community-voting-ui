import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/event.dart';
import '../../domain/repositories.dart';

final _filtersProvider = StateProvider<DiscoverFilters>(
  (ref) => const DiscoverFilters(),
);

final _searchResultsProvider =
    FutureProvider.autoDispose<List<VotingEvent>>((ref) {
  final filters = ref.watch(_filtersProvider);
  return ref.watch(eventRepositoryProvider).discover(filters);
});

final _trendingProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(eventRepositoryProvider).trending(),
);
final _closingSoonProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(eventRepositoryProvider).closingSoon(),
);

/// Public event discovery: search, filters, trending and closing-soon rails.
/// Only public events ever appear here.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  final List<String> _searchHistory = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(_filtersProvider);
      ref.read(_filtersProvider.notifier).state = DiscoverFilters(
        query: query,
        category: current.category,
        verificationLevel: current.verificationLevel,
        ballotType: current.ballotType,
        resultVisibility: current.resultVisibility,
      );
      final trimmed = query.trim();
      if (trimmed.length > 2 && !_searchHistory.contains(trimmed)) {
        setState(() => _searchHistory.insert(0, trimmed));
        if (_searchHistory.length > 6) _searchHistory.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(_filtersProvider);
    final searching = !filters.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_trendingProvider);
            ref.invalidate(_closingSoonProvider);
            ref.invalidate(_searchResultsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onQueryChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search public events…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      _FilterRow(filters: filters),
                    ],
                  ),
                ),
              ),
              if (searching)
                _SearchResults(history: _searchHistory)
              else ...[
                const _Rail(title: 'Trending', provider: _RailKind.trending),
                const _Rail(
                    title: 'Closing soon', provider: _RailKind.closingSoon),
                if (_searchHistory.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Recent searches'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                          ),
                          child: Wrap(
                            spacing: Spacing.sm,
                            children: [
                              for (final term in _searchHistory)
                                ActionChip(
                                  label: Text(term),
                                  onPressed: () {
                                    _searchController.text = term;
                                    _onQueryChanged(term);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.filters});

  final DiscoverFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update({
      EventCategory? Function()? category,
      BallotType? Function()? ballotType,
      VerificationLevel? Function()? verification,
    }) {
      ref.read(_filtersProvider.notifier).state = DiscoverFilters(
        query: filters.query,
        category: category != null ? category() : filters.category,
        ballotType: ballotType != null ? ballotType() : filters.ballotType,
        verificationLevel:
            verification != null ? verification() : filters.verificationLevel,
        resultVisibility: filters.resultVisibility,
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _DropdownChip<EventCategory>(
            label: filters.category?.label ?? 'Category',
            selected: filters.category != null,
            values: EventCategory.values,
            display: (c) => c.label,
            onSelected: (c) => update(category: () => c),
          ),
          const SizedBox(width: Spacing.sm),
          _DropdownChip<BallotType>(
            label: filters.ballotType?.label ?? 'Ballot type',
            selected: filters.ballotType != null,
            values: const [
              BallotType.singleChoice,
              BallotType.multipleChoice,
              BallotType.rankedChoice,
            ],
            display: (b) => b.label,
            onSelected: (b) => update(ballotType: () => b),
          ),
          const SizedBox(width: Spacing.sm),
          _DropdownChip<VerificationLevel>(
            label: filters.verificationLevel?.label ?? 'Verification',
            selected: filters.verificationLevel != null,
            values: VerificationLevel.values,
            display: (v) => v.label,
            onSelected: (v) => update(verification: () => v),
          ),
          if (!filters.isEmpty) ...[
            const SizedBox(width: Spacing.sm),
            ActionChip(
              avatar: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
              onPressed: () => ref.read(_filtersProvider.notifier).state =
                  const DiscoverFilters(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.selected,
    required this.values,
    required this.display,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final List<T> values;
  final String Function(T) display;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: selected ? null : const Icon(Icons.expand_more, size: 16),
      onSelected: (_) async {
        final choice = await showAppSheet<T>(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in values)
                ListTile(
                  title: Text(display(value)),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        );
        if (choice != null) onSelected(choice);
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.history});

  final List<String> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(_searchResultsProvider);
    return results.when(
      loading: () => const SliverToBoxAdapter(
        child: SkeletonList(items: 3, itemHeight: 96),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: ErrorPanel(
          message: 'Search failed. Check your connection.',
          onRetry: () => ref.invalidate(_searchResultsProvider),
        ),
      ),
      data: (events) => events.isEmpty
          ? const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No events found',
                message:
                    'Try a different search, or clear filters. Unlisted and private events never appear in search.',
              ),
            )
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              sliver: SliverList.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, i) => EventCard(
                  event: events[i],
                  onTap: () => context.push('/e/${events[i].publicId}'),
                ),
              ),
            ),
    );
  }
}

enum _RailKind { trending, closingSoon }

class _Rail extends ConsumerWidget {
  const _Rail({required this.title, required this.provider});

  final String title;
  final _RailKind provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      provider == _RailKind.trending ? _trendingProvider : _closingSoonProvider,
    );
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: SkeletonBox(height: 96, borderRadius: Corners.lg),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (events) => events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Text(
                      'Nothing here right now.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Column(
                      children: [
                        for (final event in events) ...[
                          EventCard(
                            event: event,
                            onTap: () => context.push('/e/${event.publicId}'),
                          ),
                          const SizedBox(height: Spacing.md),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
