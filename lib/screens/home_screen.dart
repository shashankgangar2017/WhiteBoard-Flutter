import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'whiteboard_screen.dart';
import '../services/file_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FileSystemEntity> savedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // This method used to load all the files from the internal storage
  Future<void> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
    setState(() {
      savedFiles = files;
    });
  }

  // This method used to load file clicked in grid view
  void _openDrawing(String fileName) async {
    final data = await FileService.loadFromFile(fileName);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhiteboardScreen(loadedData: data),
      ),
    );
  }

  //This method is used to create new WhiteBoard
  void _createNewDrawing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WhiteboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Drawings')),
      body: savedFiles.isEmpty
          ? const Center(child: Text("No drawings found.\nCreate one to get started.", textAlign: TextAlign.center))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: savedFiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemBuilder: (_, index) {
                final name = savedFiles[index].uri.pathSegments.last;
                return GestureDetector(
                  onTap: () => _openDrawing(name),
                  child: Card(
                    elevation: 4,
                    child: Center(
                      child: Text(name, textAlign: TextAlign.center),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDrawing,
        icon: const Icon(Icons.add),
        label: const Text("New Drawing"),
      ),
    );
  }
}