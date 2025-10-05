import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_date/presentation/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController ageController;
  late final TextEditingController bioController;
  late final TextEditingController petNameController;
  late final TextEditingController petTypeController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    ageController = TextEditingController();
    bioController = TextEditingController();
    petNameController = TextEditingController();
    petTypeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.watch<ProfileViewModel>();
    if (!_initialized && !vm.isLoading) {
      final data = vm.data;
      nameController.text = data['name'] ?? '';
      ageController.text = data['age']?.toString() ?? '';
      bioController.text = data['bio'] ?? '';
      petNameController.text = data['petName'] ?? '';
      petTypeController.text = data['petType'] ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    bioController.dispose();
    petNameController.dispose();
    petTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final isLoading = vm.isLoading && !_initialized;
    final isBusy = vm.isLoading || vm.isUploading;
    final photos = vm.photoUrls;
    final primaryPhoto = photos.isNotEmpty ? photos.first : '';
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title:
              const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: AbsorbPointer(
                    absorbing: isBusy,
                    child: ListView(
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: primaryPhoto.isNotEmpty
                                    ? NetworkImage(primaryPhoto)
                                    : null,
                                child: primaryPhoto.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 48, color: Colors.white)
                                    : null,
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: vm.isUploading
                                        ? null
                                        : _pickAndUploadPhoto,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.pinkAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: vm.isUploading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt,
                                              color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PhotoGallery(
                          photos: photos,
                          isBusy: isBusy,
                          onAdd: vm.isUploading ? null : _pickAndUploadPhoto,
                          onRemove: vm.isUploading
                              ? null
                              : (url) async {
                                  try {
                                    await vm.removePhoto(url);
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error removing photo: $e')),
                                    );
                                  }
                                },
                          onSetPrimary: vm.isUploading
                              ? null
                              : (url) async {
                                  try {
                                    await vm.setPrimaryPhoto(url);
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error updating primary photo: $e')),
                                    );
                                  }
                                },
                          onReorder: vm.isUploading
                              ? null
                              : (oldIndex, newIndex) {
                                  vm
                                      .reorderPhotos(oldIndex, newIndex)
                                      .catchError((e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error reordering photos: $e')),
                                    );
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Name', nameController, Icons.person,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null),
                        _buildTextField('Age', ageController, Icons.cake,
                            keyboardType: TextInputType.number),
                        _buildTextField('Bio', bioController, Icons.info,
                            maxLines: 3),
                        _buildTextField(
                            'Pet Name', petNameController, Icons.pets),
                        _buildTextField(
                            'Pet Type', petTypeController, Icons.pets_outlined),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: vm.isLoading || vm.isUploading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final navigator = Navigator.of(context);
                                  try {
                                    await vm.save({
                                      'name': nameController.text.trim(),
                                      'age': ageController.text.trim().isEmpty
                                          ? 'Not specified'
                                          : ageController.text.trim(),
                                      'bio': bioController.text.trim(),
                                      'petName': petNameController.text.trim(),
                                      'petType': petTypeController.text.trim(),
                                    });
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text('Profile saved')),
                                    );
                                    navigator.pop();
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content: Text('Error saving: $e')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: vm.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Save',
                                  style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
              ));
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final vm = context.read<ProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked == null) return;
    try {
      final file = File(picked.path);
      await vm.uploadPhoto(file);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final bool isBusy;
  final Future<void> Function()? onAdd;
  final Future<void> Function(String url)? onRemove;
  final Future<void> Function(String url)? onSetPrimary;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const _PhotoGallery({
    required this.photos,
    required this.isBusy,
    required this.onAdd,
    required this.onRemove,
    this.onSetPrimary,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final canReorder = !isBusy && onReorder != null && photos.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: onAdd == null || isBusy ? null : () => onAdd?.call(),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add'),
            ),
          ],
        ),
        SizedBox(
          height: 120,
          child: photos.isEmpty
              ? Center(
                  child: Text(
                    'Add photos of you and your pet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : canReorder
                  ? ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      buildDefaultDragHandles: false,
                      itemCount: photos.length,
                      onReorder: (oldIndex, newIndex) {
                        if (onReorder == null || isBusy) return;
                        onReorder!(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final url = photos[index];
                        return Container(
                          key: ValueKey(url),
                          margin: EdgeInsets.only(
                              right: index == photos.length - 1 ? 0 : 12),
                          child: _PhotoTile(
                            url: url,
                            index: index,
                            isPrimary: index == 0,
                            isBusy: isBusy,
                            onRemove: onRemove,
                            onSetPrimary: onSetPrimary,
                            showDragHandle: true,
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final url = photos[index];
                        return _PhotoTile(
                          url: url,
                          index: index,
                          isPrimary: index == 0,
                          isBusy: isBusy,
                          onRemove: onRemove,
                          onSetPrimary: onSetPrimary,
                          showDragHandle: false,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final int index;
  final bool isPrimary;
  final bool isBusy;
  final Future<void> Function(String url)? onRemove;
  final Future<void> Function(String url)? onSetPrimary;
  final bool showDragHandle;

  const _PhotoTile({
    required this.url,
    required this.index,
    required this.isPrimary,
    required this.isBusy,
    required this.onRemove,
    required this.onSetPrimary,
    required this.showDragHandle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isPrimary ? Icons.star : Icons.star_border,
                color: isPrimary ? Colors.amber : Colors.white,
              ),
              tooltip: isPrimary ? 'Primary photo' : 'Set as primary',
              onPressed: isPrimary || isBusy || onSetPrimary == null
                  ? null
                  : () {
                      onSetPrimary!(url);
                    },
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Colors.redAccent),
              tooltip: 'Remove photo',
              onPressed: isBusy || onRemove == null
                  ? null
                  : () {
                      onRemove!(url);
                    },
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPrimary ? 'Primary' : 'Photo ${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          if (showDragHandle)
            Positioned(
              bottom: 6,
              right: 6,
              child: ReorderableDragStartListener(
                index: index,
                enabled: !isBusy,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.drag_indicator,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
