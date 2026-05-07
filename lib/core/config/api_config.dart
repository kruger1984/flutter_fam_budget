/// Base URL for [DioFactory] (trailing slash recommended).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.example.com/',
);
