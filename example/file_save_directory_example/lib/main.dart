import 'package:file_save_directory/file_save_directory.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _saveResult = 'No save performed.';

  // Dummy data for testing
  final String fileName = 'my_example_file.txt';
  final List<int> fileBytes = 'Hello from Flutter File Saver!'.codeUnits;

  Future<void> _saveFile(SaveLocation location) async {
    setState(() {
      _saveResult = 'Saving...';
    });

    final result = await FileSaveDirectory.instance.saveFile(
      fileName: fileName,
      fileBytes: fileBytes,
      location: location,
    );

    setState(() {
      if (result.success) {
        _saveResult = 'File saved successfully to: ${result.path}';
      } else {
        _saveResult = 'Failed to save file: ${result.error}';
        if (result.needsPermission) {
          _saveResult += '\nPermission required! Please grant in app settings.';
          // Optionally, add a button to open settings for manual testing
          // FlutterFileSaver.instance.openAppSettings();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _saveFile(SaveLocation.downloads),
                child: const Text('Save to Downloads'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _saveFile(SaveLocation.documents),
                child: const Text('Save to Documents'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _saveFile(SaveLocation.appDocuments),
                child: const Text('Save to App Documents'),
              ),
              const SizedBox(height: 20),
              Text(_saveResult),
            ],
          ),
        ),
      ),
    );
  }
}
