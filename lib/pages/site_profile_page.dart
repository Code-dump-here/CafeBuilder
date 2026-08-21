import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/site_profile_responses.dart';
import '../services/site_profile_service.dart';
import '../theme/app_colors.dart';

/// Where the owner records what their premises actually are.
///
/// `projects.areaM2` is one number typed at sign-up. This is the surveyed
/// record: depth and frontage, which way the shopfront faces, a row per storey
/// and a row per opening. It is what a designer works against, and until it
/// exists they are designing for a guess.
///
/// Nothing here is required. A tape measure comes out over several visits, so
/// every field can stay blank and the screen still saves.
class SiteProfilePage extends StatefulWidget {
  /// The project whose premises these are. Uuid string.
  final String projectShopOwnerId;

  /// Project name, so the screen says what is being measured.
  final String projectName;

  const SiteProfilePage({
    super.key,
    required this.projectShopOwnerId,
    required this.projectName,
  });

  @override
  State<SiteProfilePage> createState() => _SiteProfilePageState();
}

class _SiteProfilePageState extends State<SiteProfilePage> {
  SiteProfileResponse? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await SiteProfileService.getByProject(widget.projectShopOwnerId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  /// Runs a mutation, surfaces whatever the server says, and reloads.
  ///
  /// The server's refusals here are the entire explanation — "một mặt bằng
  /// không có hai tầng số 2" tells the owner exactly what to change, so it is
  /// shown as-is rather than replaced with a generic failure message.
  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      _toast(success);
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    }
  }

  static String _cleanError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hồ sơ mặt bằng',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.espresso))
          : _error != null
              ? _ErrorView(message: _cleanError(_error!), onRetry: _load)
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final profile = _profile;

    if (profile == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            widget.projectName,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          _EmptyState(onCreate: _openMeasurements),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          widget.projectName,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _MeasurementsCard(profile: profile, onEdit: _openMeasurements),
        const SizedBox(height: 16),
        _FloorsCard(
          profile: profile,
          onAdd: () => _openFloor(null),
          onEdit: _openFloor,
          onRemove: (floor) => _confirmRemove(
            title: 'Xoá ${floor.label}?',
            body:
                'Các ô cửa gắn vào tầng này vẫn còn nhưng sẽ mất thông tin tầng.',
            onConfirm: () => _run(
              () => SiteProfileService.removeFloor(floor.id),
              'Đã xoá tầng.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _OpeningsCard(
          profile: profile,
          onAdd: () => _openOpening(null),
          onEdit: _openOpening,
          onRemove: (opening) => _confirmRemove(
            title: 'Xoá ô cửa này?',
            body: 'Nó biến mất khỏi hồ sơ mặt bằng.',
            onConfirm: () => _run(
              () => SiteProfileService.removeOpening(opening.id),
              'Đã xoá ô cửa.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove({
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }

  Future<void> _openMeasurements() async {
    final profile = _profile;
    final values = await showModalBottomSheet<_MeasurementValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _MeasurementsSheet(initial: profile),
    );
    if (values == null) return;

    await _run(
      () async {
        if (profile == null) {
          await SiteProfileService.create(
            projectShopOwnerId: widget.projectShopOwnerId,
            lengthM: values.lengthM,
            widthM: values.widthM,
            frontageWidthM: values.frontageWidthM,
            ceilingHeightM: values.ceilingHeightM,
            roadWidthM: values.roadWidthM,
            orientation: values.orientation,
            floorCount: values.floorCount,
            hasMezzanine: values.hasMezzanine,
            structureNote: values.structureNote,
            existingConditionNote: values.existingConditionNote,
          );
        } else {
          await SiteProfileService.update(
            profile.id,
            lengthM: values.lengthM,
            widthM: values.widthM,
            frontageWidthM: values.frontageWidthM,
            ceilingHeightM: values.ceilingHeightM,
            roadWidthM: values.roadWidthM,
            orientation: values.orientation,
            floorCount: values.floorCount,
            hasMezzanine: values.hasMezzanine,
            structureNote: values.structureNote,
            existingConditionNote: values.existingConditionNote,
          );
        }
      },
      profile == null ? 'Đã lưu thông số mặt bằng.' : 'Đã cập nhật thông số.',
    );
  }

  Future<void> _openFloor(SiteFloorResponse? floor) async {
    final profile = _profile;
    if (profile == null) return;

    final values = await showModalBottomSheet<_FloorValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FloorSheet(initial: floor),
    );
    if (values == null) return;

    await _run(
      () async {
        if (floor == null) {
          await SiteProfileService.addFloor(
            profile.id,
            floorNo: values.floorNo,
            name: values.name,
            areaM2: values.areaM2,
            ceilingHeightM: values.ceilingHeightM,
            purpose: values.purpose,
          );
        } else {
          await SiteProfileService.updateFloor(
            floor.id,
            floorNo: values.floorNo,
            name: values.name,
            areaM2: values.areaM2,
            ceilingHeightM: values.ceilingHeightM,
            purpose: values.purpose,
          );
        }
      },
      floor == null ? 'Đã thêm tầng.' : 'Đã cập nhật tầng.',
    );
  }

  Future<void> _openOpening(SiteOpeningResponse? opening) async {
    final profile = _profile;
    if (profile == null) return;

    final values = await showModalBottomSheet<_OpeningValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          _OpeningSheet(initial: opening, floors: profile.floors),
    );
    if (values == null) return;

    await _run(
      () async {
        if (opening == null) {
          await SiteProfileService.addOpening(
            profile.id,
            type: values.type,
            siteFloorId: values.siteFloorId,
            orientation: values.orientation,
            widthM: values.widthM,
            heightM: values.heightM,
            quantity: values.quantity,
            note: values.note,
          );
        } else {
          await SiteProfileService.updateOpening(
            opening.id,
            type: values.type,
            siteFloorId: values.siteFloorId,
            orientation: values.orientation,
            widthM: values.widthM,
            heightM: values.heightM,
            quantity: values.quantity,
            note: values.note,
          );
        }
      },
      opening == null ? 'Đã thêm ô cửa.' : 'Đã cập nhật ô cửa.',
    );
  }
}

// ── Read-only cards ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.straighten, size: 40, color: AppColors.espresso),
          const SizedBox(height: 12),
          Text(
            'Chưa ai đo mặt bằng này',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Ghi lại số đo thật để nhà thiết kế bám theo hiện trạng chứ không '
            'phải phỏng đoán. Đo tới đâu điền tới đó — không ô nào bắt buộc.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.espresso),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Khai số đo mặt bằng'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.espresso),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MeasurementsCard extends StatelessWidget {
  final SiteProfileResponse profile;
  final VoidCallback onEdit;

  const _MeasurementsCard({required this.profile, required this.onEdit});

  static String _m(double? value) =>
      value == null ? 'Chưa đo' : '${_trim(value)} m';

  static String _m2(double? value) =>
      value == null ? 'Chưa đo' : '${_trim(value)} m²';

  /// 5.0 → "5", 4.75 → "4.75". Trailing zeros on a tape measurement read as
  /// false precision.
  static String _trim(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.straighten,
      title: 'Kích thước và hướng',
      subtitle: 'Đo tới đâu điền tới đó.',
      actionLabel: 'Sửa',
      onAction: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              _Fact(label: 'Chiều sâu', value: _m(profile.lengthM)),
              _Fact(label: 'Chiều ngang', value: _m(profile.widthM)),
              _Fact(label: 'Mặt tiền', value: _m(profile.frontageWidthM)),
              _Fact(label: 'Thông thuỷ', value: _m(profile.ceilingHeightM)),
              _Fact(label: 'Đường trước nhà', value: _m(profile.roadWidthM)),
              _Fact(
                label: 'Hướng mặt tiền',
                value: profile.orientation == null
                    ? 'Chưa xác định'
                    : (kOrientationLabels[profile.orientation] ??
                        profile.orientation!),
              ),
              _Fact(
                label: 'Số tầng',
                value: profile.floorCount == null
                    ? 'Chưa đo'
                    : '${profile.floorCount} tầng',
              ),
              _Fact(
                label: 'Gác lửng',
                value: profile.hasMezzanine ? 'Có' : 'Không',
              ),
              _Fact(
                label: 'Diện tích lô',
                value: _m2(profile.derivedFootprintM2),
                hint: 'Sâu × ngang',
              ),
              _Fact(
                label: 'Tổng sàn',
                value: _m2(profile.totalFloorAreaM2),
                hint: 'Cộng các tầng',
              ),
            ],
          ),
          if (profile.structureNote != null &&
              profile.structureNote!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NoteBlock(label: 'Kết cấu', text: profile.structureNote!),
          ],
          if (profile.existingConditionNote != null &&
              profile.existingConditionNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _NoteBlock(
              label: 'Hiện trạng bàn giao',
              text: profile.existingConditionNote!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _Fact({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (hint != null)
            Text(
              hint!,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.black38),
            ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final String label;
  final String text;

  const _NoteBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
        ),
        Text(text, style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
      ],
    );
  }
}

class _FloorsCard extends StatelessWidget {
  final SiteProfileResponse profile;
  final VoidCallback onAdd;
  final void Function(SiteFloorResponse) onEdit;
  final void Function(SiteFloorResponse) onRemove;

  const _FloorsCard({
    required this.profile,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final floors = [...profile.floors]
      ..sort((a, b) => a.floorNo.compareTo(b.floorNo));

    return _SectionCard(
      icon: Icons.layers_outlined,
      title: 'Các tầng',
      subtitle: 'Mỗi tầng một diện tích riêng.',
      actionLabel: 'Thêm',
      onAction: onAdd,
      child: floors.isEmpty
          ? _EmptyRow(text: 'Chưa khai tầng nào.')
          : Column(
              children: floors
                  .map(
                    (floor) => _Row(
                      badge: 'T${floor.floorNo}',
                      title: floor.label,
                      subtitle: [
                        if (floor.areaM2 != null)
                          '${_MeasurementsCard._trim(floor.areaM2!)} m²',
                        if (floor.ceilingHeightM != null)
                          'thông thuỷ ${_MeasurementsCard._trim(floor.ceilingHeightM!)} m',
                        if (floor.purpose != null && floor.purpose!.isNotEmpty)
                          floor.purpose!,
                      ].join(' · '),
                      onEdit: () => onEdit(floor),
                      onRemove: () => onRemove(floor),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _OpeningsCard extends StatelessWidget {
  final SiteProfileResponse profile;
  final VoidCallback onAdd;
  final void Function(SiteOpeningResponse) onEdit;
  final void Function(SiteOpeningResponse) onRemove;

  const _OpeningsCard({
    required this.profile,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    String floorLabel(String? siteFloorId) {
      if (siteFloorId == null) return 'chưa gán tầng';
      for (final floor in profile.floors) {
        if (floor.id == siteFloorId) return floor.label;
      }
      return 'chưa gán tầng';
    }

    final openings = [...profile.openings]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _SectionCard(
      icon: Icons.sensor_door_outlined,
      title: 'Cửa, cửa sổ và ban công',
      subtitle: 'Nơi ánh sáng và khách đi vào.',
      actionLabel: 'Thêm',
      onAction: onAdd,
      child: openings.isEmpty
          ? _EmptyRow(text: 'Chưa khai ô cửa nào.')
          : Column(
              children: openings
                  .map(
                    (opening) => _Row(
                      badge: opening.quantity > 1 ? '×${opening.quantity}' : '1',
                      title: kSiteOpeningLabels[opening.type] ?? opening.type,
                      subtitle: [
                        floorLabel(opening.siteFloorId),
                        if (opening.widthM != null && opening.heightM != null)
                          '${_MeasurementsCard._trim(opening.widthM!)} × ${_MeasurementsCard._trim(opening.heightM!)} m',
                        if (opening.orientation != null)
                          kOrientationLabels[opening.orientation] ??
                              opening.orientation!,
                        if (opening.note != null && opening.note!.isNotEmpty)
                          opening.note!,
                      ].join(' · '),
                      onEdit: () => onEdit(opening),
                      onRemove: () => onRemove(opening),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _Row({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.espresso,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;

  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

// ── Edit sheets ──────────────────────────────────────────────────────────────

/// Parses a text field into a double, treating blank as "not measured".
///
/// Blank must stay null rather than becoming 0: these fields are optional, and
/// 0 would record "this shopfront is zero metres wide".
double? _toDouble(String text) {
  final trimmed = text.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

int? _toInt(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

String _fromNum(num? value) {
  if (value == null) return '';
  if (value is int) return value.toString();
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

class _MeasurementValues {
  final double? lengthM;
  final double? widthM;
  final double? frontageWidthM;
  final double? ceilingHeightM;
  final double? roadWidthM;
  final String? orientation;
  final int? floorCount;
  final bool hasMezzanine;
  final String? structureNote;
  final String? existingConditionNote;

  const _MeasurementValues({
    this.lengthM,
    this.widthM,
    this.frontageWidthM,
    this.ceilingHeightM,
    this.roadWidthM,
    this.orientation,
    this.floorCount,
    required this.hasMezzanine,
    this.structureNote,
    this.existingConditionNote,
  });
}

class _MeasurementsSheet extends StatefulWidget {
  final SiteProfileResponse? initial;

  const _MeasurementsSheet({this.initial});

  @override
  State<_MeasurementsSheet> createState() => _MeasurementsSheetState();
}

class _MeasurementsSheetState extends State<_MeasurementsSheet> {
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _frontage;
  late final TextEditingController _ceiling;
  late final TextEditingController _road;
  late final TextEditingController _floorCount;
  late final TextEditingController _structure;
  late final TextEditingController _condition;
  String? _orientation;
  late bool _hasMezzanine;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _length = TextEditingController(text: _fromNum(p?.lengthM));
    _width = TextEditingController(text: _fromNum(p?.widthM));
    _frontage = TextEditingController(text: _fromNum(p?.frontageWidthM));
    _ceiling = TextEditingController(text: _fromNum(p?.ceilingHeightM));
    _road = TextEditingController(text: _fromNum(p?.roadWidthM));
    _floorCount = TextEditingController(text: _fromNum(p?.floorCount));
    _structure = TextEditingController(text: p?.structureNote ?? '');
    _condition = TextEditingController(text: p?.existingConditionNote ?? '');
    _orientation = p?.orientation;
    _hasMezzanine = p?.hasMezzanine ?? false;
  }

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    _frontage.dispose();
    _ceiling.dispose();
    _road.dispose();
    _floorCount.dispose();
    _structure.dispose();
    _condition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.initial == null ? 'Khai số đo mặt bằng' : 'Sửa số đo',
      subtitle: 'Chưa đo được gì thì cứ để trống.',
      onSave: () => Navigator.pop(
        context,
        _MeasurementValues(
          lengthM: _toDouble(_length.text),
          widthM: _toDouble(_width.text),
          frontageWidthM: _toDouble(_frontage.text),
          ceilingHeightM: _toDouble(_ceiling.text),
          roadWidthM: _toDouble(_road.text),
          orientation: _orientation,
          floorCount: _toInt(_floorCount.text),
          hasMezzanine: _hasMezzanine,
          structureNote:
              _structure.text.trim().isEmpty ? null : _structure.text.trim(),
          existingConditionNote:
              _condition.text.trim().isEmpty ? null : _condition.text.trim(),
        ),
      ),
      children: [
        _NumberField(label: 'Chiều sâu (m)', controller: _length),
        _NumberField(label: 'Chiều ngang (m)', controller: _width),
        _NumberField(
          label: 'Bề rộng mặt tiền (m)',
          controller: _frontage,
          hint: 'Thường bằng chiều ngang, trừ lô góc hoặc nhà lùi vào trong.',
        ),
        _NumberField(label: 'Chiều cao thông thuỷ (m)', controller: _ceiling),
        _NumberField(label: 'Bề rộng đường trước nhà (m)', controller: _road),
        _NumberField(
          label: 'Số tầng sử dụng',
          controller: _floorCount,
          decimal: false,
        ),
        _DropdownField(
          label: 'Hướng mặt tiền',
          value: _orientation,
          items: kOrientationLabels,
          placeholder: 'Chưa xác định',
          onChanged: (value) => setState(() => _orientation = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.espresso,
          value: _hasMezzanine,
          onChanged: (value) => setState(() => _hasMezzanine = value),
          title: Text(
            'Có gác lửng',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        _TextField(
          label: 'Kết cấu',
          controller: _structure,
          hint: 'Nhà phố, shophouse, nhà cấp 4, mặt bằng thô…',
          maxLines: 2,
        ),
        _TextField(
          label: 'Hiện trạng bàn giao',
          controller: _condition,
          hint: 'Đã có sẵn những gì, phải đập bỏ những gì.',
          maxLines: 2,
        ),
      ],
    );
  }
}

class _FloorValues {
  final int floorNo;
  final String? name;
  final double? areaM2;
  final double? ceilingHeightM;
  final String? purpose;

  const _FloorValues({
    required this.floorNo,
    this.name,
    this.areaM2,
    this.ceilingHeightM,
    this.purpose,
  });
}

class _FloorSheet extends StatefulWidget {
  final SiteFloorResponse? initial;

  const _FloorSheet({this.initial});

  @override
  State<_FloorSheet> createState() => _FloorSheetState();
}

class _FloorSheetState extends State<_FloorSheet> {
  late final TextEditingController _floorNo;
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _ceiling;
  late final TextEditingController _purpose;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _floorNo = TextEditingController(text: f == null ? '1' : '${f.floorNo}');
    _name = TextEditingController(text: f?.name ?? '');
    _area = TextEditingController(text: _fromNum(f?.areaM2));
    _ceiling = TextEditingController(text: _fromNum(f?.ceilingHeightM));
    _purpose = TextEditingController(text: f?.purpose ?? '');
  }

  @override
  void dispose() {
    _floorNo.dispose();
    _name.dispose();
    _area.dispose();
    _ceiling.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.initial == null ? 'Thêm tầng' : 'Sửa tầng',
      subtitle: '1 là trệt, 0 là gác lửng, số âm là hầm.',
      onSave: () {
        final no = _toInt(_floorNo.text);
        if (no == null) return;
        Navigator.pop(
          context,
          _FloorValues(
            floorNo: no,
            name: _name.text.trim().isEmpty ? null : _name.text.trim(),
            areaM2: _toDouble(_area.text),
            ceilingHeightM: _toDouble(_ceiling.text),
            purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
          ),
        );
      },
      children: [
        _NumberField(
          label: 'Số tầng',
          controller: _floorNo,
          decimal: false,
          hint: 'Không trùng trong cùng mặt bằng.',
        ),
        _TextField(
          label: 'Tên',
          controller: _name,
          hint: 'Trệt, Lầu 1, Gác lửng, Sân thượng…',
        ),
        _NumberField(label: 'Diện tích sàn (m²)', controller: _area),
        _NumberField(label: 'Chiều cao thông thuỷ (m)', controller: _ceiling),
        _TextField(
          label: 'Công năng dự kiến',
          controller: _purpose,
          hint: 'Quầy pha chế, chỗ ngồi, kho, WC…',
        ),
      ],
    );
  }
}

class _OpeningValues {
  final String type;
  final String? siteFloorId;
  final String? orientation;
  final double? widthM;
  final double? heightM;
  final int quantity;
  final String? note;

  const _OpeningValues({
    required this.type,
    this.siteFloorId,
    this.orientation,
    this.widthM,
    this.heightM,
    required this.quantity,
    this.note,
  });
}

class _OpeningSheet extends StatefulWidget {
  final SiteOpeningResponse? initial;
  final List<SiteFloorResponse> floors;

  const _OpeningSheet({this.initial, required this.floors});

  @override
  State<_OpeningSheet> createState() => _OpeningSheetState();
}

class _OpeningSheetState extends State<_OpeningSheet> {
  late String _type;
  String? _siteFloorId;
  String? _orientation;
  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _quantity;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final o = widget.initial;
    _type = o?.type ?? 'main_door';
    _siteFloorId = o?.siteFloorId;
    _orientation = o?.orientation;
    _width = TextEditingController(text: _fromNum(o?.widthM));
    _height = TextEditingController(text: _fromNum(o?.heightM));
    _quantity = TextEditingController(text: o == null ? '1' : '${o.quantity}');
    _note = TextEditingController(text: o?.note ?? '');
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.initial == null ? 'Thêm ô cửa' : 'Sửa ô cửa',
      subtitle: 'Các ô giống nhau gộp một dòng rồi điền số lượng.',
      onSave: () => Navigator.pop(
        context,
        _OpeningValues(
          type: _type,
          siteFloorId: _siteFloorId,
          orientation: _orientation,
          widthM: _toDouble(_width.text),
          heightM: _toDouble(_height.text),
          quantity: _toInt(_quantity.text) ?? 1,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      ),
      children: [
        _DropdownField(
          label: 'Loại',
          value: _type,
          items: kSiteOpeningLabels,
          onChanged: (value) => setState(() => _type = value ?? 'main_door'),
        ),
        _DropdownField(
          label: 'Tầng',
          value: _siteFloorId,
          items: {for (final f in widget.floors) f.id: f.label},
          placeholder: 'Chưa gán tầng',
          onChanged: (value) => setState(() => _siteFloorId = value),
        ),
        _NumberField(label: 'Rộng (m)', controller: _width),
        _NumberField(label: 'Cao (m)', controller: _height),
        _NumberField(
          label: 'Số lượng',
          controller: _quantity,
          decimal: false,
          hint: 'Bốn cửa sổ cùng quy cách là một dòng, số lượng 4.',
        ),
        _TextField(label: 'Ghi chú', controller: _note),
      ],
    );
  }
}

// ── Sheet building blocks ────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSave;
  final List<Widget> children;

  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet clear of the keyboard so the field being typed into
      // stays visible.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                      ),
                      onPressed: onSave,
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool decimal;

  const _NumberField({
    required this.label,
    required this.controller,
    this.hint,
    this.decimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return _TextField(
      label: label,
      controller: controller,
      hint: hint,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle:
                  GoogleFonts.inter(fontSize: 12, color: Colors.black38),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> items;
  final String? placeholder;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: items.containsKey(value) ? value : null,
            isExpanded: true,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            hint: placeholder == null
                ? null
                : Text(
                    placeholder!,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.black38),
                  ),
            items: [
              if (placeholder != null)
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(placeholder!),
                ),
              ...items.entries.map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
