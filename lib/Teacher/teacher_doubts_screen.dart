import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Teacher/models/teacher_doubt_model.dart';

import 'package:vraz_application/Teacher/services/teacher_doubt_service.dart';
import '../teacher_session_manager.dart';
import 'doubt_discussionn.dart';
import 'teacher_app_drawer.dart';

class TeacherDoubtsScreen extends StatefulWidget {
  const TeacherDoubtsScreen({super.key});

  @override
  State<TeacherDoubtsScreen> createState() => _TeacherDoubtsScreenState();
}

class _TeacherDoubtsScreenState extends State<TeacherDoubtsScreen> {
  final TeacherDoubtService _doubtService = TeacherDoubtService();

  // API Data
  List<TeacherDoubtModel> _doubts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Real-time polling
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 3);

  // Filter
  String _selectedFilter = 'All'; // All, New, In Progress, Resolved

  @override
  void initState() {
    super.initState();
    _fetchDoubts();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ========== API METHODS ==========

  Future<void> _fetchDoubts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      print('📥 Fetching teacher doubts...');

      final doubts = await _doubtService.getMyDoubts(token);

      setState(() {
        _doubts = doubts;
        _isLoading = false;
      });

      print('✅ Loaded ${doubts.length} doubts');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading doubts: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doubts: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchDoubts,
            ),
          ),
        );
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted && !_isLoading) {
        _refreshDoubts();
      }
    });
  }

  Future<void> _refreshDoubts() async {
    try {
      final sessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) return;

      final doubts = await _doubtService.getMyDoubts(token);

      if (mounted && doubts.length != _doubts.length) {
        setState(() {
          _doubts = doubts;
        });
        print('🔄 Doubts updated: ${_doubts.length} doubts');
      }
    } catch (e) {
      print('⚠️ Error refreshing doubts: $e');
    }
  }

  List<TeacherDoubtModel> get _filteredDoubts {
    if (_selectedFilter == 'All') return _doubts;
    return _doubts.where((doubt) {
      switch (_selectedFilter) {
        case 'New':
          return doubt.isNew;
        case 'In Progress':
          return doubt.isInProgress;
        case 'Resolved':
          return doubt.isResolved;
        default:
          return true;
      }
    }).toList();
  }

  // ========== UI METHODS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text('Student Doubts',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchDoubts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _filteredDoubts.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
              onRefresh: _fetchDoubts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _filteredDoubts.length,
                itemBuilder: (context, index) {
                  return _buildDoubtCard(context, _filteredDoubts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'New', 'In Progress', 'Resolved'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.blueAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load doubts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchDoubts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedFilter.toLowerCase()} doubts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'No student doubts assigned yet'
                : 'Try selecting a different filter',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubtCard(BuildContext context, TeacherDoubtModel doubt) {
    Color statusColor;
    Color statusBgColor;

    if (doubt.isNew) {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
    } else if (doubt.isResolved) {
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.shade200;
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDiscussDoubtScreen(
                doubt: doubt, // Pass the entire doubt object
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Avatar with Initials
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      doubt.student.getInitials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doubt.student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(doubt.subject.name,
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  Text(doubt.getRelativeTime(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 52.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic: ${doubt.topic.name}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(doubt.initialQuestion,
                        style: TextStyle(color: Colors.grey[700], height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doubt.displayStatus,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        if (doubt.isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  'Needs Response',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}