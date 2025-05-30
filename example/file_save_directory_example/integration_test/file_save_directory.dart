import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_save_directory/file_save_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart'; // For appDocuments testing
import 'package:permission_handler/permission_handler.dart'; // For permission testing

void main() {
  // Initialize the IntegrationTestWidgetsFlutterBinding to ensure the test environment is ready
  // final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterFileSaver Integration Tests', () {
    late FileSaveDirectory fileStore;

    setUp(() {
      fileStore = FileSaveDirectory.instance;
      // You might want to delete previously saved test files here
      // for a clean slate, but be careful not to delete user data!
    });

    // --- Helper function to create some dummy file bytes ---
    Uint8List createDummyFileBytes(String content) {
      return Uint8List.fromList(content.codeUnits);
    }

    // --- Tests for SaveLocation.downloads ---
    testWidgets('Save to Downloads folder (Android/iOS Documents)', (
      WidgetTester tester,
    ) async {
      final fileName =
          'test_download_${DateTime.now().millisecondsSinceEpoch}.txt';
      final fileContent = 'This is a test file for downloads.'; /*  */
      final fileBytes = createDummyFileBytes(fileContent);

      // On Android, request permission for older SDKs
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          // For SDK < 33, request WRITE_EXTERNAL_STORAGE
          final status = await Permission.storage.request();
          expect(
            status.isGranted,
            true,
            reason: 'Storage permission should be granted for Android < 33',
          );
        }
      }

      final result = await fileStore.saveFile(
        fileName: fileName,
        fileBytes: fileBytes,
        location: SaveLocation.downloads,
      );

      expect(
        result.success,
        true,
        reason: 'File should be saved successfully to downloads',
      );
      expect(result.path, isNotNull, reason: 'Path should not be null');
      print('Saved to Downloads/Documents: ${result.path}');

      // Optional: Verify file existence (challenging for public dirs due to scoped storage)
      // For public directories, verifying existence is harder.
      // For app-specific directories, it's straightforward.
    });

    // --- Tests for SaveLocation.documents ---
    testWidgets('Save to Documents folder', (WidgetTester tester) async {
      final fileName =
          'test_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final fileContent = 'This is a test PDF content.'; // Simulate PDF content
      final fileBytes = createDummyFileBytes(fileContent);

      // On Android, request permission for older SDKs
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 33) {
          final status = await Permission.storage.request();
          expect(
            status.isGranted,
            true,
            reason: 'Storage permission should be granted for Android < 33',
          );
        }
      }

      final result = await fileStore.saveFile(
        fileName: fileName,
        fileBytes: fileBytes,
        location: SaveLocation.documents,
      );

      expect(
        result.success,
        true,
        reason: 'File should be saved successfully to documents',
      );
      expect(result.path, isNotNull, reason: 'Path should not be null');
      print('Saved to Documents: ${result.path}');
    });

    // --- Tests for SaveLocation.appDocuments ---
    testWidgets('Save to App Documents folder (private)', (
      WidgetTester tester,
    ) async {
      final fileName =
          'test_app_doc_${DateTime.now().millisecondsSinceEpoch}.txt';
      final fileContent = 'This is a test file for app private documents.';
      final fileBytes = createDummyFileBytes(fileContent);

      final result = await fileStore.saveFile(
        fileName: fileName,
        fileBytes: fileBytes,
        location: SaveLocation.appDocuments,
      );

      expect(
        result.success,
        true,
        reason: 'File should be saved successfully to app documents',
      );
      expect(result.path, isNotNull, reason: 'Path should not be null');
      print('Saved to App Documents: ${result.path}');

      // Verify file existence in app documents (easier to verify)
      final appDocDir = await getApplicationDocumentsDirectory();
      final savedFile = File(result.path!);
      expect(
        await savedFile.exists(),
        true,
        reason: 'File should exist in app documents',
      );
      expect(
        await savedFile.readAsString(),
        fileContent,
        reason: 'File content should match',
      );

      // Clean up the test file
      await savedFile.delete();
      expect(
        await savedFile.exists(),
        false,
        reason: 'File should be deleted after test',
      );
    });

    // --- Test for duplicate file naming ---
    testWidgets('Handles duplicate file names in App Documents', (
      WidgetTester tester,
    ) async {
      final baseFileName = 'duplicate_test.txt';
      final fileContent = 'Content for duplicate file.';
      final fileBytes = createDummyFileBytes(fileContent);

      // Save first file
      final result1 = await fileStore.saveFile(
        fileName: baseFileName,
        fileBytes: fileBytes,
        location: SaveLocation.appDocuments,
      );
      expect(result1.success, true);
      print('Saved first duplicate: ${result1.path}');

      // Save second file with same name
      final result2 = await fileStore.saveFile(
        fileName: baseFileName,
        fileBytes: fileBytes,
        location: SaveLocation.appDocuments,
      );
      expect(result2.success, true);
      print('Saved second duplicate: ${result2.path}');

      // Verify the second file has a modified name (e.g., duplicate_test(1).txt)
      expect(result2.path, isNot(equals(result1.path)));
      expect(result2.path, contains('duplicate_test(1).txt'));

      // Clean up
      final file1 = File(result1.path!);
      final file2 = File(result2.path!);
      if (await file1.exists()) await file1.delete();
      if (await file2.exists()) await file2.delete();
    });

    // --- Test for invalid arguments ---
    // --- Test for invalid arguments (null fileName causing TypeError) ---
    testWidgets('Throws TypeError when fileName is null', (
      WidgetTester tester,
    ) async {
      expect(
        () async {
          // Attempting to pass null to a non-nullable required String will throw a TypeError
          await fileStore.saveFile(
            fileName:
                null as String, // This is the line that causes the TypeError.
            // It's a way to explicitly trigger and test that TypeError.
            fileBytes: createDummyFileBytes(''),
            location: SaveLocation.downloads,
          );
        },
        throwsA(isA<TypeError>()), // Expect that a TypeError is thrown
      );
    });

    // --- Test permission denied scenario (Android) ---
    // This is more complex to test reliably in automated tests
    // because you can't easily programmatically deny permissions after requesting.
    // Manual testing is often better for this flow.
    // However, you could simulate it by mocking the permission_handler results if strictly unit testing
    // the Dart permission logic, but for integration, you'd need a specific test environment.
    // For now, rely on manual testing for this.
  });
}
