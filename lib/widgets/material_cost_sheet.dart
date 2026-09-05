import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/review3_responses.dart';
import '../services/material_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// What a milestone costs in materials, for the shop owner.
///
/// Read-only: the price list and the quantities belong to the provider. What
/// the owner needs is the arithmetic behind a payment request — planned versus
/// actual, and where the numbers came from.
///
/// The actual total is deliberately withheld while any line is still missing a
/// real quantity. The server returns null in that case, and this sheet shows a
/// dash plus how many lines are outstanding rather than adding up the ones that
/// happen to be filled in — a partial sum labelled "actual" would read as the
/// final figure.
class MaterialCostSheet extends StatefulWidget {
  final String constructionItemId;
  final String milestoneName;

  const MaterialCostSheet({
    super.key,
    required this.constructionItemId,
    required this.milestoneName,
  });

  @override
  State<MaterialCostSheet> createState() => _MaterialCostSheetState();
}

class _MaterialCostSheetState extends State<MaterialCostSheet> {
  MaterialCostSummaryResponse? _cost;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cost = await MaterialService.getCost(widget.constructionItemId);
      if (!mounted) return;
      setState(() {
        _cost = cost;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _vnd(double? value) =>
      value == null ? '—' : formatVnd(value);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_error != null) {
      return ListView(
        controller: controller,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.error_outline, size: 36, color: Colors.red.shade400),
          const SizedBox(height: 10),
          Text(
            'Không tải được chi phí vật tư.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
          ),
        ],
      );
    }

    final cost = _cost!;

    return ListView(
      controller: controller,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Vật tư & chi phí',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        Text(
          widget.milestoneName,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        _CostRow(label: 'Riêng hạng mục', value: _vnd(cost.ownEstimatedCost)),
        _CostRow(label: 'Từ các task', value: _vnd(cost.tasksEstimatedCost)),
        const Divider(height: 20),
        _CostRow(
          label: 'Chi phí dự tính',
          value: _vnd(cost.totalEstimatedCost),
          emphasis: true,
        ),
        _CostRow(
          label: 'Chi phí thực tế',
          value: _vnd(cost.totalActualCost),
          emphasis: true,
        ),

        if (cost.missingActualCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Còn ${cost.missingActualCount} dòng chưa có khối lượng thực tế — '
                    'tổng thực tế chỉ hiện khi đã ghi đủ.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),
        Text(
          'Chi tiết',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        if (cost.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Chưa có vật tư nào được khai cho hạng mục này.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
          )
        else
          ...cost.lines.map((line) => _LineTile(line: line, vnd: _vnd)),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _CostRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: emphasis ? AppColors.espresso : AppColors.textSecondary,
              fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final ConstructionMaterialResponse line;
  final String Function(double?) vnd;

  const _LineTile({required this.line, required this.vnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.materialName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                vnd(line.estimatedCost),
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Dự tính ${line.estimatedQuantity} ${line.unit}'
            '${line.actualQuantity != null ? '  ·  thực tế ${line.actualQuantity} ${line.unit}' : '  ·  chưa có thực tế'}'
            '  ·  ${vnd(line.unitPrice)}/${line.unit}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (line.note != null && line.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                line.note!,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}
