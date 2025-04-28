import 'package:flutter/material.dart';
import '../services/api_service.dart';
import './game_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  bool _hasMore = true;
  List<dynamic> _games = [];
  int _currentPage = 0;
  bool _isLoading = false;
  String _selectedFilter = 'melhores';
  String _debugInfo = ''; // Variável para informações de depuração

  // O timestampAgora precisa ser acessado no momento da execução da query
  String _escapeSearchQuery(String query) {
    return query.replaceAll("'", r"\'");
  }

  final Map<String, String> _filters = {
    'recentes':
        'where first_release_date != null; sort first_release_date desc;',
    'melhores': 'where total_rating != null;sort total_rating desc;',
    'em_alta': 'sort rating_count desc;',
  };

  List<dynamic> _filteredGames() {
    if (_searchQuery.isEmpty) return _games;
    return _games.where((game) {
      final name = game['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    _debugInfo = 'Carregando jogos...'; // Exibe mensagem de carregamento

    // Calculando o timestamp da data atual para usar na query
    final timestampAgora = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final isSearching = _searchQuery.isNotEmpty;

      final String searchFilter = isSearching
          ? 'where name ~ *"${_escapeSearchQuery(_searchQuery)}"*;'
          : _filters[_selectedFilter] ?? '';

      final query = """
      fields cover, name, summary, first_release_date, total_rating, rating_count, age_ratings, genres, platforms;
      $searchFilter
      where first_release_date < $timestampAgora;
      limit 10;
      offset ${_currentPage * 10};
    """;

      // Exibe a query na tela
      setState(() {
        _debugInfo = 'Query executada: $query'; // Exibe a query no debug
      });

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
        // Exibe a estrutura dos dados recebidos (apenas o primeiro item para não sobrecarregar)
        if (newGames.isNotEmpty) {
          _debugInfo = 'Dados recebidos (primeiro item): ${newGames.first}';
        } else {
          _debugInfo = 'Nenhum dado recebido.';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugInfo = 'Erro ao carregar jogos: $e'; // Exibe erro no debug
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar jogos: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGames(); // Carrega a primeira página
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGames();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de jogos')),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilters(),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              child: Text(
                'Resultados para: $_searchQuery',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          if (_games.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
            ),
          // Debug visual com estado de carregamento, número de jogos e query executada
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Carregando: ${_isLoading ? "Sim" : "Não"}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Jogos carregados: ${_games.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Filtro atual: $_selectedFilter',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Query executada: $_debugInfo',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por nome...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
            _games.clear();
            _currentPage = 0;
            _hasMore = true;
            _selectedFilter = '';
          });
          _loadGames();
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: _filters.keys.map((key) {
          final isSelected = _selectedFilter == key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(key.toUpperCase()),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = key;
                  _games.clear();
                  _currentPage = 0;
                  _hasMore = true;
                });
                _loadGames();
              },
            ),
          );
        }).toList(),
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
          final coverUrl = (cover != null && cover['url'] is String)
              ? 'https:${cover['url']}'.replaceAll('t_thumb', 't_cover_small')
              : null;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailPage(game: game),
                  ),
                );
              },
              contentPadding: const EdgeInsets.all(8),
              leading: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.warning, size: 50, color: Colors.red),
              title: Text(
                game['name'] ?? '⚠️ Nome nulo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                game['summary'] != null
                    ? (game['summary'].length > 50
                        ? game['summary'].substring(0, 50)
                        : game['summary'])
                    : 'Sem descrição',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return _hasMore
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _loadGames,
                          icon: const Icon(Icons.add),
                          label: const Text("Carregar mais"),
                        ),
                ),
              )
            : const SizedBox();
      },
    );
  }
}
