import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async'; // Notwendig für den FutureBuilder

// Importiere deine neuen Service- und Model-Dateien
import 'services/truelayer_service.dart'; // Pfad ggf. anpassen
import 'models/account_model.dart';    // Pfad ggf. anpassen

// Importiere Pakete für Auth Flow und Secure Storage
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // Für den Token-Austausch (Backend empfohlen!)
import 'dart:convert';                   // Für den Token-Austausch

// Hauptfunktion, die die App startet
void main() {
  runApp(const MyApp());
}

// --- Farb- und Stilkonstanten für das Design ---
class AppTheme {
  static const Color primaryColor = Color(0xFF0A1931);
  static const Color secondaryColor = Color(0xFF183B56);
  static const Color accentColor = Color(0xFF00BFFF);
  static const Color textColor = Color(0xFFEFEFEF);
  static const Color subtleTextColor = Color(0xFFB0B0B0);
}

// Das Haupt-Widget der Anwendung
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.primaryColor,
        primaryColor: AppTheme.primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentColor,
          secondary: AppTheme.accentColor,
          background: AppTheme.primaryColor,
          surface: AppTheme.secondaryColor,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: AppTheme.textColor,
          onSurface: AppTheme.textColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppTheme.accentColor),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppTheme.secondaryColor,
          selectedItemColor: AppTheme.accentColor,
          unselectedItemColor: AppTheme.subtleTextColor,
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
        cardTheme: CardThemeData(
          color: AppTheme.secondaryColor.withOpacity(0.8),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.accentColor.withOpacity(0.2)),
          ),
        ),
         textTheme: const TextTheme(
           headlineSmall: TextStyle( // Früher headline6
             color: AppTheme.textColor,
             fontWeight: FontWeight.bold,
             fontSize: 20, // Beispielgröße
           ),
           titleLarge: TextStyle( // Früher subtitle1
             color: AppTheme.textColor,
             fontSize: 18, // Beispielgröße
             fontWeight: FontWeight.w600,
           ),
           bodyLarge: TextStyle( // Früher bodyText1
             color: AppTheme.textColor,
             fontSize: 16, // Beispielgröße
           ),
           bodyMedium: TextStyle( // Früher bodyText2
             color: AppTheme.subtleTextColor,
             fontSize: 14, // Beispielgröße
           ),
            bodySmall: TextStyle( // Früher caption
             color: AppTheme.subtleTextColor,
             fontSize: 12, // Beispielgröße
           ),
           // Füge hier weitere Textstile hinzu, falls benötigt
         ),
         elevatedButtonTheme: ElevatedButtonThemeData(
           style: ElevatedButton.styleFrom(
             backgroundColor: AppTheme.accentColor, // Hintergrundfarbe
             foregroundColor: Colors.black, // Textfarbe
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(12),
             ),
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
           ),
         ),
    );
  }
}

// --- Haupt-Shell der App mit unterer Navigation ---
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Erstelle eine Instanz des Service und Storage
  final TrueLayerService _apiService = TrueLayerService();
  final _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false; // Status, ob ein Token vorhanden ist

  // Liste der Seiten-Widgets
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Prüfe beim Start, ob ein Token existiert

     // Initialisiere die _pages Liste hier, nachdem _apiService verfügbar ist
    _pages = <Widget>[
      AccountsOverviewPage(apiService: _apiService), // Service übergeben
      PaymentHistoryPage(), // Diese Seite verwendet noch Platzhalter
      AnalysisPage(), // Diese Seite verwendet noch Platzhalter
    ];
  }

  // Prüft, ob ein Access Token gespeichert ist
  Future<void> _checkLoginStatus() async {
    final token = await _storage.read(key: 'truelayer_access_token');
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
    });
     // Wenn eingeloggt, lade die Konten neu (optional, falls die Seite das nicht selbst tut)
     if (_isLoggedIn && _selectedIndex == 0) {
       // Hier könnte man einen Neuladen-Mechanismus in AccountsOverviewPage auslösen
       // z.B. über einen GlobalKey oder einen State Management Ansatz
     }
  }

  // Wird aufgerufen, nachdem der Login-Flow erfolgreich war
  void _onLoginSuccess() {
    _checkLoginStatus(); // Aktualisiere den Login-Status
    // Wechsle zur Kontenübersicht und löse dort ggf. Neuladen aus
    _onItemTapped(0);
  }

    // Wird aufgerufen, wenn auf Logout geklickt wird
  Future<void> _logout() async {
    await _storage.delete(key: 'truelayer_access_token');
    await _storage.delete(key: 'truelayer_refresh_token');
    _checkLoginStatus(); // Aktualisiere den Status
     // Optional: Navigiere zu einer Login-Seite oder zeige eine Meldung
     _onItemTapped(0); // Zurück zur (jetzt leeren) Kontenübersicht
  }


  static const List<String> _pageTitles = [
    'Kontenübersicht',
    'Zahlungshistorie',
    'Analyse',
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
      // Übergib Callbacks an den Drawer
      drawer: AppDrawer(
              onLoginSuccess: _onLoginSuccess,
              onLogout: _logout,
              isLoggedIn: _isLoggedIn,
            ),
      // Zeige entweder die Seiten oder eine Login-Aufforderung an
      body: _isLoggedIn
          ? IndexedStack(index: _selectedIndex, children: _pages)
          : Center(
             child: Padding(
               padding: const EdgeInsets.all(20.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.lock_outline, size: 60, color: AppTheme.accentColor),
                   const SizedBox(height: 20),
                   Text(
                     'Bitte verbinden',
                     style: Theme.of(context).textTheme.headlineSmall,
                     textAlign: TextAlign.center,
                   ),
                     const SizedBox(height: 10),
                   Text(
                     'Öffne das Menü und wähle "Mit Bank verbinden", um deine Konten anzuzeigen.',
                     style: Theme.of(context).textTheme.bodyMedium,
                     textAlign: TextAlign.center,
                   ),
                    const SizedBox(height: 30),
                   ElevatedButton.icon(
                     icon: const Icon(Icons.link),
                     label: const Text('Menü öffnen'),
                     onPressed: () {
                       Scaffold.of(context).openDrawer(); // Öffnet den Drawer
                     },
                   ),
                 ],
               ),
             ),
           ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Konten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.manage_history),
            label: 'Historie',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analyse',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- Das seitliche Menü (Drawer) ---
class AppDrawer extends StatelessWidget {
  final VoidCallback onLoginSuccess; // Callback für erfolgreichen Login
  final VoidCallback onLogout;       // Callback für Logout
  final bool isLoggedIn;             // Aktueller Login-Status


  const AppDrawer({
    super.key,
    required this.onLoginSuccess,
    required this.onLogout,
    required this.isLoggedIn,
    });

  // --- TrueLayer Authentifizierungs-Flow ---
  Future<void> authenticateWithTrueLayer(BuildContext context) async {
    // Definiere deine TrueLayer App-Details
    const clientId = 'sandbox-finanzmanagementapp-159eef'; // <-- HIER ERSETZEN!
    const redirectUri = 'finanzapp://auth?code=XYZ123'; // <-- HIER ERSETZEN! z.B. 'com.deineapp.myapp://callback'
    const callbackUrlScheme = 'http://localhost:3000/callback'; // <-- HIER ERSETZEN! (Schema aus redirectUri)
    const scopes = 'info accounts balance transactions offline_access'; // Benötigte Berechtigungen

    // Baue die Auth-URL
    final authUrl = Uri.https('auth.truelayer.com', '/', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes,
      'providers': 'uk-ob-all uk-oauth-all', // Beispiel-Provider, anpassen!
      // 'state': '...', // Optional: Zufälligen Wert für CSRF-Schutz senden
      // 'nonce': '...', // Optional: Zufälligen Wert für Replay-Schutz senden
    });

    try {
      // Starte den Web-Authentifizierungs-Flow
      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackUrlScheme, // Schema deiner Redirect URI
      );

      // Extrahiere den Autorisierungscode aus der zurückgegebenen URL
      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        print('Erfolgreich Code erhalten: $code'); // Debugging

        // !!! SICHERHEITSHINWEIS !!!
        // SENDE DIESEN 'code' AN DEIN SICHERES BACKEND!
        // Das Backend tauscht den Code + Client Secret gegen Access/Refresh Tokens.
        // Das Backend sendet die Tokens sicher zurück an die App.

        // ----- Beispielhafter (UNSICHERER!) direkter Token-Austausch (NUR FÜR TESTS!) -----
        // NUR VERWENDEN, WENN DU KEIN BACKEND HAST UND DIE RISIKEN VERSTEHST!
        final tokenResponse = await http.post(
          Uri.parse('https://auth.truelayer.com/connect/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'authorization_code',
            'client_id': clientId,
            'client_secret': '87508e64-e5bc-4208-8e17-ee0bdbc88b28', // <-- SEHR UNSICHER IN DER APP!
            'redirect_uri': redirectUri,
            'code': code,
          },
        );

        if (tokenResponse.statusCode == 200) {
           final tokenData = json.decode(tokenResponse.body);
           final accessToken = tokenData['access_token'];
           final refreshToken = tokenData['refresh_token']; // Wichtig für spätere Erneuerung

           // Speichere die erhaltenen Tokens sicher
           const storage = FlutterSecureStorage();
           await storage.write(key: 'truelayer_access_token', value: accessToken);
           await storage.write(key: 'truelayer_refresh_token', value: refreshToken);

           print('Tokens erfolgreich erhalten und gespeichert.'); // Debugging
           onLoginSuccess(); // Rufe den Callback auf, um die UI zu aktualisieren
           Navigator.pop(context); // Schließe den Drawer

        } else {
           print('Fehler beim Token-Austausch: ${tokenResponse.body}');
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Fehler beim Token-Austausch: ${tokenResponse.statusCode}')),
           );
        }
        // ----- Ende des unsicheren Beispiels -----


        // Wenn du ein Backend verwendest, würde der Code hier so aussehen:
        // final tokens = await sendCodeToBackend(code); // Deine Backend-Funktion
        // if (tokens != null) {
        //   await _storage.write(key: 'truelayer_access_token', value: tokens['access_token']);
        //   await _storage.write(key: 'truelayer_refresh_token', value: tokens['refresh_token']);
        //   onLoginSuccess();
        //   Navigator.pop(context); // Schließe den Drawer
        // } else {
        //   // Fehlerbehandlung für Backend-Kommunikation
        // }

      } else {
        print('Fehler: Kein Code in der Antwort-URL gefunden.');
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Authentifizierung fehlgeschlagen: Kein Code erhalten.')),
         );
      }
    } catch (e) {
      print('Authentifizierungsfehler: $e');
      // Zeige dem Benutzer eine Fehlermeldung
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentifizierungsfehler: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.primaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              image: DecorationImage(
                fit: BoxFit.cover,
                opacity: 0.1,
                image: NetworkImage(
                  "https://www.transparenttextures.com/patterns/cubes.png",
                ),
              ),
            ),
            child: Text(
              'Menü',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Zeige "Verbinden" oder "Trennen/Logout" Button basierend auf Login-Status
          if (!isLoggedIn)
            ListTile(
              leading: const Icon(
                Icons.link,
                color: AppTheme.accentColor,
              ),
              title: const Text('Mit Bank verbinden'),
              onTap: () => authenticateWithTrueLayer(context), // Starte den Auth-Flow
            ),

          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: AppTheme.accentColor,
            ),
            title: const Text('Einstellungen'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: AppTheme.accentColor,
            ),
            title: const Text('Profil'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: AppTheme.secondaryColor),
          if (isLoggedIn)
             ListTile(
               leading: const Icon(Icons.logout, color: AppTheme.subtleTextColor),
               title: const Text('Verbindung trennen'),
               onTap: () {
                 onLogout(); // Logout-Funktion aufrufen
                 Navigator.pop(context); // Drawer schließen
               }
             ),
        ],
      ),
    );
  }
}

// --- SEITE 1: Kontenübersicht (MIT API-DATEN) ---
class AccountsOverviewPage extends StatefulWidget {
  final TrueLayerService apiService; // Service wird jetzt übergeben

  const AccountsOverviewPage({super.key, required this.apiService});

  @override
  State<AccountsOverviewPage> createState() => _AccountsOverviewPageState();
}

class _AccountsOverviewPageState extends State<AccountsOverviewPage> {
  // Ein Future, das die Liste der Konten halten wird.
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Lade Konten beim Initialisieren
  }

  // Methode zum (Neu-)Laden der Konten
  void _loadAccounts() {
     // Prüfe, ob das Widget noch im Baum ist, bevor setState aufgerufen wird
    if (mounted) {
      setState(() {
        _accountsFuture = widget.apiService.getAccounts();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // FutureBuilder wartet auf das Ergebnis des API-Aufrufs und baut die UI entsprechend.
    return FutureBuilder<List<Account>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        // Fall 1: Während die Daten geladen werden, zeige einen Ladekreis.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Fall 2: Wenn ein Fehler aufgetreten ist.
        if (snapshot.hasError) {
          // Zeige den Fehler an und biete ggf. einen "Erneut versuchen"-Button
           return Center(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    SizedBox(height: 16),
                   Text(
                     'Fehler beim Laden der Konten:\n${snapshot.error}',
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.redAccent),
                   ),
                    SizedBox(height: 20),
                   ElevatedButton.icon(
                       icon: const Icon(Icons.refresh),
                       label: const Text('Erneut versuchen'),
                       onPressed: _loadAccounts, // Ruft die Ladefunktion erneut auf
                     )
                 ],
               ),
             ),
           );
        }

        // Fall 3: Wenn keine Daten vorhanden sind (API gibt eine leere Liste zurück).
        // Überprüft explizit auf null oder leere Liste
         if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
           return Center(
             child: Padding(
               padding: const EdgeInsets.all(20.0),
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.accentColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Konten gefunden',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                      ),
                     const SizedBox(height: 8),
                     Text(
                       'Es wurden keine Konten über die verbundene Bank abgerufen.',
                       style: Theme.of(context).textTheme.bodyMedium,
                       textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 20),
                        ElevatedButton.icon(
                         icon: const Icon(Icons.refresh),
                         label: const Text('Aktualisieren'),
                         onPressed: _loadAccounts,
                       )
                  ],
               ),
             )
           );
         }


        // Fall 4: Daten wurden erfolgreich geladen.
        final accounts = snapshot.data!;
        // Berechne die Gesamtbilanz aus den echten Daten.
        final totalBalance = accounts.fold<double>(
          0.0,
          (sum, item) => sum + item.balance, // Annahme: Alle Konten in gleicher Währung oder Umrechnung nötig
        );
         // Finde die Währung (vereinfacht, nimmt die erste)
        final currencySymbol = accounts.isNotEmpty ? accounts.first.currency : 'EUR'; // Standard auf EUR


        return RefreshIndicator( // Ermöglicht Pull-to-Refresh
           onRefresh: () async {
              _loadAccounts(); // Lade Konten neu
           },
           child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TotalBalanceCard(balance: '${totalBalance.toStringAsFixed(2)} $currencySymbol'),
              const SizedBox(height: 24),
              Text(
                "Deine Konten",
                 style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Erstelle eine AccountCard für jedes Konto aus der API-Antwort
              if (accounts.isEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 20.0),
                   child: Text("Keine Konten für diese Verbindung gefunden.", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                 )
              else
                 ...accounts.map( (account) => AccountCard(
                      accountName: account.displayName,
                      balance: '${account.balance.toStringAsFixed(2)} ${account.currency}',
                      iban: account.accountNumber,
                   ),
                 ).toList(),
               ],
             ),
         );
      },
    );
  }
}


// --- SEITE 2: Zahlungshistorie (verwendet noch Platzhalter) ---
class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Diese Daten sind noch Platzhalter. Der Prozess zur Anbindung der
    // Transaktions-API wäre sehr ähnlich zu dem der Konten.
    // Du müsstest eine getTransactions Methode im TrueLayerService erstellen
    // und diese Seite mit einem FutureBuilder oder State Management verbinden.

    final transactions = [
      {
        'type': 'expense',
        'merchant': 'Supermarkt',
        'amount': '- 85,20 €',
        'date': 'Heute',
      },
      {
        'type': 'income',
        'merchant': 'Gehalt',
        'amount': '+ 2.800,00 €',
        'date': 'Gestern',
      },
      {
        'type': 'expense',
        'merchant': 'Restaurant',
        'amount': '- 45,50 €',
        'date': '18. Okt',
      },
      // Füge mehr Beispieltransaktionen hinzu...
        {
        'type': 'expense',
        'merchant': 'Online-Shop',
        'amount': '- 120,00 €',
        'date': '17. Okt',
      },
       {
        'type': 'income',
        'merchant': 'Rückerstattung',
        'amount': '+ 35,00 €',
        'date': '16. Okt',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionListItem(
          isExpense: tx['type'] == 'expense',
          merchant: tx['merchant']!,
          amount: tx['amount']!,
          date: tx['date']!,
        );
      },
    );
  }
}

// --- SEITE 3: Analyse (verwendet noch Platzhalter) ---
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Diese Seite benötigt ebenfalls Daten von der API (z.B. Transaktionen)
    // um sinnvolle Analysen durchzuführen.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Finanzanalyse",
             style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: AppTheme.accentColor),
                  SizedBox(height: 16),
                  Text(
                    "Ausgaben-Diagramm (Platzhalter)",
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Hier könnte eine Visualisierung deiner Ausgaben nach Kategorie angezeigt werden.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.subtleTextColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AnalysisTile(
                  title: "Ausgaben Monat",
                  value: "1.245,67 €", // Placeholder
                  icon: Icons.arrow_downward,
                   iconColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalysisTile(
                  title: "Einnahmen Monat",
                  value: "2.800,00 €", // Placeholder
                  icon: Icons.arrow_upward,
                  iconColor: Colors.greenAccent,
                ),
              ),
            ],
          ),
            const SizedBox(height: 24),
            Text(
            "Budgets (Beispiel)",
             style: Theme.of(context).textTheme.headlineSmall,
          ),
           const SizedBox(height: 16),
           BudgetTile(category: "Lebensmittel", spent: 350.50, budget: 500),
           BudgetTile(category: "Freizeit", spent: 180.20, budget: 250),
           BudgetTile(category: "Transport", spent: 95.00, budget: 100),
        ],
      ),
    );
  }
}


// --- WIDGETS (Unverändert, bis auf kleine Anpassungen/Textstile) ---

class TotalBalanceCard extends StatelessWidget {
  final String balance;
  const TotalBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
            gradient: LinearGradient( // Optional: Fügt einen leichten Gradienten hinzu
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
               colors: [
                 AppTheme.secondaryColor.withOpacity(0.3),
                 AppTheme.accentColor.withOpacity(0.1),
               ],
             ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Gesamtguthaben',
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                balance,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1, // Etwas mehr Abstand
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class AccountCard extends StatelessWidget {
  final String accountName;
  final String balance;
  final String iban;

  const AccountCard({
    super.key,
    required this.accountName,
    required this.balance,
    required this.iban,
  });

  @override
  Widget build(BuildContext context) {
    // Extrahiere den reinen Betrag für die Farbprüfung
    final numericBalance = double.tryParse(balance.split(' ')[0].replaceAll(',', '.')) ?? 0.0;
    final balanceColor = numericBalance < 0 ? Colors.redAccent : Colors.greenAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded( // Damit langer Text umbricht
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                     style: Theme.of(context).textTheme.titleLarge,
                     overflow: TextOverflow.ellipsis, // Verhindert Überlaufen
                  ),
                  const SizedBox(height: 4),
                  Text(
                     iban,
                     style: Theme.of(context).textTheme.bodyMedium,
                     overflow: TextOverflow.ellipsis, // Verhindert Überlaufen
                  ),
                ],
              ),
            ),
             const SizedBox(width: 16), // Abstand zwischen Text und Betrag
            Text(
              balance,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
              textAlign: TextAlign.right, // Rechtsbündig
            ),
          ],
        ),
      ),
    );
  }
}


class TransactionListItem extends StatelessWidget {
  final bool isExpense;
  final String merchant;
  final String amount;
  final String date;

  const TransactionListItem({
    super.key,
    required this.isExpense,
    required this.merchant,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isExpense ? Colors.redAccent : Colors.greenAccent;
    final iconData = isExpense ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.2),
          child: Icon(
            iconData,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(merchant, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(date, style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
             fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class AnalysisTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor; // Hinzugefügt für Flexibilität

  const AnalysisTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppTheme.accentColor, // Standardfarbe
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24), // Verwendet iconColor
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
               style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Neues Widget für Budget-Anzeige (Beispiel)
class BudgetTile extends StatelessWidget {
  final String category;
  final double spent;
  final double budget;

  const BudgetTile({
    super.key,
    required this.category,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (budget > 0) ? (spent / budget) : 0.0;
    final progressColor = percentage > 1.0 ? Colors.redAccent : (percentage > 0.8 ? Colors.orangeAccent : Colors.greenAccent);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${spent.toStringAsFixed(2)} € / ${budget.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0), // Stelle sicher, dass Wert zwischen 0 und 1 liegt
              backgroundColor: AppTheme.primaryColor.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6, // Dickere Leiste
            ),
          ],
        ),
      ),
    );
  }
}