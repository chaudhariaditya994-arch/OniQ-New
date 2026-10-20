import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReviewService {
  Future<Map<String, dynamic>> createReview({
    required File imageFile,
    required String userEmail,
    required String userRole,
    required String correctedLabel,
    String originalPrediction = '',
    double originalConfidence = 0.0,
    String comment = '',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.reviews))
      ..fields['user_email'] = userEmail
      ..fields['user_role'] = userRole
      ..fields['corrected_label'] = correctedLabel
      ..fields['original_prediction'] = originalPrediction
      ..fields['original_confidence'] = originalConfidence.toString()
      ..fields['comment'] = comment
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final decoded = json.decode(body) as Map<String, dynamic>;
    return {...decoded, '_status': streamed.statusCode};
  }

  Future<Map<String, dynamic>> getReview({
    required String id,
    required String requesterEmail,
    required String requesterRole,
  }) async {
    final uri = Uri.parse(ApiConfig.reviewById(id)).replace(queryParameters: {
      'requester_email': requesterEmail,
      'requester_role': requesterRole,
    });
    final resp = await http.get(uri);
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listMyReviews(String email) async {
    final resp = await http.get(Uri.parse(ApiConfig.reviewsByUser(email)));
    final body = json.decode(resp.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['reviews'] ?? []);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> listAllReviews(String requesterRole) async {
    final uri = Uri.parse(ApiConfig.reviews).replace(queryParameters: {
      'requester_role': requesterRole,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['reviews'] ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> updateReview({
    required String id,
    required String requesterEmail,
    required String requesterRole,
    String? correctedLabel,
    String? comment,
    String? status,
  }) async {
    final body = <String, dynamic>{
      'requester_email': requesterEmail,
      'requester_role': requesterRole,
    };
    if (correctedLabel != null) body['corrected_label'] = correctedLabel;
    if (comment != null) body['comment'] = comment;
    if (status != null) body['status'] = status;

    final resp = await http.patch(
      Uri.parse(ApiConfig.reviewById(id)),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  /// Downloads the reviews export ZIP. Throws on non-200.
  /// Returns (bytes, suggested filename from Content-Disposition).
  Future<({Uint8List bytes, String filename})> downloadExport(
      String requesterRole) async {
    final uri = Uri.parse(ApiConfig.reviewsExport).replace(queryParameters: {
      'requester_role': requesterRole,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      String detail = 'HTTP ${resp.statusCode}';
      try {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        if (body['detail'] != null) detail = body['detail'].toString();
      } catch (_) {}
      throw Exception(detail);
    }
    var filename = 'reviews-export.zip';
    final disp = resp.headers['content-disposition'];
    if (disp != null) {
      final m = RegExp(r'filename="?([^";]+)"?').firstMatch(disp);
      if (m != null) filename = m.group(1)!;
    }
    return (bytes: resp.bodyBytes, filename: filename);
  }

  Future<bool> deleteReview({
    required String id,
    required String requesterEmail,
    required String requesterRole,
  }) async {
    final uri = Uri.parse(ApiConfig.reviewById(id)).replace(queryParameters: {
      'requester_email': requesterEmail,
      'requester_role': requesterRole,
    });
    final resp = await http.delete(uri);
    if (resp.statusCode != 200) return false;
    final body = json.decode(resp.body) as Map<String, dynamic>;
    return body['success'] == true;
  }
}

const List<String> kReviewLabelOptions = [
  'Alternaria',
  'Bulb_Blight',
  'Caterpillar',
  'Fusarium',
  'Healthy',
  'Virosis',
  'Not_Onion',
  'Unsure',
];
