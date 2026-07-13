import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CollaborationWorkspacePage extends StatelessWidget {
  const CollaborationWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: const Icon(Icons.coffee, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Design Cafe',
              style: TextStyle(
                  color: AppColors.appName,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collaboration\nWorkspace',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Project: Urban Roast Flagship Store • 12 Active\nContributors',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            // Discussion Threads
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Discussion\nThreads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                       ElevatedButton.icon(
                         onPressed: () {},
                         icon: const Icon(Icons.add, size: 16),
                         label: const Text('New\nThread', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primaryContainer,
                           foregroundColor: AppColors.white,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         ),
                       )
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildThreadItem(
                    category: 'DESIGN',
                    categoryColor: Colors.green.shade200,
                    time: '2h ago',
                    title: 'Bar Counter Discussion',
                    preview: 'Exploring the integration of seamless brass inlays within the main mahogany...',
                    commentsCount: 14,
                    avatars: ['https://i.pravatar.cc/100?img=11', 'https://i.pravatar.cc/100?img=68'],
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 32),
                  _buildThreadItem(
                    category: 'MATERIALS',
                    categoryColor: Colors.orange.shade200,
                    time: '5h ago',
                    title: 'Material Selection',
                    preview: 'Reviewing the sustainable acoustic panel options for the mezzanine ceiling. Needs...',
                    commentsCount: 8,
                    avatars: ['https://i.pravatar.cc/100?img=33'],
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 32),
                  _buildThreadItem(
                    category: 'TECHNICAL',
                    categoryColor: Colors.blue.shade200,
                    time: 'Yesterday',
                    title: 'Facade Lighting',
                    preview: 'Placement of recessed warm LEDs along the exterior brickwork. Wiring diagrams...',
                    commentsCount: 21,
                    avatars: ['https://i.pravatar.cc/100?img=44', 'https://i.pravatar.cc/100?img=45', 'https://i.pravatar.cc/100?img=46'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Pending Approvals
             const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 12),
             Container(
               decoration: BoxDecoration(
                 color: AppColors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: AppColors.outlineVariant),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   ClipRRect(
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                     child: Image.network(
                       'https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&q=80&w=600',
                       height: 140,
                       fit: BoxFit.cover,
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                              const Expanded(child: Text('Walnut Material\nApproval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2))),
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department, size: 14, color: Colors.red.shade700),
                                  const SizedBox(width: 4),
                                  Text('High\nPriority', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold, height: 1.2))
                                ],
                              )
                           ],
                         ),
                         const SizedBox(height: 12),
                         const Text(
                           'Request from Design Team for the bespoke cabinetry in the main brewing area. Sample code: WN-2024-B.',
                           style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                         ),
                         const SizedBox(height: 16),
                         Row(
                           children: [
                             Expanded(
                               child: ElevatedButton(
                                 onPressed: () {},
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: AppColors.primaryContainer,
                                   foregroundColor: AppColors.white,
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                 ),
                                 child: const Text('Approve\nSelection', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: OutlinedButton(
                                 onPressed: () {},
                                 style: OutlinedButton.styleFrom(
                                   side: const BorderSide(color: AppColors.outlineVariant),
                                   foregroundColor: AppColors.textPrimary,
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                 ),
                                 child: const Text('Request\nChanges', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                               ),
                             ),
                           ],
                         )
                       ],
                     ),
                   )
                 ],
               ),
             ),
             const SizedBox(height: 24),
             
             // Decision Log
             const Text('Decision Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: AppColors.outlineVariant),
               ),
               child: Column(
                 children: [
                   _buildDecisionItem('Confirmed Industrial Lighting', 'Oct 24 • Approved by M. Roberts', true),
                   const SizedBox(height: 12),
                   _buildDecisionItem('Approved Layout v4.2', 'Oct 23 • Final Client Sign-off', true),
                   const SizedBox(height: 12),
                   _buildDecisionItem('Basic Plumbing Sign-off', 'Oct 20 • Contractor Team', false),
                 ],
               ),
             ),
             
             const SizedBox(height: 24),
             // Meeting Notes
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: AppColors.outlineVariant),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Meeting Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       Icon(Icons.edit_document, size: 18, color: AppColors.placeholder),
                     ],
                   ),
                   const SizedBox(height: 12),
                   const Text('Site Visit Oct 22', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                   const Text('Key Summary', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                   const SizedBox(height: 8),
                   _buildCheckItem('Wall demolition completed.', true),
                   _buildCheckItem('Confirm sink placement with MEP.', true),
                   _buildCheckItem('Source local brick alternative.', false),
                   const SizedBox(height: 12),
                   Center(
                     child: TextButton(
                       onPressed: () {},
                       child: const Text('View All Notes', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                     ),
                   )
                 ],
               ),
             ),
             
             const SizedBox(height: 24),
             // Shared Assets
             const Text('Shared Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 12),
             _buildAssetItem(Icons.picture_as_pdf, Colors.red.shade400, 'Schematic_v2.pdf', '12.4 MB • 2H AGO'),
             const SizedBox(height: 8),
             _buildAssetItem(Icons.image, Colors.green.shade400, 'Facade_Render_4K.jpg', '85.3 MB • 5H AGO'),
             const SizedBox(height: 8),
             _buildAssetItem(Icons.insert_drive_file, Colors.blue.shade400, 'Electrical_Draft.dwg', '5.2 MB • YESTERDAY'),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadItem({
    required String category,
    required Color categoryColor,
    required String time,
    required String title,
    required String preview,
    required int commentsCount,
    required List<String> avatars,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
          ],
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(preview, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: avatars.length * 16.0 + 8,
              height: 24,
              child: Stack(
                children: List.generate(avatars.length, (index) {
                  return Positioned(
                    left: index * 14.0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundImage: NetworkImage(avatars[index]),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Text('$commentsCount comments', style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
          ],
        )
      ],
    );
  }

  Widget _buildDecisionItem(String title, String subtitle, bool isCompleted) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: isCompleted ? Colors.green.shade600 : AppColors.placeholder,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCheckItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: isChecked ? Colors.green.shade600 : AppColors.placeholder,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: AppColors.background,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.placeholder)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
