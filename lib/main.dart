import 'package:flutter/material.dart';
import 'services/preferences_service.dart';
import 'screens/url_input_screen.dart';
import 'screens/webview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web View App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _hasStoredUrl = false;

  @override
  void initState() {
    super.initState();
    _checkStoredUrl();
  }

  Future<void> _checkStoredUrl() async {
    try {
      final hasUrl = await PreferencesService.hasUrl();
      setState(() {
        _hasStoredUrl = hasUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasStoredUrl = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    // If we have a stored URL, go directly to web view
    // Otherwise, show URL input screen
    return _hasStoredUrl ? const WebViewScreen() : const UrlInputScreen();
  }
}

