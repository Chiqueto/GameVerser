import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class GameDetailPage extends StatefulWidget {
  final Map<String, dynamic> game;

  const GameDetailPage({super.key, required this.game});

  @override
  _GameDetailPageState createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  Map<String, dynamic>? gameDetails;
  bool _isLoading = true;
  List<String> genreNames = [];
  List<String> platformNames = [];

  @override
  void initState() {
    super.initState();
    _fetchGameDetails();
  }

  Future<void> _fetchGameDetails() async {
    try {
      final gameId = widget.game['id'];
      final query = """
      fields name, cover.url, summary, first_release_date, total_rating, rating_count, platforms.name, genres.name, url;
      where id = $gameId;
      """;

      final result = await ApiService().fetchIGDBData(
        endpoint: 'games',
        query: query.trim(),
      );

      if (result.isNotEmpty) {
        setState(() {
          gameDetails = result[0];
          _isLoading = false;
        });
        await _fetchAdditionalDetails();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar detalhes do jogo: $e')),
      );
    }
  }

  Future<void> _fetchAdditionalDetails() async {
    if (gameDetails == null) return;

    if (gameDetails!['platforms'] != null &&
        gameDetails!['platforms'] is List) {
      final platformList = gameDetails!['platforms'] as List;
      platformNames = platformList
          .map((platform) => platform['name']?.toString() ?? 'Desconhecido')
          .toList();
    }

    if (gameDetails!['genres'] != null && gameDetails!['genres'] is List) {
      final genreList = gameDetails!['genres'] as List;
      genreNames = genreList
          .map((genre) => genre['name']?.toString() ?? 'Desconhecido')
          .toList();
    }
    setState(() {});
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Desconhecida';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = (gameDetails?['cover']?['url'] as String?) != null
        ? (() {
            var url = gameDetails!['cover']['url'] as String;
            if (url.startsWith('//')) {
              url = 'https:$url';
            }
            return url.replaceAll('t_thumb', 't_cover_big');
          })()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(gameDetails?['name'] ?? 'Detalhes'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : gameDetails == null
              ? const Center(child: Text('Detalhes não disponíveis.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (coverUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          coverUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        gameDetails?['name'] ?? 'Sem nome',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    if (gameDetails?['total_rating'] != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                              '${gameDetails!['total_rating'].toStringAsFixed(1)} / 100',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Text(
                            'Lançamento: ${_formatDate(gameDetails?['first_release_date'])}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (platformNames.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: platformNames
                            .map((name) => Chip(
                                  label: Text(name,
                                      style: const TextStyle(fontSize: 13)),
                                  backgroundColor: Colors.blue.shade100,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    if (genreNames.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genreNames
                            .map((name) => Chip(
                                  label: Text(name,
                                      style: const TextStyle(fontSize: 13)),
                                  backgroundColor: Colors.purple.shade100,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    Text(
                      'Descrição:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameDetails?['summary'] ??
                          'Este jogo não possui descrição.',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 30),
                    if (gameDetails?['url'] != null)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Future: adicionar link usando url_launcher
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Ver no IGDB'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 169, 141, 247),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
