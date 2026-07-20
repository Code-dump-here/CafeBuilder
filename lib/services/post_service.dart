import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/responses/api_responses.dart';

class CreatePostRequest {
  final String title;
  final String description;
  final String location;
  final String style;
  final String budgetTier;
  final String expectedStart;
  final List<String> requirements;

  CreatePostRequest({
    required this.title,
    required this.description,
    required this.location,
    required this.style,
    required this.budgetTier,
    required this.expectedStart,
    required this.requirements,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'style': style,
        'budgetTier': budgetTier,
        'expectedStart': expectedStart,
        'requirements': requirements,
      };
}

class PostResponse {
  final int id;
  final String title;
  final String description;
  final String location;
  final String style;
  final String budgetTier;
  final String expectedStart;
  final List<String> requirements;
  final DateTime createdAt;

  PostResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.style,
    required this.budgetTier,
    required this.expectedStart,
    required this.requirements,
    required this.createdAt,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) => PostResponse(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        location: json['location'] ?? '',
        style: json['style'] ?? '',
        budgetTier: json['budgetTier'] ?? '',
        expectedStart: json['expectedStart'] ?? '',
        requirements: (json['requirements'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );
}

class PostService {
  static Future<PaginationResponse<PostResponse>> getPosts({int pageNumber = 1, int pageSize = 10}) async {
    final response = await ApiClient.authGet('/posts', {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    final body = jsonDecode(response.body);
    return PaginationResponse.fromJson(
      body,
      (json) => PostResponse.fromJson(json),
    );
  }

  static Future<PostResponse> createPost(CreatePostRequest request) async {
    final response = await ApiClient.authPost('/posts', request.toJson());
    ApiClient.throwIfError(response);
    final body = jsonDecode(response.body);
    // Usually the response contains the created post in 'data' or directly.
    return PostResponse.fromJson(body['data'] ?? body);
  }
}
