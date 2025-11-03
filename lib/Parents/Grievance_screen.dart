import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/greivance_api.dart';

import 'grievance_chat_screen.dart';
import 'models/grivance_model.dart';
import 'parent_app_drawer.dart';

class GrievanceScreen extends StatefulWidget {
  const GrievanceScreen({super.key});

  @override
  State<GrievanceScreen> createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  List<Grievance> _allGrievances = [];
  List<Grievance> _filteredGrievances = [];
  GrievanceSummary? _summary;
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadGrievances();
  }

  Future<void> _loadGrievances() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get auth token
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');

      print('[GrievanceScreen] Auth Token: ${_authToken != null ? "Found" : "Missing"}');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      // 2. Fetch grievances from API
      print('[GrievanceScreen] 🔄 Fetching grievances...');
      _allGrievances = await GrievanceApi.fetchGrievances(
        authToken: _authToken!,
      );

      if (_allGrievances.isNotEmpty) {
        _summary = GrievanceApi.calculateSummary(_allGrievances);
        _filteredGrievances = _allGrievances;
        print('[GrievanceScreen] ✅ Loaded ${_allGrievances.length} grievances');
        print('[GrievanceScreen] 📊 Summary: $_summary');
      } else {
        print('[GrievanceScreen] ℹ️ No grievances found');
        _filteredGrievances = [];
      }
    } catch (e, stackTrace) {
      print('[GrievanceScreen] ❌ Error: $e');
      print('[GrievanceScreen] Stack trace: $stackTrace');
      _showError('Failed to load grievances. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'ALL') {
        _filteredGrievances = _allGrievances;
      } else {
        _filteredGrievances = GrievanceApi.filterByStatus(_allGrievances, filter);
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Grievances',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _loadGrievances,
            tooltip: 'Refresh',
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadGrievances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_summary != null) _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildFilterChips(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == 'ALL'
                        ? 'All Grievances'
                        : '$_selectedFilter Grievances',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_filteredGrievances.length} total',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_filteredGrievances.isEmpty)
                _buildEmptyState()
              else
                ..._filteredGrievances.map((g) => _buildGrievanceCard(g)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await _showTicketModal(context);
          if (result == true) {
            _loadGrievances();
          }
        },
        label: const Text('Raise New Ticket'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Open',
            _summary!.openCount.toString(),
            Colors.blue,
            Icons.pending_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            _summary!.inProgressCount.toString(),
            Colors.orange,
            Icons.autorenew,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Resolved',
            _summary!.resolvedCount.toString(),
            Colors.green,
            Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('OPEN', 'Open'),
          const SizedBox(width: 8),
          _buildFilterChip('IN_PROGRESS', 'In Progress'),
          const SizedBox(width: 8),
          _buildFilterChip('RESOLVED', 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyFilter(value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blueAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blueAccent : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No grievances found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to raise a new ticket',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievanceCard(Grievance grievance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          grievance.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              grievance.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  grievance.formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: grievance.statusBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grievance.displayStatus,
            style: TextStyle(
              color: grievance.statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          // ✅ UPDATED: Navigate to chat with grievance ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrievanceChatScreen(
                grievanceTitle: grievance.title,
                navigationSource: 'grievance_list',
                grievanceId: grievance.id, // ✅ Pass the ID
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showTicketModal(BuildContext context) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RaiseTicketModal(authToken: _authToken!);
      },
    );
  }
}

// Raise Ticket Modal
class RaiseTicketModal extends StatefulWidget {
  final String authToken;

  const RaiseTicketModal({super.key, required this.authToken});

  @override
  State<RaiseTicketModal> createState() => _RaiseTicketModalState();
}

class _RaiseTicketModalState extends State<RaiseTicketModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory = 'Academic';
  File? _attachedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _attachedImage = File(pickedFile.path);
          _isUploading = true;
        });

        // ✅ AUTO-UPLOAD when captured from camera
        await _uploadImage();
      }
    } catch (e) {
      print('[RaiseTicket] ❌ Camera error: $e');
      _showError('Failed to capture image. Please try again.');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _attachedImage = File(pickedFile.path);
        });

        // ✅ ASK FOR CONFIRMATION when selected from gallery
        final confirmed = await _showConfirmationDialog();

        if (confirmed == true) {
          setState(() => _isUploading = true);
          await _uploadImage();
        } else {
          // User cancelled, remove the image
          setState(() {
            _attachedImage = null;
          });
        }
      }
    } catch (e) {
      print('[RaiseTicket] ❌ Gallery error: $e');
      _showError('Failed to select image. Please try again.');
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Attachment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _attachedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Do you want to attach this image to your grievance?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'Attach Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    if (_attachedImage == null) return;

    try {
      print('[RaiseTicket] 📤 Uploading image...');

      final uploadedUrl = await GrievanceApi.uploadMedia(
        authToken: widget.authToken,
        file: _attachedImage!,
      );

      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrl = uploadedUrl;
          _isUploading = false;
        });

        _showSuccess('✅ Image uploaded successfully!');
        print('[RaiseTicket] ✅ Image URL: $uploadedUrl');
      } else {
        setState(() {
          _attachedImage = null;
          _isUploading = false;
        });
        _showError('Failed to upload image. Please try again.');
      }
    } catch (e) {
      print('[RaiseTicket] ❌ Upload error: $e');
      setState(() {
        _attachedImage = null;
        _isUploading = false;
      });
      _showError('Failed to upload image. Please try again.');
    }
  }

  Future<void> _submitGrievance() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description');
      return;
    }

    if (_isUploading) {
      _showError('Please wait for image upload to complete');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final attachments = _uploadedImageUrl != null ? [_uploadedImageUrl!] : null;

      final success = await GrievanceApi.createGrievance(
        authToken: widget.authToken,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        attachments: attachments,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Grievance submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showError('❌ Failed to submit grievance. Please try again.');
        }
      }
    } catch (e) {
      print('[RaiseTicket] Error: $e');
      if (mounted) {
        _showError('❌ An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Raise New Ticket',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildAttachmentSection(),
              if (_attachedImage != null) _buildImagePreview(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ticket Title', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g., Bus Service Issue',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ['Academic', 'Payment', 'Attendance', 'Transport', 'Other']
                .map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please describe the issue in detail...',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachments (Optional)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAttachmentButton(
                Icons.camera_alt_outlined,
                'Camera',
                _isUploading ? null : _pickImageFromCamera,
                tooltip: 'Capture & Upload',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAttachmentButton(
                Icons.photo_library_outlined,
                'Gallery',
                _isUploading ? null : _pickImageFromGallery,
                tooltip: 'Select from Gallery',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(
      IconData icon,
      String label,
      VoidCallback? onPressed, {
        String? tooltip,
      }) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.file(
                  _attachedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (_isUploading)
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_uploadedImageUrl != null && !_isUploading)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Uploaded',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_isUploading)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: () => setState(() {
                  _attachedImage = null;
                  _uploadedImageUrl = null;
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: (_isSubmitting || _isUploading) ? null : _submitGrievance,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[400],
      ),
      child: _isSubmitting
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        _isUploading ? 'Uploading Image...' : 'Submit',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}