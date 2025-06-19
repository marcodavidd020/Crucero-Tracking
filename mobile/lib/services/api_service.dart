import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    print("API POST request a: $baseUrl/$endpoint");
    print("Datos enviados: ${jsonEncode(data)}");
    
    final response = await _client.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print("Código de respuesta: ${response.statusCode}");
    print("Cuerpo de respuesta: ${response.body}");
    
    if(response.statusCode < 400) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      print("JSON decodificado: $jsonResponse");
      return jsonResponse;
    } else {
      print("Error en la respuesta: ${response.body}");
      throw Exception('Failed to post data: ${response.statusCode} - ${response.body}');
    }
  }
  Future<void> put(String endpoint, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if(response.statusCode >= 400) {
      throw Exception('Failed to update data: ${response.statusCode}');
    }
  }

  Future<void> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if(response.statusCode >= 400) {
      throw Exception('Failed to delete data: ${response.statusCode}');
    }
  }
}