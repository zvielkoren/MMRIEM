class AppConstants {
  static const String appName = 'MMRIEM';
  static const String appVersion = '1.0.0';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';

  // Storage paths
  static const String profileImagesPath = 'profile_images';

  // Shared preferences keys
  static const String themeKey = 'isDark';
  static const String languageKey = 'language';

  // API endpoints
  static const String baseUrl = 'https://api.mmriem.com';

  // Error messages
  static const String networkError = 'אין חיבור לאינטרנט';
  static const String generalError = 'שגיאה כללית';
  static const String authError = 'שגיאה בהתחברות';

  // Validation messages
  static const String emailRequired = 'נא להזין אימייל';
  static const String emailInvalid = 'נא להזין כתובת אימייל תקינה';
  static const String passwordRequired = 'נא להזין סיסמה';
  static const String phoneRequired = 'נא להזין מספר טלפון';
  static const String phoneInvalid = 'נא להזין מספר טלפון תקין (05X-XXX-XXXX)';

  // Success messages
  static const String loginSuccess = 'התחברות בוצעה בהצלחה';
  static const String logoutSuccess = 'התנתקות בוצעה בהצלחה';
}
