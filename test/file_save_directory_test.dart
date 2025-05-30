import 'package:file_save_directory/file_save_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SaveLocation enum test', () {
    expect(SaveLocation.downloads.displayName, 'Downloads');
    expect(SaveLocation.documents.displayName, 'Documents');
    expect(SaveLocation.appDocuments.displayName, 'App Documents');
  });
}
