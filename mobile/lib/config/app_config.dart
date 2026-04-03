class AppConfig {
  // TODO: Replace with your Supabase project credentials
  static const String supabaseUrl = 'https://rankmykjnicectabtxdf.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_V0Oq0D3uOnV9PPL86ww_1A_qxcFAdcI';

  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';

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
