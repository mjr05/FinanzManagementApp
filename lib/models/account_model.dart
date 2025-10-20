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
    return Account(
      accountId: json['account_id'] ?? 'N/A',
      displayName: json['display_name'] ?? 'Unbekanntes Konto',
      // Die Kontonummer ist oft in einem verschachtelten Objekt
      accountNumber:
          json['account_identifiers']?['iban']?[0] ?? 'IBAN nicht verfügbar',
      balance: (json['balance']?['current'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EUR',
    );
  }
}
