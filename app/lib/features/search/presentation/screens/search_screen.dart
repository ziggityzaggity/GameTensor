import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../application/search_controller.dart';
import '../widgets/game_result_tile.dart';
import '../widgets/search_filters_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return AppShell(
      currentIndex: 0,
      title: 'Search',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.assistant),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI Finder'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, genre, platform...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (q) => ref.read(searchControllerProvider.notifier).search(q),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const SearchFiltersSheet(),
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final game = state.results[index];
                return GameResultTile(
                  game: game,
                  onTap: () => context.push(RoutePaths.gameDetailPath(game.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
