import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String apiUrl = 'https://api.igdb.com/v4';
  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> _getAccessToken() async {
    // Verifica se já tem um token válido
    if (_accessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now())) {
      print('ℹ️ Token ainda válido. Expira em: $_tokenExpiry');
      return;
    }

    print('🔑 Iniciando obtenção de novo token de acesso...');

    try {
      final clientId = dotenv.env['IGDB_CLIENT_ID']!;
      final clientSecret = dotenv.env['IGDB_CLIENT_SECRET']!;

      print('📤 Enviando requisição para Twitch OAuth...');
      print(
          '🆔 Client ID: ${clientId.substring(0, 5)}...'); // Mostra apenas parte por segurança
      print('🔒 Client Secret: ${clientSecret.substring(0, 5)}...');

      final response = await http.post(
        Uri.parse('https://id.twitch.tv/oauth2/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'client_credentials',
        },
      );

      print('📥 Resposta recebida. Status: ${response.statusCode}');
      print('📊 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry =
            DateTime.now().add(Duration(seconds: data['expires_in']));

        print('✅ Token obtido com sucesso!');
        print('   ⏱️ Expira em: $_tokenExpiry');
        print(
            '   🔑 Token (início): ${_accessToken!.substring(0, 15)}...'); // Mostra só parte
      } else {
        print('❌ Erro ao obter token: ${response.statusCode}');
        print('   Corpo do erro: ${response.body}');
        throw Exception('Falha ao obter token: ${response.statusCode}');
      }
    } catch (e) {
      print('‼️ Exceção durante obtenção do token: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchIGDBData({
    required String endpoint,
    required String query,
  }) async {
    try {
      await _getAccessToken();
      final headers = {
        'Client-ID': dotenv.env['IGDB_CLIENT_ID']!,
        'Authorization': 'Bearer $_accessToken',
        'Accept': 'application/json; charset=utf-8', // Charset explícito
        'Content-Type': 'text/plain; charset=utf-8', // Importante para queries
      };

      final response = await http.post(
        Uri.parse('$apiUrl/$endpoint'),
        headers: headers,
        body: utf8.encode(query), // Codifica a query como UTF-8
      );

      // Decodificação correta da resposta:
      final responseString =
          utf8.decode(response.bodyBytes); // <-- SOLUÇÃO CHAVE
      final decodedData = json.decode(responseString) as List<dynamic>;

      print('✅ Dados decodificados: ${decodedData.length} itens');
      return decodedData;
    } catch (e) {
      print('‼️ Erro na conexão: $e');
      rethrow;
    }
  }
}
