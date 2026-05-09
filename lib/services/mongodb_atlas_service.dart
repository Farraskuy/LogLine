import 'dart:convert';

import 'package:http/http.dart' as http;

class MongoDbAtlasService {
  MongoDbAtlasService({
    required this.endpoint,
    required this.apiKey,
    required this.dataSource,
    required this.database,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final String apiKey;
  final String dataSource;
  final String database;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'api-key': apiKey,
  };

  Future<Map<String, dynamic>> insertOne({
    required String collection,
    required Map<String, dynamic> document,
  }) async {
    return _post('insertOne', {
      'dataSource': dataSource,
      'database': database,
      'collection': collection,
      'document': document,
    });
  }

  Future<Map<String, dynamic>> updateOne({
    required String collection,
    required Map<String, dynamic> filter,
    required Map<String, dynamic> update,
    bool upsert = true,
  }) async {
    return _post('updateOne', {
      'dataSource': dataSource,
      'database': database,
      'collection': collection,
      'filter': filter,
      'update': {'\$set': update},
      'upsert': upsert,
    });
  }

  Future<Map<String, dynamic>> find({
    required String collection,
    Map<String, dynamic> filter = const {},
    int limit = 100,
  }) async {
    return _post('find', {
      'dataSource': dataSource,
      'database': database,
      'collection': collection,
      'filter': filter,
      'limit': limit,
    });
  }

  Future<Map<String, dynamic>> deleteOne({
    required String collection,
    required Map<String, dynamic> filter,
  }) async {
    return _post('deleteOne', {
      'dataSource': dataSource,
      'database': database,
      'collection': collection,
      'filter': filter,
    });
  }

  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      endpoint.resolve(action),
      headers: _headers,
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MongoDbAtlasException(response.statusCode, decoded);
    }
    return decoded;
  }
}

class MongoDbAtlasException implements Exception {
  MongoDbAtlasException(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  String toString() => 'MongoDbAtlasException($statusCode): $body';
}
