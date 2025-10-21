// Dieses Modell repräsentiert ein einzelnes Bankkonto,
// wie es von der TrueLayer API zurückgegeben wird.

class Account {
  final String accountId;
  final String displayName;
  final String accountNumber; // IBAN
  final double balance;
  final String currency;

  Account({
    required this.accountId,
    required this.displayName,
    required this.accountNumber,
    required this.balance,
    required this.currency,
  });

  // Eine "Factory"-Methode, um ein Account-Objekt aus einem JSON-Objekt zu erstellen.
  factory Account.fromJson(Map<String, dynamic> json) {
    // Versuche, den Kontostand aus 'available' oder 'current' zu lesen
    // Stelle sicher, dass die Werte korrekt als double behandelt werden
    double availableBalance =
        (json['balance']?['available'] as num?)?.toDouble() ?? 0.0;
    double currentBalance =
        (json['balance']?['current'] as num?)?.toDouble() ?? 0.0;

    // Priorisiere 'available', falle auf 'current' zurück, wenn 'available' 0 ist oder fehlt
    double finalBalance = (availableBalance != 0.0)
        ? availableBalance
        : currentBalance;

    // IBAN kann in verschiedenen Feldern sein, prüfe beide gängigen
    String iban = 'IBAN nicht verfügbar';
    if (json['account_identifiers']?['iban'] != null &&
        json['account_identifiers']['iban']
            is List && // Prüfe, ob es eine Liste ist
        json['account_identifiers']['iban'].isNotEmpty) {
      iban = json['account_identifiers']['iban'][0];
    } else if (json['account_routing'] != null &&
        json['account_routing'] is List && // Prüfe, ob es eine Liste ist
        json['account_routing'].isNotEmpty &&
        json['account_routing'][0]
            is Map && // Prüfe, ob das erste Element eine Map ist
        json['account_routing'][0]['address'] != null) {
      // Manchmal ist die IBAN unter account_routing -> address versteckt
      iban = json['account_routing'][0]['address'];
      // Bereinige ggf. zusätzliche Infos, falls vorhanden (selten)
      if (iban.contains(',')) {
        iban = iban.split(',')[0].trim();
      }
    }

    return Account(
      accountId: json['account_id'] as String? ?? 'N/A', // Sicherer Zugriff
      displayName:
          json['display_name'] as String? ??
          'Unbekanntes Konto', // Sicherer Zugriff
      accountNumber: iban,
      balance: finalBalance,
      currency: json['currency'] as String? ?? 'EUR', // Sicherer Zugriff
    );
  }
}
