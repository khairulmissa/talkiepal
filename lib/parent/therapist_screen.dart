import 'package:flutter/material.dart';
import 'package:talkiepal/parent/widgets/parent_ui.dart';

/// Therapist tab: finding and booking a speech therapist is coming soon.
class TherapistScreen extends StatelessWidget {
  const TherapistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget feature(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParentIconBox(icon, const Color(0xFF00897B), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ParentColors.ink),
                ),
                Text(
                  text,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return ParentPage(
      tab: ParentTab.therapist,
      header: const ParentHeader(title: 'Therapist'),
      children: [
        ParentCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_rounded, size: 44, color: Color(0xFF00897B)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: ParentColors.yellowLight, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB7791F),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Speech therapists for your child',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ParentColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'Soon you can find a verified speech therapist, book sessions and share your child\'s progress with them.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ParentColors.soft, height: 1.4),
              ),
            ],
          ),
        ),
        ParentCard(
          child: Column(
            children: [
              const ParentSectionTitle('What is coming', icon: Icons.auto_awesome_rounded),
              feature(
                Icons.verified_rounded,
                'Verified therapists',
                'Every therapist is checked before they can join.',
              ),
              feature(Icons.event_available_rounded, 'Book sessions', 'Pick a time that suits you and your child.'),
              feature(
                Icons.insights_rounded,
                'Share progress',
                'Your therapist sees the same scores you see in Progress.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
