import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';

class AvatarConstants {
  static const List<Color> colors = [
    Color(0xFF53B175),
    Color(0xFFF3603F),
    Color(0xFF4A90E2),
    Color(0xFFF5A623),
    Color(0xFF9013FE),
    Color(0xFFE91E63),
  ];

  static const List<IconData> icons = [
    Icons.person,
    Icons.face,
    Icons.sentiment_satisfied_alt,
    Icons.emoji_emotions,
    Icons.nature_people,
    Icons.account_circle,
  ];
}

class UserAvatar extends StatelessWidget {
  final String? customImage;
  final int avatarIndex;
  final double radius;
  final bool showCameraBadge;
  final VoidCallback? onTap;
  final VoidCallback? onCameraTap;

  const UserAvatar({
    super.key,
    this.customImage,
    this.avatarIndex = 0,
    this.radius = 34,
    this.showCameraBadge = false,
    this.onTap,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final validIndex = (avatarIndex >= 0 && avatarIndex < AvatarConstants.colors.length)
        ? avatarIndex
        : 0;
    final color = AvatarConstants.colors[validIndex];
    final icon = AvatarConstants.icons[validIndex];

    Widget content;
    final hasCustom = customImage != null && customImage!.trim().isNotEmpty;

    if (hasCustom) {
      try {
        final bytes = base64Decode(customImage!.trim());
        content = Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallback(color, icon),
            ),
          ),
        );
      } catch (_) {
        content = _buildFallback(color, icon);
      }
    } else {
      content = _buildFallback(color, icon);
    }

    Widget avatarWidget = content;

    if (showCameraBadge) {
      final badgeSize = (radius * 0.65).clamp(24.0, 36.0);
      final iconSize = (badgeSize * 0.55).clamp(14.0, 20.0);

      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onCameraTap ?? onTap,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback(Color color, IconData icon) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: radius * 1.15,
          color: color,
        ),
      ),
    );
  }
}

/// Bottom sheet dialog allowing the user to pick an image from camera or gallery,
/// or remove custom photo.
Future<void> showProfilePhotoOptions({
  required BuildContext context,
  required Function(String base64Image) onImagePicked,
  VoidCallback? onRemovePhoto,
  bool hasCustomImage = false,
}) async {
  final picker = ImagePicker();

  Future<void> pick(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Str = base64Encode(bytes);
        onImagePicked(base64Str);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Picture',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose an image from your device or take a photo',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textGrey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: const Text(
                'Use your device camera',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
              onTap: () => pick(ImageSource.camera),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined, color: Color(0xFF4A90E2)),
              ),
              title: const Text(
                'Choose from Device / Gallery',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: const Text(
                'Select a photo from your gallery or files',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
              onTap: () => pick(ImageSource.gallery),
            ),
            if (hasCustomImage) ...[
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                title: const Text(
                  'Remove Custom Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  'Switch back to default avatar icon',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
                onTap: () {
                  Navigator.pop(ctx);
                  if (onRemovePhoto != null) {
                    onRemovePhoto();
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
