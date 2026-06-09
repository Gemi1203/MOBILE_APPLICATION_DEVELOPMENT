import 'package:flutter/material.dart';
import '../store/sacco_store.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  final SaccoStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Landing',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digital Cooperative Banking',
                style: TextStyle(
                  color: Color(0xFF2ED3A4),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Grow Member Savings. Approve Smarter Loans.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A SACCO operating cockpit with a sharp, trustworthy interface built for daily contributions, transparent balances, and cleaner lending decisions.',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFFBED7CC),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => store.setTab(1),
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => store.setTab(2),
                      child: const Text('Preview Dashboard'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2019),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x3366CDAE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF2ED3A4), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fully compliant with SACCO regulations. Member data is encrypted and secure.',
                        style: TextStyle(
                          color: Color(0xFFBED7CC),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How It Works',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFlowStep(
                icon: Icons.person_add_outlined,
                title: '1. Member Onboarding',
                description:
                    'Register members quickly with ID verification and share capital setup.',
              ),
              _buildFlowStep(
                icon: Icons.savings_outlined,
                title: '2. Daily Contributions',
                description:
                    'Track and record member savings with instant balance updates.',
              ),
              _buildFlowStep(
                icon: Icons.request_page_outlined,
                title: '3. Loan Application',
                description:
                    'Guided intake form with eligibility checks based on member savings.',
              ),
              _buildFlowStep(
                icon: Icons.fact_check_outlined,
                title: '4. Loan Approval',
                description:
                    'Committee review dashboard with transparent scoring and decisions.',
              ),
              _buildFlowStep(
                icon: Icons.bar_chart_outlined,
                title: '5. Reports & Oversight',
                description:
                    'Real-time analytics on portfolio health, repayments, and growth.',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Key Features',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetric('Daily Contribution Tracking', 'Instant'),
            _buildMetric('Loan Intake', 'Guided'),
            _buildMetric('Design Style', 'Figma-ready tokens'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFlowStep({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2019),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x3366CDAE)),
            ),
            child: Icon(icon, color: const Color(0xFF2ED3A4), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFBED7CC),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF112A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3366CDAE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBED7CC), fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF8D47A),
            ),
          ),
        ],
      ),
    );
  }
}
