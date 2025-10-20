import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/account_model.dart';

class TrueLayerService {
  final String _baseUrl = "https://api.truelayer.com/data/v1";

  // ACHTUNG: Ersetze dies durch deinen echten Access Token.
  // In einer echten App würde dieser Token sicher gespeichert und nicht hartcodiert werden!
  final String _accessToken = "DEIN_TRUELAYER_ACCESS_TOKEN";

  // Ruft die Liste der Konten ab
  Future<List<Account>> getAccounts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/accounts'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      // Wenn der Server mit OK antwortet, parse das JSON.
      final List<dynamic> results = json.decode(response.body)['results'];
      return results.map((json) => Account.fromJson(json)).toList();
    } else {
      // Wenn die Antwort nicht OK war, wirf einen Fehler.
      throw Exception('Fehler beim Laden der Konten: ${response.body}');
    }
  }

  // Hier könntest du eine ähnliche Methode für Transaktionen hinzufügen:
  // Future<List<Transaction>> getTransactions(String accountId) async { ... }
}
