import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Error answered by the API, already translated for the user.
class ApiException implements Exception {
  ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => message;
}

/// REST client of the Innova Carty API. Sends the JWT of the signed-in user.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String? token;

  /// Called when the token expires (401), to go back to the login.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? const {})));

  Future<dynamic> patch(String path, Object body) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> _request(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(0, 'El servidor está despertando (plan gratis de Render). Intenta de nuevo en un momento.');
    } on Exception {
      throw ApiException(0, 'No hay conexión con el servidor. Revisa tu internet.');
    }
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final response = await _request(request);
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }

    var message = 'Error ${response.statusCode}';
    try {
      final data = jsonDecode(text);
      if (data is Map && data['message'] != null) message = data['message'].toString();
    } catch (_) {
      // Not JSON (e.g. Render page while it wakes up).
    }
    if (response.statusCode == 502 || response.statusCode == 503) {
      message = 'El servidor está despertando (plan gratis de Render). Intenta de nuevo en un momento.';
    }
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(response.statusCode, _translate(message));
  }

  /// Spanish text for the messages of the API.
  static String _translate(String message) {
    const known = {
      'Invalid email or password': 'Correo o contraseña incorrectos.',
      'Wrong PIN': 'PIN incorrecto.',
      'That email already has an account': 'Ese correo ya tiene una cuenta.',
      'The password needs at least 6 characters': 'La contraseña necesita al menos 6 caracteres.',
      'Write a valid email': 'Escribe un correo válido.',
      'Write your name': 'Escribe tu nombre.',
      'You have no cart linked': 'Aún no tienes un carrito vinculado.',
      'This cart is already linked to another shopper': 'Este carrito ya está vinculado a otro comprador.',
      'The cart is offline': 'El carrito está sin conexión.',
      'This cart has no active shopping session': 'Este carrito no tiene una compra activa.',
      'This order is already paid': 'Esta compra ya está pagada.',
      'Payment paused: weight discrepancy, ask a supervisor': 'Pago en pausa: el peso no coincide. Llama a un supervisor.',
      'The cart is locked, ask a supervisor': 'El carrito está bloqueado. Llama a un supervisor.',
      'The cart is empty': 'El carrito está vacío.',
      'Link this cart to your app before paying': 'Vincula el carrito a tu app antes de pagar.',
      'Your session expired, sign in again': 'Tu sesión venció. Ingresa de nuevo.',
      'Sign in first': 'Ingresa a tu cuenta.',
      'This action needs an administrator account': 'Esta acción necesita una cuenta de administrador.',
    };
    if (known.containsKey(message)) return known[message]!;
    if (message.startsWith('Cart ') && message.endsWith(' not found')) return 'No existe ese carrito.';
    if (message.endsWith(' is not locked')) return 'El carrito no está bloqueado.';
    return message;
  }
}
