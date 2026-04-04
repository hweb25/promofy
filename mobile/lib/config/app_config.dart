class AppConfig {
  // TODO: Replace with your Supabase project credentials
  static const String supabaseUrl = 'https://rankmykjnicectabtxdf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhbmtteWtqbmljZWN0YWJ0eGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxODE0MTgsImV4cCI6MjA5MDc1NzQxOH0.MzJ2UZzCzaOX0BUqac1APZ8wdeh8KhQVTY1MXSWuzK8';

  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyAu5GpxNHKQ3zuSNCzFzDsFM9LO3WByvbs';

  // Geofencing defaults
  static const int defaultGeofenceRadiusMeters = 500;
  static const int maxDailyNotifications = 2;
  static const int cooldownHours = 24;
  static const int qrCodeExpiryMinutes = 30;

  // Subscription tier radius limits (meters)
  static const Map<String, int> tierRadiusLimits = {
    'free': 100,
    'premium': 1000,
    'gold': 5000,
  };

  // Subscription tier promotion limits
  static const Map<String, int> tierPromotionLimits = {
    'free': 1,
    'premium': 3,
    'gold': 999, // unlimited
  };
}
