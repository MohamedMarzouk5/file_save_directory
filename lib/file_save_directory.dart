library file_save_directory;

/// A Flutter plugin for saving files to different directories with enum-based location selection
///
/// Supports saving files to:
/// - Downloads folder (public, visible to users)
/// - Documents folder (public, visible to users)
/// - App Documents folder (private to your app)
///
/// Handles permissions automatically based on Android version and chosen location.

export 'src/file_saver.dart';
export 'src/save_location.dart';
