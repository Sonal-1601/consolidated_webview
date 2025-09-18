import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _urlKey = 'stored_url';
  
  // Store URL in shared preferences
  static Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }
  
  // Retrieve URL from shared preferences
  static Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }
  
  // Check if URL exists in shared preferences
  static Future<bool> hasUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_urlKey);
  }
  
  // Clear stored URL
  static Future<void> clearUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
  }
}
