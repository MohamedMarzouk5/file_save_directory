## 1.0.3

- [Documentation] Updated README.md to include proper Android manifest namespace declaration
- [Documentation] Enhanced Android setup instructions with required xmlns:tools namespace

## 1.0.2

- [Android/iOS] Added support for saving files to Videos directory
- [Android/iOS] Added support for saving files to Music directory
- [Android] Implemented proper MediaStore integration for video files with specific MIME types (mp4, avi, mkv, mov, wmv, flv, webm, m4v, 3gp, mpeg)
- [Android] Implemented proper MediaStore integration for audio files with specific MIME types (mp3, wav, m4a, flac, ogg, aac, wma, opus)
- [Android] Enhanced file type detection and automatic MIME type assignment for video and audio files
- [iOS] Added app-specific Videos and Music directories with proper fallback handling
- [All] Added `SaveLocation.videos` and `SaveLocation.music` enum options
- [All] Added helper methods `isAudioFile()` and `isVideoFile()` for file type detection
- [All] Enhanced file saving logic to handle different content URIs based on file type

## 1.0.1 # or appropriate version

- [iOS] Your changes description here
- [iOS] Another change if applicable

## 1.0.0

- Initial release.
