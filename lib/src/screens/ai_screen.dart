// ============================================================
// ai_screen.dart — AI feature placeholder screen
// ============================================================
// This screen serves as a placeholder / preview for upcoming AI-
// powered features in the Goa Maps app.  It currently displays two
// feature cards:
//
//   1. "The Time Machine" — a concept that would allow users to
//      visualise a location in a specific historical era.
//   2. "The Architecture Expert" — a concept AI chatbot that could
//      answer questions about architectural styles and history.
//
// The screen is intentionally static (a StatelessWidget) because
// there is no interactive state to manage yet.  Once the AI
// features are implemented, this file will be expanded with actual
// navigation to chat interfaces or AR views.
// ============================================================

import 'package:flutter/material.dart';

/// [AIScreen] is a stateless widget that renders two preview cards
/// for planned AI features.  No user interaction is wired up yet.
class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  /// Builds the AI screen layout: a vertically scrollable column
  /// containing two feature cards.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Card for the "Time Machine" AI feature.
                _buildAICard(
                  'The Time Machine',
                  'Teleport yourself to a specific era!',
                  Icons.hourglass_bottom,
                  Colors.blueAccent,
                ),

                const SizedBox(height: 16),

                // Card for the "Architecture Expert" AI feature.
                _buildAICard(
                  'The Architecture Expert',
                  'Here to answer all your queries',
                  Icons.architecture,
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single AI feature preview card.
  ///
  /// Parameters:
  ///   [title]    — Bold heading text (e.g. "The Time Machine").
  ///   [subtitle] — Secondary description text below the title.
  ///   [icon]     — Large icon displayed in the dark header area.
  ///   [color]    — Accent colour associated with this feature
  ///               (currently unused in styling but reserved for
  ///               future theming of each card).
  ///
  /// The card consists of a dark-grey header area with a centred icon,
  /// followed by a white content area with the title and subtitle.
  Widget _buildAICard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Header area — a dark placeholder with a large icon.
          // In production this could be replaced with an actual image
          // using DecorationImage(image: AssetImage('...')).
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              // In reality, use DecorationImage(image: AssetImage('...'))
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 60)),
          ),

          // Title and subtitle text area.
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Feature title.
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Feature subtitle / tagline.
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
