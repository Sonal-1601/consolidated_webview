import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/network_service.dart';
import 'webview_screen.dart';

class UrlInputScreen extends StatefulWidget {
  const UrlInputScreen({super.key});

  @override
  State<UrlInputScreen> createState() => _UrlInputScreenState();
}

class _UrlInputScreenState extends State<UrlInputScreen> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredUrl();
  }

  Future<void> _loadStoredUrl() async {
    final storedUrl = await PreferencesService.getUrl();
    if (storedUrl != null) {
      _urlController.text = storedUrl;
    }
  }

  Future<void> _saveAndLaunchUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check network connectivity first
      final hasInternet = await NetworkService.hasInternetConnection();
      if (!hasInternet) {
        setState(() {
          _isLoading = false;
        });
        NetworkService.showNetworkErrorDialog(context);
        return;
      }
      
      final url = _urlController.text.trim();
      await PreferencesService.saveUrl(url);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WebViewScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }
    
    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }
    
    try {
      Uri.parse(url);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your URL'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.web,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Website URL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the URL of the website you want to view',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                validator: _validateUrl,
                onFieldSubmitted: (_) => _saveAndLaunchUrl(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAndLaunchUrl,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Launch Website',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
