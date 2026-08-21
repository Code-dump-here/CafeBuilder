// Runs the app's own parsers over the live response the proposals page gets,
// so a parse failure shows up here instead of as an empty screen.
import 'dart:convert';
import 'dart:io';

import 'lib/models/responses/api_responses.dart';

Future<void> main(List<String> args) async {
  final token = args[0];
  final postId = args[1];

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(
    'http://localhost:5199/api/applies?pageNumber=1&pageSize=50&postId=$postId',
  ));
  req.headers.set('Authorization', 'Bearer $token');
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  print('HTTP ${res.statusCode}, ${text.length} bytes');

  final body = jsonDecode(text) as Map<String, dynamic>;
  print('items in payload: ${(body['items'] as List).length}');

  try {
    final page = PaginationResponse.fromJson(body, ApplyResponse.fromJson);
    print('PARSED OK — ${page.items.length} application(s)');
    for (final a in page.items) {
      print('  ${a.providerDisplayName} | ${a.status} '
          '| surveyCount=${a.surveyCount} '
          '| hasCompletedSurvey=${a.hasCompletedSurvey} '
          '| surveyedAt=${a.latestSurveyedAt}');
    }
  } catch (e, st) {
    print('PARSE FAILED: $e');
    print(st.toString().split('\n').take(6).join('\n'));
    exitCode = 1;
  }
  client.close();
}
