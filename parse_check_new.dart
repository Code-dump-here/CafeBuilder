// Runs the app's own parsers over the live responses the three new screens
// depend on, so a field-name mismatch shows up here rather than as a blank
// card in the running app.
//
//   dart run parse_check_new.dart <token> <projectId> <engagementId> <providerId>
import 'dart:convert';
import 'dart:io';

import 'lib/models/responses/api_responses.dart';
import 'lib/models/responses/change_order_responses.dart';
import 'lib/models/responses/provider_brand_responses.dart';
import 'lib/models/responses/site_profile_responses.dart';

const base = 'http://localhost:5199/api';

late final HttpClient client;
late final String token;
int failures = 0;

Future<dynamic> get(String path) async {
  final req = await client.getUrl(Uri.parse('$base$path'));
  req.headers.set('Authorization', 'Bearer $token');
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  if (res.statusCode >= 400) {
    throw 'HTTP ${res.statusCode} on $path — ${text.substring(0, text.length.clamp(0, 160))}';
  }
  return jsonDecode(text);
}

void check(String label, void Function() body) {
  try {
    body();
  } catch (e, st) {
    failures++;
    print('  FAIL  $label');
    print('        $e');
    print('        ${st.toString().split('\n').take(3).join('\n        ')}');
  }
}

Future<void> main(List<String> args) async {
  token = args[0];
  final projectId = args[1];
  final engagementId = args[2];
  final providerId = args[3];

  client = HttpClient();

  // ── Site profile ───────────────────────────────────────────────────────────
  print('── site profile ──');
  final rawProfile = await get('/site-profiles/by-project/$projectId');
  check('SiteProfileResponse', () {
    final profile =
        SiteProfileResponse.fromJson(rawProfile as Map<String, dynamic>);
    print('  PASS  ${profile.floors.length} floor(s), '
        '${profile.openings.length} opening(s), '
        'footprint ${profile.derivedFootprintM2} m², '
        'total ${profile.totalFloorAreaM2} m², '
        'orientation ${profile.orientation}');
    for (final floor in profile.floors) {
      print('        floor ${floor.floorNo} "${floor.label}" '
          '${floor.areaM2} m² — ${floor.purpose}');
    }
    for (final opening in profile.openings) {
      print('        ${kSiteOpeningLabels[opening.type]} ×${opening.quantity} '
          '${opening.widthM}×${opening.heightM} m '
          'floor=${opening.siteFloorId != null ? "set" : "none"}');
    }
  });

  // ── Change orders ──────────────────────────────────────────────────────────
  print('── change orders ──');
  final rawOrders = await get('/change-orders?projectWorkingId=$engagementId&pageSize=50');
  check('PaginationResponse<ChangeOrderResponse>', () {
    final page = PaginationResponse.fromJson(
      rawOrders as Map<String, dynamic>,
      ChangeOrderResponse.fromJson,
    );
    print('  PASS  ${page.items.length} order(s)');
    for (final order in page.items) {
      print('        ${order.status.padRight(9)} ${order.amount} VND  '
          '${kChangeOrderKindLabels[order.kind]}  '
          'raisedBy=${order.requestedByParty}  "${order.title}"');
    }
  });

  final rawSummary = await get('/change-orders/summary?projectWorkingId=$engagementId');
  check('ChangeOrderSummaryResponse', () {
    final summary =
        ChangeOrderSummaryResponse.fromJson(rawSummary as Map<String, dynamic>);
    print('  PASS  contract=${summary.contractValue} '
        'accepted=${summary.acceptedAmount} (${summary.acceptedCount}) '
        'pending=${summary.pendingAmount} (${summary.pendingCount}) '
        'committed=${summary.totalCommitted}');
  });

  // ── Provider brand + portfolio ─────────────────────────────────────────────
  print('── provider brand ──');
  final rawBrand = await get('/provider-brands/$providerId');
  check('ProviderBrandResponse', () {
    final brand =
        ProviderBrandResponse.fromJson(rawBrand as Map<String, dynamic>);
    print('  PASS  ${brand.displayName} — founded ${brand.foundedYear}, '
        '${brand.employeeCount} staff, ${brand.yearsExperience}y exp, '
        'rating ${brand.avgRating}/${brand.reviewCount}');
    print('        ${brand.socialLinks.length} link(s), '
        '${brand.serviceAreas.length} area(s), '
        '${brand.certificates.length} certificate(s)');
    for (final area in brand.serviceAreas) {
      print('        area: ${area.label}');
    }
    for (final cert in brand.certificates) {
      print('        cert: ${cert.name} '
          '(${kCertificateKindLabels[cert.kind]}) verified=${cert.isVerified}');
    }
  });

  final rawPortfolios =
      await get('/provider-portfolios?serviceProviderProfileId=$providerId&pageSize=20');
  check('PaginationResponse<ProviderPortfolioResponse>', () {
    final page = PaginationResponse.fromJson(
      rawPortfolios as Map<String, dynamic>,
      ProviderPortfolioResponse.fromJson,
    );
    print('  PASS  ${page.items.length} portfolio entry(ies)');
    for (final entry in page.items) {
      print('        "${entry.title}" ${kPortfolioRoleLabels[entry.role]} '
          '${entry.areaM2} m², ${entry.contractValue} VND, '
          '${entry.images.length} image(s)');
    }
  });

  client.close();
  print(failures == 0
      ? '\nall model parsers OK'
      : '\n$failures parser(s) failed');
  exitCode = failures == 0 ? 0 : 1;
}
