import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/touchpad_viewmodel.dart';
import '../models/command.dart';

/// Mode selection view for choosing control mode
/// 
/// Requirements:
/// - 7.1: Select presentation mode
/// - 7.2: Select media control mode
/// - 7.3: Select basic mouse mode
class ModeSelectionView extends StatelessWidget {
  const ModeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('Select Mode'),
      ),
      body: SafeArea(
        child: Consumer<TouchpadViewModel>(
          builder: (context, viewModel, child) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Description
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Choose a control mode for your touchpad',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Presentation Mode
                _buildModeCard(
                  context: context,
                  mode: ControlMode.presentation,
                  icon: Icons.present_to_all,
                  title: 'Presentation Mode',
                  description: 'Navigate slides with arrow keys. Perfect for presentations.',
                  isSelected: viewModel.currentMode == ControlMode.presentation,
                  onTap: () => _selectMode(context, viewModel, ControlMode.presentation),
                  accentColor: Colors.blue,
                ),

                const SizedBox(height: 16),

                // Media Control Mode
                _buildModeCard(
                  context: context,
                  mode: ControlMode.mediaControl,
                  icon: Icons.music_note,
                  title: 'Media Control Mode',
                  description: 'Control media playback and volume. Tap to play/pause, swipe up/down for volume.',
                  isSelected: viewModel.currentMode == ControlMode.mediaControl,
                  onTap: () => _selectMode(context, viewModel, ControlMode.mediaControl),
                  accentColor: Colors.purple,
                ),

                const SizedBox(height: 16),

                // Basic Mouse Mode
                _buildModeCard(
                  context: context,
                  mode: ControlMode.basicMouse,
                  icon: Icons.mouse,
                  title: 'Basic Mouse Mode',
                  description: 'Standard mouse control with cursor movement and clicks.',
                  isSelected: viewModel.currentMode == ControlMode.basicMouse,
                  onTap: () => _selectMode(context, viewModel, ControlMode.basicMouse),
                  accentColor: Colors.blue,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required ControlMode mode,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    Color accentColor = Colors.blue,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey[700]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.3)
                      : Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected ? accentColor : Colors.grey[400],
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: accentColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMode(
    BuildContext context,
    TouchpadViewModel viewModel,
    ControlMode mode,
  ) {
    viewModel.setMode(mode);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode changed to ${_getModeDisplayName(mode)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getModeDisplayName(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return 'Presentation';
      case ControlMode.mediaControl:
        return 'Media Control';
      case ControlMode.basicMouse:
        return 'Basic Mouse';
    }
  }
}
