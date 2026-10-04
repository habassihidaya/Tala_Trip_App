import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';

class AddHotelPage extends StatefulWidget {
  final HotelEntity? hotel;

  const AddHotelPage({
    super.key,
    this.hotel,
  });

  @override
  State<AddHotelPage> createState() => _AddHotelPageState();
}

class _AddHotelPageState extends State<AddHotelPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mapUrlController = TextEditingController();

  final _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _existingImages = [];

  final List<String> _wilayas = [
    'Alger',
    'Oran',
    'Béjaïa',
    'Annaba',
    'Tipaza',
  ];

  String? _selectedWilaya;
  bool _isPickingImages = false;
  bool _saveRequested = false;

  bool get _isEditing => widget.hotel != null;

  @override
  void initState() {
    super.initState();

    final hotel = widget.hotel;
    if (hotel == null) return;

    _nameController.text = hotel.name;
    _descriptionController.text = hotel.description;
    _addressController.text = hotel.address;
    _phoneController.text = hotel.phoneNumber;
    _mapUrlController.text = hotel.mapUrl ?? '';

    _existingImages.addAll(hotel.images);

    if (hotel.wilaya.isNotEmpty) {
      // Preserve any existing value that differs from our current list.
      if (!_wilayas.contains(hotel.wilaya)) {
        _wilayas.add(hotel.wilaya);
      }
      _selectedWilaya = hotel.wilaya;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mapUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPickingImages || _saveRequested) return;

    FocusScope.of(context).unfocus();
    setState(() => _isPickingImages = true);

    try {
      final photos = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 80,
      );

      if (!mounted) return;

      setState(() {
        for (final photo in photos) {
          final alreadySelected = _selectedImages.any(
            (selected) => selected.path == photo.path,
          );

          if (!alreadySelected) {
            _selectedImages.add(photo);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open photos. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _saveDraft(BuildContext blocContext) {
    if (_isPickingImages || _saveRequested) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bloc = blocContext.read<HotelBloc>();
    if (bloc.state is HotelLoadingState) return;

    final original = widget.hotel;

    if (original != null &&
        original.status.name != 'draft' &&
        original.status.name != 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only draft or rejected hotels can be edited.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final mapText = _mapUrlController.text.trim();
    final mapUrl = mapText.isEmpty ? null : mapText;
    final photoPaths = _selectedImages.map((photo) => photo.path).toList();

    setState(() => _saveRequested = true);

    if (original == null) {
      bloc.add(
        CreateHotelDraftEvent(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          wilaya: _selectedWilaya ?? '',
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          photoPaths: photoPaths,
          mapUrl: mapUrl,
        ),
      );
      return;
    }

    final editedHotel = HotelEntity(
      id: original.id,
      ownerId: original.ownerId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      wilaya: _selectedWilaya ?? '',
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      images: List.unmodifiable(_existingImages),
      mapUrl: mapUrl,
      status: original.status,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      reviewedAt: original.reviewedAt,
      reviewedBy: original.reviewedBy,
      rejectionReason: original.rejectionReason,
    );

    bloc.add(
      UpdateHotelDraftEvent(
        hotel: editedHotel,
        photoPaths: photoPaths,
      ),
    );
  }

  Widget _photoPreview({
    required Widget image,
    required VoidCallback onRemove,
  }) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const ColoredBox(
      color: Colors.black12,
      child: Icon(Icons.broken_image_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HotelBloc>(
      create: (_) => getIt<HotelBloc>(),
      child: BlocConsumer<HotelBloc, HotelState>(
        listener: (context, state) {
          if (state is HotelErrorState) {
            setState(() => _saveRequested = false);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }

          final saved = state is HotelDraftCreatedState ||
              (state is HotelActionSuccessState &&
                  state.action == HotelAction.updated);

          if (saved) {
            // Allow PopScope to rebuild before navigating back.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pop(true);
            });
          }
        },
        builder: (context, state) {
          final saving = state is HotelLoadingState;
          final saved = state is HotelDraftCreatedState ||
              (state is HotelActionSuccessState &&
                  state.action == HotelAction.updated);
          final busy = saving || saved || _saveRequested;

          return PopScope(
            canPop: saved || (!saving && !_saveRequested),
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isEditing ? 'Edit hotel' : 'Add hotel'),
                automaticallyImplyLeading: !busy,
              ),
              body: AbsorbPointer(
                absorbing: busy,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isEditing) ...[
                          const Text(
                            'Saving keeps this hotel as a draft. '
                            'Submit it for review when you are ready.',
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Hotel name',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the hotel name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Tell travelers about your hotel.',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWilaya,
                          decoration: const InputDecoration(
                            labelText: 'Wilaya',
                            border: OutlineInputBorder(),
                          ),
                          items: _wilayas.map((wilaya) {
                            return DropdownMenuItem<String>(
                              value: wilaya,
                              child: Text(wilaya),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _selectedWilaya = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: 'Example: 0550123456',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mapUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Google Maps link (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;

                            final uri = Uri.tryParse(text);

                            if (uri == null ||
                                (uri.scheme != 'https' &&
                                    uri.scheme != 'http') ||
                                uri.host.isEmpty) {
                              return 'Enter a valid web link.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _isPickingImages ? null : _pickImages,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                          ),
                          label: Text(
                            _isPickingImages
                                ? 'Opening photos...'
                                : 'Choose photos',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_existingImages.isEmpty &&
                            _selectedImages.isEmpty)
                          const Text('No photos selected yet.'),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final url in _existingImages)
                              _photoPreview(
                                image: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: _photoError,
                                ),
                                onRemove: () {
                                  setState(() {
                                    _existingImages.remove(url);
                                  });
                                },
                              ),
                            for (final photo in _selectedImages)
                              _photoPreview(
                                image: Image.file(
                                  File(photo.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: _photoError,
                                ),
                                onRemove: () {
                                  setState(() {
                                    _selectedImages.remove(photo);
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: busy || _isPickingImages
                      ? null
                      : () => _saveDraft(context),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Save changes' : 'Save draft',
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}