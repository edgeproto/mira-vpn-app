import 'package:flutter/material.dart';

void main() {
  runApp(const MiraVpnApp());
}

class MiraVpnApp extends StatelessWidget {
  const MiraVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mira VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MiraHomePage(title: 'Mira VPN'),
    );
  }
}

class MiraHomePage extends StatefulWidget {
  const MiraHomePage({super.key, required this.title});

  final String title;

  @override
  State<MiraHomePage> createState() => _MiraHomePageState();
}

class _MiraHomePageState extends State<MiraHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Scaffold ready.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: theme.textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
