/// Enum to specify where to save the file
enum SaveLocation {
  /// Save to Downloads folder (Android) or Documents folder (iOS)
  downloads,

  /// Save to Documents folder
  documents,

  /// Save to Music folder
  music,

  /// Save to Videos folder
  videos,

  /// Save to app's private documents directory
  appDocuments,
}

extension SaveLocationExtension on SaveLocation {
  String get displayName {
    switch (this) {
      case SaveLocation.downloads:
        return 'Downloads';
      case SaveLocation.documents:
        return 'Documents';
      case SaveLocation.music:
        return 'Music';
      case SaveLocation.videos:
        return 'Videos';
      case SaveLocation.appDocuments:
        return 'App Documents';
    }
  }

  String get description {
    switch (this) {
      case SaveLocation.downloads:
        return 'Saves to the public Downloads folder';
      case SaveLocation.documents:
        return 'Saves to the public Documents folder';
      case SaveLocation.music:
        return 'Saves to the public Music folder';
      case SaveLocation.videos:
        return 'Saves to the public Videos folder';
      case SaveLocation.appDocuments:
        return 'Saves to the app\'s private documents directory';
    }
  }
}
