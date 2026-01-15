import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/api/items_repository.dart';
import 'package:frontend/blocs/auth/auth_bloc.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/places_service.dart';
import 'package:frontend/services/speech_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class ReportFoundItemScreen extends StatelessWidget {
  const ReportFoundItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportFoundItemForm();
  }
}

class ReportFoundItemForm extends StatefulWidget {
  const ReportFoundItemForm({super.key});

  @override
  State<ReportFoundItemForm> createState() => _ReportFoundItemFormState();
}

class _ReportFoundItemFormState extends State<ReportFoundItemForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _image;
  LocationData? _locationData;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String _selectedCategory = 'Electronics';

  // Voice recording
  bool _isListening = false;
  String _partialSpeechText = '';
  final SpeechService _speechService = SpeechService();

  // Location autocomplete
  final PlacesService _placesService = PlacesService();
  List<PlacePrediction> _placePredictions = [];
  bool _showPlacePredictions = false;
  bool _isLoadingPlaces = false;

  final List<String> _categories = [
    'People',
    'Electronics',
    'Pets',
    'Documents',
    'Jewelry',
    'Bags & Wallets',
    'Keys',
    'Clothing',
    'Glasses & Eyewear',
    'Watches',
    'Headphones & Earbuds',
    'Laptops & Tablets',
    'Phones',
    'Cameras',
    'Sports Equipment',
    'Books & Stationery',
    'Toys',
    'Medical Items',
    'Umbrellas',
    'Other',
  ];

  // Optional person-specific fields when category == 'People'
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _personAgeController = TextEditingController();
  final TextEditingController _personWhereaboutsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fetch user location for distance calculations
    _fetchUserLocationSilently();
  }

  /// Silently fetch user location in background for distance calculations
  Future<void> _fetchUserLocationSilently() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) return;

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) return;

      final locationData = await location.getLocation();
      if (mounted && locationData.latitude != null) {
        setState(() {
          _locationData = locationData;
        });
        // Also set in PlacesService for future queries
        _placesService.setUserLocation(
          locationData.latitude!,
          locationData.longitude!,
        );
      }
    } catch (e) {
      // Silently fail - user can still use GPS button manually
      print('📍 Silent location fetch failed: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _personNameController.dispose();
    _personAgeController.dispose();
    _personWhereaboutsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Crop image to square for Instagram compatibility
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF0EA5E9),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _image = File(croppedFile.path);
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showErrorSnackBar('Location services are disabled');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showErrorSnackBar('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final locationData = await location.getLocation();
      setState(() {
        _locationData = locationData;
        _isLoadingLocation = true;
      });

      // Use PlacesService to get human-readable address
      if (locationData.latitude != null && locationData.longitude != null) {
        final address = await _placesService.getShortAddressFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );
        setState(() {
          if (address != null && address.isNotEmpty) {
            _locationController.text = address;
          } else {
            _locationController.text =
                '${locationData.latitude?.toStringAsFixed(6)}, ${locationData.longitude?.toStringAsFixed(6)}';
          }
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationController.text =
              '${locationData.latitude?.toStringAsFixed(6)}, ${locationData.longitude?.toStringAsFixed(6)}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Toggle voice recording on/off
  Future<void> _toggleVoiceRecording() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
        _partialSpeechText = '';
      });
    } else {
      final available = await _speechService.isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Speech recognition not available'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _partialSpeechText = '';
      });

      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _isListening = false;
            _partialSpeechText = '';
            if (text.isNotEmpty) {
              final currentText = _descriptionController.text;
              if (currentText.isNotEmpty && !currentText.endsWith(' ')) {
                _descriptionController.text = '$currentText $text';
              } else {
                _descriptionController.text = '$currentText$text';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Added: "$text"')),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        },
        onPartialResult: (text) {
          setState(() => _partialSpeechText = text);
        },
      );
    }
  }

  /// Search for places when user types
  Future<void> _onLocationSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _placePredictions = [];
        _showPlacePredictions = false;
      });
      return;
    }

    setState(() => _isLoadingPlaces = true);

    try {
      // Pass user's location for distance calculation
      final predictions = await _placesService.getPlacePredictions(
        query,
        userLat: _locationData?.latitude,
        userLng: _locationData?.longitude,
      );
      setState(() {
        _placePredictions = predictions;
        _showPlacePredictions = predictions.isNotEmpty;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      setState(() {
        _placePredictions = [];
        _showPlacePredictions = false;
        _isLoadingPlaces = false;
      });
    }
  }

  /// Select a place from autocomplete
  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() {
      _locationController.text = prediction.description;
      _showPlacePredictions = false;
      _placePredictions = [];
      _isLoadingPlaces = true;
    });

    try {
      final details = await _placesService.getPlaceDetails(prediction.placeId);
      if (details != null) {
        setState(() {
          _locationData = LocationData.fromMap({
            'latitude': details.latitude,
            'longitude': details.longitude,
          });
          _isLoadingPlaces = false;
        });
      } else {
        setState(() => _isLoadingPlaces = false);
      }
    } catch (e) {
      setState(() => _isLoadingPlaces = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_image == null) {
      _showErrorSnackBar('Please add a photo');
      return;
    }

    if (_locationData == null && _locationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add the location where it was found');
      return;
    }

    // ✅ Check if user is authenticated
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get the items repository
      final itemsRepository = context.read<ItemsRepository>();
      final userId = authState.uid;

      // Parse location
      double latitude = _locationData?.latitude ?? 0.0;
      double longitude = _locationData?.longitude ?? 0.0;

      // If location was entered manually, try to parse it
      if (_locationData == null && _locationController.text.isNotEmpty) {
        final parts = _locationController.text.split(',');
        if (parts.length == 2) {
          latitude = double.tryParse(parts[0].trim()) ?? 0.0;
          longitude = double.tryParse(parts[1].trim()) ?? 0.0;
        }
      }

      // Build description with person details if applicable
      String fullDescription = _descriptionController.text;
      if (_selectedCategory == 'People') {
        final personDetails = <String>[];
        if (_personNameController.text.isNotEmpty) {
          personDetails.add('Name: ${_personNameController.text}');
        }
        if (_personAgeController.text.isNotEmpty) {
          personDetails.add('Age: ${_personAgeController.text}');
        }
        if (_personWhereaboutsController.text.isNotEmpty) {
          personDetails.add('Found at: ${_personWhereaboutsController.text}');
        }
        if (personDetails.isNotEmpty) {
          fullDescription = '${personDetails.join(', ')}\n\n$fullDescription';
        }
      }

      // Create the item (isLost: false for found items)
      final item = Item(
        id: '', // Will be set by Firestore
        description: '${_titleController.text}|||$fullDescription',
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        isLost: false, // This is a FOUND item
        userId: userId,
        category: _selectedCategory,
        status: 'active',
        placeName: _locationController.text,
      );

      // Save to Firebase with image (includes retry logic)
      await itemsRepository.addItem(item, image: _image);

      setState(() => _isSubmitting = false);
      _showSuccessSnackBar('Report submitted successfully!');

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Failed to submit report: $e');
    }
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Sign In Required'),
          ],
        ),
        content: const Text(
          'You need to sign in to report found items. This helps lost item owners contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'What did you find?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Help reunite this with its owner',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Item Title
              // Name
              Text(
                'Name',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                hintText: 'e.g., Black iPhone 15 Pro or Max',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.primary,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // If category is People, show person-specific optional fields
              if (_selectedCategory == 'People') ...[
                Text(
                  'Person Details (optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _personNameController,
                  hintText: 'Name (optional)',
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _personAgeController,
                  hintText: 'Age (optional)',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _personWhereaboutsController,
                  hintText: 'Last known whereabouts (optional)',
                  prefixIcon: Icons.place,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Describe in detail...',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 10) {
                    return 'Description should be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Image Section
              Text(
                'Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _image != null
                          ? colorScheme.primary
                          : Colors.grey.shade300,
                      width: _image != null ? 2 : 1,
                    ),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_image!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _image = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(150),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo or choose from gallery',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Voice Description Section
              Center(
                child: Text(
                  _isListening
                      ? 'Listening... Tap to stop'
                      : 'or describe by voice',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isListening
                        ? colorScheme.primary
                        : Colors.grey.shade600,
                    fontWeight: _isListening
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isListening && _partialSpeechText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(75),
                    ),
                  ),
                  child: Text(
                    _partialSpeechText,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _toggleVoiceRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isListening ? 80 : 64,
                    height: _isListening ? 80 : 64,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red
                          : const Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isListening
                                      ? Colors.red
                                      : const Color(0xFF0EA5E9))
                                  .withAlpha(100),
                          blurRadius: _isListening ? 30 : 20,
                          spreadRadius: _isListening ? 8 : 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: _isListening ? 36 : 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // AI-Powered Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Powered',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Our AI will auto-identify the item and generate a description.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Section
              Text(
                'Where did you find?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Type to search (e.g. West Tambaram)',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: colorScheme.primary,
                            ),
                            suffixIcon: _isLoadingPlaces
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: _onLocationSearch,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isLoadingLocation ? null : _getLocation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingLocation
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ],
                  ),
                  // Place Predictions Dropdown
                  if (_showPlacePredictions &&
                      _placePredictions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _placePredictions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final prediction = _placePredictions[index];
                          return ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey.shade600,
                                  size: 22,
                                ),
                                if (prediction.distanceText.isNotEmpty)
                                  Text(
                                    prediction.distanceText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              prediction.mainText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              prediction.secondaryText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            onTap: () => _selectPlace(prediction),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (_locationData != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Location captured successfully',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),

              // Submit Button
              CustomButton(
                onPressed: _submitForm,
                text: 'Submit Report',
                isLoading: _isSubmitting,
                icon: Icons.send,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
