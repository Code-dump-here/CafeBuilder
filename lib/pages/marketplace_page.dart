import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/marketplace_state.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter marketplace based on search
    final items = MarketplaceState.broadcasts.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.style.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildProjectCard(items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.store_mall_directory_rounded, color: AppColors.espresso, size: 28),
              const SizedBox(width: 8),
              Text(
                'Market place',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.espresso),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search architectural projects...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
            prefixIcon: const Icon(Icons.search, color: AppColors.placeholder, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: AppColors.espresso, size: 20),
              onPressed: () {
                // Quick filter options
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.find_in_page_outlined, size: 64, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or tags.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BroadcastProject project) {
    Color badgeColor;
    Color textColor;
    if (project.status == 'Open for Proposals') {
      badgeColor = const Color(0xFFD9EAA3).withOpacity(0.8);
      textColor = const Color(0xFF56642B);
    } else if (project.status == 'Urgent') {
      badgeColor = const Color(0xFFFFDAD9);
      textColor = const Color(0xFFBA1A1A);
    } else {
      badgeColor = const Color(0xFFF0E5D8);
      textColor = AppColors.espresso;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  project.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project.status,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Text(
                      project.location,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.color_lens_outlined, size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Text(
                      project.style,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 16, color: AppColors.placeholder),
                        const SizedBox(width: 4),
                        Text(
                          '${project.proposalsCount} Proposals',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: AppColors.placeholder),
                        const SizedBox(width: 4),
                        Text(
                          '${project.commentsCount}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _showProjectDetail(project),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Detail',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectDetail(BroadcastProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9EAA3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              project.style.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                            ),
                          ),
                          Text('ID: ${project.id}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.title,
                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso),
                      ),
                      Text(
                        project.location,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard('Expected Start', project.date),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard('Budget Tier', project.budgetTier),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PROJECT DESCRIPTION',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SERVICE REQUIREMENTS',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.requirements.map((req) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.outlineVariant)),
                          child: Text(req, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                        )).toList(),
                      ),
                      const SizedBox(height: 32),
                      _SubmitProposalForm(
                        project: project,
                        onSubmitted: () {
                          setState(() {}); // Refresh counter
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso)),
        ],
      ),
    );
  }
}

class _SubmitProposalForm extends StatefulWidget {
  final BroadcastProject project;
  final VoidCallback onSubmitted;

  const _SubmitProposalForm({required this.project, required this.onSubmitted});

  @override
  State<_SubmitProposalForm> createState() => _SubmitProposalFormState();
}

class _SubmitProposalFormState extends State<_SubmitProposalForm> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _timelineController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD9EAA3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF56642B).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF56642B), size: 48),
            const SizedBox(height: 12),
            Text(
              'Proposal Submitted!',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            const SizedBox(height: 4),
            Text(
              'The Cafe Owner will review your offer and get in touch with you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: AppColors.outlineVariant),
        Text(
          'SUBMIT PROPOSAL',
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameController,
          decoration: _inputDecor('Your Designer/Firm Name'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: _inputDecor('Est. Cost (\$)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _timelineController,
                decoration: _inputDecor('Duration (e.g. 10 weeks)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: _inputDecor('Introduce your concept or modifications...'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _costController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in your name and cost estimate.')),
              );
              return;
            }

            // Perform dummy submit
            setState(() {
              // Retrieve and increment in memory
              // (Since it is referenced by reference in the list)
              final index = MarketplaceState.broadcasts.indexWhere((element) => element.id == widget.project.id);
              if (index != -1) {
                final proj = MarketplaceState.broadcasts[index];
                MarketplaceState.broadcasts[index] = BroadcastProject(
                  id: proj.id,
                  title: proj.title,
                  location: proj.location,
                  style: proj.style,
                  budgetTier: proj.budgetTier,
                  description: proj.description,
                  requirements: proj.requirements,
                  date: proj.date,
                  proposalsCount: proj.proposalsCount + 1,
                  commentsCount: proj.commentsCount,
                  status: proj.status,
                  imageUrl: proj.imageUrl,
                );
              }
              _submitted = true;
            });
            widget.onSubmitted();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.espresso,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text(
            'Send Proposal Brief',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.espresso),
      ),
    );
  }
}
