import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'constructor_detail_page.dart';

class FindConstructorsPage extends StatefulWidget {
  const FindConstructorsPage({super.key});

  @override
  State<FindConstructorsPage> createState() => _FindConstructorsPageState();
}

class _FindConstructorsPageState extends State<FindConstructorsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _constructors = [
    {
      'name': 'Vanguard Builds Co.',
      'type': 'Construction Firm',
      'rating': '4.9',
      'projects': '42 Cafe Projects',
      'location': 'Hanoi, Vietnam',
      'services': ['Structural & MEP', 'Artisan Finishing', 'Kitchen HVAC'],
      'images': [
        'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80&w=300',
        'https://images.unsplash.com/photo-1541123356070-7d722bf1d15c?auto=format&fit=crop&q=80&w=300',
      ],
    },
    {
      'name': 'Heritage Stone & Steel',
      'type': 'Construction Firm',
      'rating': '4.8',
      'projects': '28 Cafe Projects',
      'location': 'Ho Chi Minh City',
      'services': ['Custom Metalwork', 'Stone Masonry', 'Electrical Design'],
      'images': [
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300',
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80&w=300',
      ],
    },
  ];

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterConstructorsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Constructors',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            Text(
              'Marketplace Feed',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Constructors',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Specialized construction firms for your next F&B masterpiece. From structural integrity to artisan finishing.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDropdown('Specialization')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Project Scale')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search firm name...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
                prefixIcon: const Icon(Icons.search, color: AppColors.placeholder, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.espresso),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => _showFilterSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9EAA3).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Detail filter',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._constructors.map((c) => _buildConstructorCard(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildConstructorCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['type'],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.espresso),
                    const SizedBox(width: 4),
                    Text(
                      data['rating'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['name'],
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.coffee_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Text(
                data['projects'],
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Text(
                data['location'],
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CORE SERVICES',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (data['services'] as List).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.espresso),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConstructorDetailPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(140, 36),
            ),
            child: Text(
              'View Full Portfolio →',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FEATURED PROJECTS',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['images'][0],
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['images'][1],
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['images'][2],
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterConstructorsSheet extends StatefulWidget {
  const FilterConstructorsSheet({super.key});

  @override
  State<FilterConstructorsSheet> createState() => _FilterConstructorsSheetState();
}

class _FilterConstructorsSheetState extends State<FilterConstructorsSheet> {
  String selectedBudget = 'MID';
  String selectedSpec = 'Bistro';
  String selectedProjects = '10+';
  String selectedArea = '50 - 100m²';
  String selectedTime = '30-60 days';
  String selectedWarranty = '12 mo';
  bool verifiedPartner = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.espresso),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Filter Constructors',
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Reset', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Refine your search for the perfect building partner.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('City'),
                            _buildDropdown('HCMC'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('District'),
                            _buildDropdown('District 1'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('BUDGET RANGE (VND)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('NORMAL', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('MID', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('LUXURY', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('LUXURY +', selectedBudget, (v) => setState(() => selectedBudget = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('SPECIALIZATION'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Specialty Cafe', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Bistro', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Roastery', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Chain/Franchise', selectedSpec, (v) => setState(() => selectedSpec = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('COMPLETED PROJECTS'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('5+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('10+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('20+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('FLOOR AREA (M²)'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('< 50m²', selectedArea, (v) => setState(() => selectedArea = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('50 - 100m²', selectedArea, (v) => setState(() => selectedArea = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('100 - 200m²', selectedArea, (v) => setState(() => selectedArea = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('COMPLETION TIME'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('< 30 days', selectedTime, (v) => setState(() => selectedTime = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('30-60 days', selectedTime, (v) => setState(() => selectedTime = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('60-90 days', selectedTime, (v) => setState(() => selectedTime = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verified Partner', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                            Text('Only show constructors vetted by Atelier', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                        Switch(
                          value: verifiedPartner,
                          onChanged: (v) => setState(() => verifiedPartner = v),
                          activeColor: const Color(0xFF56642B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('WARRANTY PERIOD'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('6 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('12 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('24 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('MINIMUM RATING'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('4.0', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          const Icon(Icons.star, size: 12, color: AppColors.placeholder),
                        ],
                      ),
                      Column(
                        children: [
                          Text('4.5', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          const Icon(Icons.star, size: 12, color: AppColors.espresso),
                        ],
                      ),
                      Column(
                        children: [
                          Text('5.0', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                          const Icon(Icons.star, size: 12, color: AppColors.placeholder),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Clear All', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Show 12 Results', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.espresso)),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.placeholder),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String selectedValue, Function(String) onSelect) {
    bool isSelected = label == selectedValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.espresso : Colors.white,
          border: Border.all(color: isSelected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
