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
  late Map<String, dynamic> gameDetails;
  bool _isLoading = true;
  List<String> genreNames = [];
  List<String> platformNames = [];
  List<String> ageRatingNames = [];

  @override
  void initState() {
    super.initState();
    _fetchGameDetails(); // Carrega os detalhes do jogo
  }

  // Função para buscar os detalhes adicionais do jogo usando o ID
  Future<void> _fetchGameDetails() async {
    try {
      final gameId = widget.game['id'];
      final query = """
      fields name, cover.url, summary, first_release_date, platforms, genres, age_ratings;
      where id = $gameId;
      """;

      final result = await ApiService().fetchIGDBData(
        endpoint: 'games',
        query: query.trim(),
      );

      setState(() {
        gameDetails =
            result.isNotEmpty ? result[0] : {}; // Armazena os detalhes
        _isLoading = false; // Finaliza o carregamento
      });

      // Agora, vamos buscar os detalhes dos gêneros, plataformas e faixa etária
      await _fetchAdditionalDetails();
    } catch (e) {
      setState(() {
        _isLoading = false; // Finaliza carregamento
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar detalhes do jogo: $e')),
      );
    }
  }

  Future<void> _fetchAdditionalDetails() async {
    // Gêneros
    if (gameDetails['genres'] != null) {
      final genreIds = gameDetails['genres'];
      final genreQuery = """
      fields name;
      where id in (${genreIds.join(',')});
      """;
      final genreResult = await ApiService().fetchIGDBData(
        endpoint: 'genres',
        query: genreQuery.trim(),
      );
      setState(() {
        genreNames = genreResult
            .map((genre) => genre['name']?.toString() ?? 'Desconhecido')
            .toList();
      });
    }

    // Plataformas
    if (gameDetails['platforms'] != null) {
      final platformIds = gameDetails['platforms'];
      final platformQuery = """
      fields name;
      where id in (${platformIds.join(',')});
      """;
      final platformResult = await ApiService().fetchIGDBData(
        endpoint: 'platforms',
        query: platformQuery.trim(),
      );
      setState(() {
        platformNames = platformResult
            .map((platform) => platform['name']?.toString() ?? 'Desconhecido')
            .toList();
      });
    }

    // Faixa etária
    if (gameDetails['age_ratings'] != null) {
      final ageRatingIds = gameDetails['age_ratings'];
      final ageRatingQuery = """
      fields rating_category;
      where id in (${ageRatingIds.join(',')});
      """;
      final ageRatingResult = await ApiService().fetchIGDBData(
        endpoint: 'age_ratings',
        query: ageRatingQuery.trim(),
      );
      setState(() {
        ageRatingNames = ageRatingResult
            .map((ageRating) =>
                ageRating['rating_category']?.toString() ?? 'Desconhecido')
            .toList();
      });
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Desconhecida';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatList(List<String> list) {
    if (list.isEmpty) return 'Não disponível';
    return list.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = (widget.game['cover']?['url'] as String?) != null
        ? 'https:${widget.game['cover']['url']}'
            .replaceAll('t_thumb', 't_cover_big')
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.game['name'] ?? 'Detalhes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coverUrl != null)
                    Center(
                      child: Image.network(
                        coverUrl,
                        width: 400,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    gameDetails['name'] ?? 'Sem nome',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (gameDetails['total_rating'] != null)
                    Text(
                      '⭐ Avaliação: ${widget.game['total_rating'].toStringAsFixed(1)} / 100',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    '📆 Lançamento: ${_formatDate(widget.game['first_release_date'])}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (platformNames.isNotEmpty)
                    Text(
                      '🎮 Plataformas: ${_formatList(platformNames)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 12),
                  if (genreNames.isNotEmpty)
                    Text(
                      '🧬 Gêneros: ${_formatList(genreNames)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 12),
                  if (ageRatingNames.isNotEmpty)
                    Text(
                      '📑 Faixa Etária: ${_formatList(ageRatingNames)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    widget.game['summary'] ?? 'Este jogo não possui descrição.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (widget.game['url'] != null)
                    TextButton(
                      onPressed: () {
                        // Se quiser abrir no navegador, adicione url_launcher depois
                      },
                      child: const Text('🔗 Ver no IGDB'),
                    ),
                ],
              ),
            ),
    );
  }
}
