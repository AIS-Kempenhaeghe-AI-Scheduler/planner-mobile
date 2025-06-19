import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// A utility class to help make authenticated HTTP requests with automatic token refresh
class AuthenticatedHttpClient {
  final AuthService _authService;

  AuthenticatedHttpClient(this._authService);

  /// Make an authenticated GET request with automatic token refresh on 401
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _makeAuthenticatedRequest(() async {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      if (_authService.authToken != null) {
        requestHeaders['Authorization'] = 'Bearer ${_authService.authToken}';
      }

      return await http.get(Uri.parse(url), headers: requestHeaders);
    });
  }

  /// Make an authenticated POST request with automatic token refresh on 401
  Future<http.Response> post(String url,
      {Map<String, String>? headers, Object? body}) async {
    return _makeAuthenticatedRequest(() async {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      if (_authService.authToken != null) {
        requestHeaders['Authorization'] = 'Bearer ${_authService.authToken}';
      }

      return await http.post(Uri.parse(url),
          headers: requestHeaders, body: body);
    });
  }

  /// Make an authenticated PUT request with automatic token refresh on 401
  Future<http.Response> put(String url,
      {Map<String, String>? headers, Object? body}) async {
    return _makeAuthenticatedRequest(() async {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      if (_authService.authToken != null) {
        requestHeaders['Authorization'] = 'Bearer ${_authService.authToken}';
      }

      return await http.put(Uri.parse(url),
          headers: requestHeaders, body: body);
    });
  }

  /// Make an authenticated DELETE request with automatic token refresh on 401
  Future<http.Response> delete(String url,
      {Map<String, String>? headers}) async {
    return _makeAuthenticatedRequest(() async {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      if (_authService.authToken != null) {
        requestHeaders['Authorization'] = 'Bearer ${_authService.authToken}';
      }

      return await http.delete(Uri.parse(url), headers: requestHeaders);
    });
  }

  /// Helper method to handle 401 errors and retry with refresh token
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    final response = await requestFunction();

    if (response.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _authService.refreshAuthToken();
      if (refreshed) {
        // Retry the request with new token
        return await requestFunction();
      }
    }

    return response;
  }
}
