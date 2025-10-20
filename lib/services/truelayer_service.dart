import 'dart:convert';
import 'dart:io'; // Für PlatformException
import 'package:http/http.dart' as http;
import '../models/account_model.dart'; // Pfad ggf. anpassen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart'; // Für PlatformException

class TrueLayerService {
  final String _baseUrl = "https://api.truelayer.com/data/v1";
  final _storage = const FlutterSecureStorage(); // Secure Storage Instanz

  // Helper-Methode, um den Token sicher abzurufen
  Future<String?> _getAccessToken() async {
    try {
      // Versuche, den Token zu lesen
      return await _storage.read(key: 'truelayer_access_token');
    } on PlatformException catch (e) {
      // Spezielles Handling für PlatformExceptions (z.B. Keychain/Keystore nicht verfügbar)
      print("Secure Storage Fehler beim Lesen des Tokens: $e");
      // Optional: Versuche, alle Schlüssel zu löschen und es erneut zu versuchen,
      // oder leite den Benutzer zum erneuten Login weiter.
      // await _storage.deleteAll();
      return null;
    } catch (e) {
      // Allgemeines Fehlerhandling
      print("Allgemeiner Fehler beim Lesen des Tokens: $e");
      return null;
    }
  }

  // Ruft die Liste der Konten ab
  Future<List<Account>> getAccounts() async {
    final accessToken = await _getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      // Wirf einen spezifischen Fehler oder gib eine leere Liste zurück,
      // damit die UI den Benutzer zum Login auffordern kann.
      throw Exception(
        'Access Token nicht gefunden oder leer. Bitte einloggen.',
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/accounts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        }, // Dynamischen Token verwenden
      );

      if (response.statusCode == 200) {
        // Wenn der Server mit OK antwortet, parse das JSON.
        final Map<String, dynamic> decodedBody = json.decode(response.body);
        if (decodedBody.containsKey('results') &&
            decodedBody['results'] is List) {
          final List<dynamic> results = decodedBody['results'];
          if (results.isEmpty) {
            // API hat erfolgreich geantwortet, aber es gibt keine Konten
            return []; // Leere Liste zurückgeben
          }
          return results.map((json) => Account.fromJson(json)).toList();
        } else {
          // Unerwartete JSON-Struktur
          throw Exception(
            'Fehler beim Parsen der Konten: "results" Feld fehlt oder ist kein Array.',
          );
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - Token ist wahrscheinlich ungültig oder abgelaufen
        // Hier könntest du versuchen, den Token mit dem Refresh Token zu erneuern
        // oder den Benutzer zum erneuten Login auffordern.
        await _storage.delete(
          key: 'truelayer_access_token',
        ); // Ungültigen Token löschen
        await _storage.delete(key: 'truelayer_refresh_token');
        throw Exception(
          'Authentifizierung fehlgeschlagen (Token ungültig?). Bitte erneut einloggen.',
        );
      } else {
        // Andere HTTP-Fehler
        throw Exception(
          'Fehler beim Laden der Konten (${response.statusCode}): ${response.body}',
        );
      }
    } on SocketException {
      // Kein Internet
      throw Exception(
        'Netzwerkfehler: Konnte TrueLayer nicht erreichen. Bitte prüfe deine Internetverbindung.',
      );
    } catch (e) {
      // Andere Fehler (z.B. Timeout, FormatException beim Parsen)
      throw Exception('Ein unerwarteter Fehler ist aufgetreten: $e');
    }
  }

  // --- Beispiel für Transaktionen ---
  // Future<List<Transaction>> getTransactions(String accountId) async {
  //   final accessToken = await _getAccessToken();
  //   if (accessToken == null) {
  //     throw Exception('Access Token nicht gefunden. Bitte einloggen.');
  //   }
  //
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/accounts/$accountId/transactions'),
  //     headers: {'Authorization': 'Bearer $accessToken'},
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final List<dynamic> results = json.decode(response.body)['results'];
  //     // Erstelle hier ein Transaction.fromJson und parse die Daten
  //     // return results.map((json) => Transaction.fromJson(json)).toList();
  //     return []; // Platzhalter
  //   } else {
  //      await _storage.delete(key: 'truelayer_access_token'); // Ungültigen Token löschen
  //      await _storage.delete(key: 'truelayer_refresh_token');
  //     throw Exception('Fehler beim Laden der Transaktionen: ${response.body}');
  //   }
  // }

  // --- Beispiel für Kontostand ---
  // Future<double> getBalance(String accountId) async {
  //   final accessToken = await _getAccessToken();
  //   if (accessToken == null) {
  //     throw Exception('Access Token nicht gefunden. Bitte einloggen.');
  //   }
  //
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/accounts/$accountId/balance'),
  //     headers: {'Authorization': 'Bearer $accessToken'},
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> result = json.decode(response.body)['results'][0];
  //     return (result['available'] ?? result['current'] ?? 0.0).toDouble();
  //   } else {
  //      await _storage.delete(key: 'truelayer_access_token'); // Ungültigen Token löschen
  //      await _storage.delete(key: 'truelayer_refresh_token');
  //      throw Exception('Fehler beim Laden des Kontostands: ${response.body}');
  //   }
  // }
}
