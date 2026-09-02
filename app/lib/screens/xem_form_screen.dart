import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';

class XemFormScreen extends StatefulWidget {
  const XemFormScreen({super.key, required this.controller, this.pickImage = defaultPickImage});
  final AppStateController controller;
  final ImagePickFn pickImage;

  @override
  State<XemFormScreen> createState() => _XemFormScreenState();
}

class _XemFormScreenState extends State<XemFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.controller.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Πίσω',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Ξεμάτιασμα',
                  style: TextStyle(
                      fontFamily: kHeadingFontFamily, fontVariations: kHeadingWeight, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Όνομα', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'π.χ. Μαρία'),
            onChanged: controller.setName,
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Φωτογραφία', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          ImageSlot(
            placeholder: 'Ρίξε τη φωτογραφία εδώ',
            imagePath: controller.xemPhotoPath,
            onImagePicked: controller.setXemPhoto,
            height: 220,
            pickImage: widget.pickImage,
          ),
          const SizedBox(height: AppTokens.space6),
          PrimaryButton(
            label: 'Ξεκίνα το ξεμάτιασμα',
            onPressed: controller.xemPhotoPath == null ? null : controller.submitXem,
          ),
        ],
      ),
    );
  }
}
