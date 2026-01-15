import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NearbyReports extends StatelessWidget {
  const NearbyReports({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Reports',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items lost or found in your area',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/heatmap'),
              icon: Icon(
                Icons.map_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                'View Map',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Real-time stats from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            int lostCount = 0;
            int foundCount = 0;
            int reunitedCount = 0;

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final isLost = data['isLost'] ?? true;
                final status = data['status'] ?? 'active';

                if (status == 'returned' || status == 'claimed') {
                  reunitedCount++;
                } else if (isLost) {
                  lostCount++;
                } else {
                  foundCount++;
                }
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.search,
                    count: snapshot.hasData ? '$lostCount' : '-',
                    label: 'Lost Items',
                    color: const Color(0xFFEF4444),
                    isLoading: !snapshot.hasData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.check_circle,
                    count: snapshot.hasData ? '$foundCount' : '-',
                    label: 'Found Items',
                    color: const Color(0xFF22C55E),
                    isLoading: !snapshot.hasData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.handshake,
                    count: snapshot.hasData ? '$reunitedCount' : '-',
                    label: 'Reunited',
                    color: colorScheme.primary,
                    isLoading: !snapshot.hasData,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
