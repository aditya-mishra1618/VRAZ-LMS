import 'package:flutter/material.dart';

import 'models/course_models.dart';

class NotesViewScreen extends StatelessWidget {
  final List<LMSContentModel> notes;

  const NotesViewScreen({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    // Filter notes by type
    final pdfs = notes.where((note) => note.contentType == 'PDF').toList();
    final links = notes.where((note) => note.contentType == 'Link').toList();
    // You can add more types like 'Image' if your model supports it
    final images = notes.where((note) => note.contentType == 'Image').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes & Resources'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDFs'),
              Tab(icon: Icon(Icons.image_outlined), text: 'Images'),
              Tab(icon: Icon(Icons.link), text: 'Links'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotesList(context, pdfs, Icons.picture_as_pdf, Colors.purple),
            _buildNotesList(
                context, images, Icons.image_outlined, Colors.orange),
            _buildNotesList(context, links, Icons.link, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, List<LMSContentModel> items,
      IconData icon, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items found.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () {
              // Mock tap action
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Opening ${item.title}...'),
                backgroundColor: Colors.blueAccent,
              ));
            },
          ),
        );
      },
    );
  }
}
