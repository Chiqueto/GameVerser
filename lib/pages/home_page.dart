import 'package:flutter/material.dart';
import '../services/api_service.dart';
import './game_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasMore = true;
  final List<dynamic> _games = [];
  int _currentPage = 0;
  bool _isLoading = false;

  String _escapeSearchQuery(String query) {
    return query.replaceAll("'", r"\\'");
  }

  Future<void> _loadGames({bool reset = false}) async {
    if (reset) {
      setState(() {
        _games.clear();
        _currentPage = 0;
        _hasMore = true;
      });
    }

    setState(() => _isLoading = true);

    final timestampAgora = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final isSearching = _searchQuery.isNotEmpty;
      final String searchFilter =
          isSearching ? 'search "${_escapeSearchQuery(_searchQuery)}";' : '';

      final query = """
      fields cover.url, name, summary, first_release_date, total_rating, rating_count, platforms.name, genres.name;
      $searchFilter
      where first_release_date < $timestampAgora;
      ${isSearching ? "" : "sort rating_count desc;"}
      limit 10;
      offset ${_currentPage * 10};
      """;

      print('Query: $query');

      final newGames = await ApiService().fetchIGDBData(
        endpoint: 'games',
        query: query.trim(),
      );

      setState(() {
        _games.addAll(newGames);
        _currentPage++;
        if (newGames.length < 10) {
          _hasMore = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar jogos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogos Populares'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading && _games.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _games.isEmpty
                    ? const Center(child: Text('Nenhum jogo encontrado.'))
                    : _buildGamesList(_games),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim().toLowerCase();
              });
              _loadGames(reset: true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(List<dynamic> gamesList) {
    return ListView.builder(
      itemCount: gamesList.length + 1,
      itemBuilder: (context, index) {
        if (index < gamesList.length) {
          final game = gamesList[index];
          final cover = game['cover'];
          String? coverUrl;

          if (cover is Map<String, dynamic> && cover['url'] != null) {
            var url = cover['url'] as String;
            if (url.startsWith('//')) {
              url = 'https:$url';
            }
            coverUrl = url.replaceAll('t_thumb', 't_cover_small');
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailPage(game: game),
                  ),
                );
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                  maxWidth: 60,
                  maxHeight: 60,
                ),
                child: coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.videogame_asset,
                        size: 50, color: Colors.grey),
              ),
              title: Text(
                game['name'] ?? 'Sem nome',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: game['total_rating'] != null
                  ? Text('⭐ ${game['total_rating'].toStringAsFixed(1)} / 100')
                  : const Text('Sem avaliação'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        }

        return _hasMore
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _loadGames,
                          icon: const Icon(Icons.add),
                          label: const Text('Carregar mais'),
                        ),
                ),
              )
            : const SizedBox();
      },
    );
  }
}
