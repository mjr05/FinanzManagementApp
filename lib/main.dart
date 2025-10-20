import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async'; // Notwendig für den FutureBuilder

// Importiere deine neuen Service- und Model-Dateien
import 'services/truelayer_service.dart';
import 'models/account_model.dart';

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
          headlineSmall: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppTheme.textColor),
          bodyMedium: TextStyle(color: AppTheme.subtleTextColor),
        ),
      ),
      home: const MainShell(),
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
  static const List<Widget> _pages = <Widget>[
    AccountsOverviewPage(), // Diese Seite ist jetzt mit der API verbunden
    PaymentHistoryPage(), // Diese Seite verwendet noch Platzhalter
    AnalysisPage(), // Diese Seite verwendet noch Platzhalter
  ];
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
      drawer: const AppDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
  const AppDrawer({super.key});
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
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.subtleTextColor),
            title: const Text('Abmelden'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// --- SEITE 1: Kontenübersicht (MIT API-DATEN) ---
class AccountsOverviewPage extends StatefulWidget {
  const AccountsOverviewPage({super.key});

  @override
  State<AccountsOverviewPage> createState() => _AccountsOverviewPageState();
}

class _AccountsOverviewPageState extends State<AccountsOverviewPage> {
  // Ein Future, das die Liste der Konten halten wird.
  late Future<List<Account>> _accountsFuture;
  final TrueLayerService _apiService = TrueLayerService();

  @override
  void initState() {
    super.initState();
    // Starte den API-Aufruf, wenn das Widget zum ersten Mal erstellt wird.
    _accountsFuture = _apiService.getAccounts();
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

        // Fall 2: Wenn ein Fehler aufgetreten ist (z.B. falscher Token, keine Internetverbindung).
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Fehler beim Laden der Daten:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        // Fall 3: Wenn keine Daten vorhanden sind (API gibt eine leere Liste zurück).
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Keine Konten gefunden.'));
        }

        // Fall 4: Daten wurden erfolgreich geladen.
        final accounts = snapshot.data!;
        // Berechne die Gesamtbilanz aus den echten Daten.
        final totalBalance = accounts.fold<double>(
          0.0,
          (sum, item) => sum + item.balance,
        );

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TotalBalanceCard(balance: '${totalBalance.toStringAsFixed(2)} €'),
            const SizedBox(height: 24),
            Text(
              "Deine Konten",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Erstelle eine AccountCard für jedes Konto aus der API-Antwort
            ...accounts
                .map(
                  (account) => AccountCard(
                    accountName: account.displayName,
                    balance:
                        '${account.balance.toStringAsFixed(2)} ${account.currency}',
                    iban: account.accountNumber,
                  ),
                )
                .toList(),
          ],
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
                    "Hier könnte eine Visualisierung deiner Ausgaben angezeigt werden.",
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
                  value: "1.245,67 €",
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnalysisTile(
                  title: "Einnahmen Monat",
                  value: "2.800,00 €",
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS (Unverändert) ---
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gesamtguthaben',
                style: TextStyle(color: AppTheme.subtleTextColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                balance,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(iban, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            Text(
              balance,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: balance.startsWith('-')
                    ? Colors.redAccent
                    : Colors.greenAccent,
              ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.redAccent : Colors.greenAccent,
            size: 20,
          ),
        ),
        title: Text(merchant),
        subtitle: Text(date, style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.redAccent : Colors.greenAccent,
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

  const AnalysisTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 24),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
