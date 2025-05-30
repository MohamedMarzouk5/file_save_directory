# file_save_directory

A Flutter plugin that allows you to **save files** to the **Downloads**, **Documents**, or **App Documents** directories on **Android** and **iOS**. It also supports **automatically opening the file after saving**, handles permissions, and resolves file name conflicts.

---

## ✨ Features

- ✅ Save files to:
  - 📂 Public **Downloads** folder
  - 📄 Public **Documents** folder
  - 📁 App's **private documents** directory
- 🛡️ Automatically handles permissions and file name conflicts
- 📱 Supports **Android 6.0+** and **iOS 11+**
- 📦 Simple API — just provide a file name and bytes
- 🔓 Optionally opens the file after saving

---

## Platform Support

- ✅ Android 6.0+ (API level 23)
- ✅ iOS 11+

---

## 🚀 Getting Started

### ⚙️ Platform Setup

#### ✅ Android Setup

1. **Add permissions** in `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, but outside `<application>`):

````xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
    tools:ignore="ScopedStorage" />


2. **Enable Legacy Storage** (For Android 10)
   Inside the `<application>` tag in `AndroidManifest.xml`, add:

```xml
<application
...
android:requestLegacyExternalStorage="true"
...
>
</application>
````

#### 🍎 iOS Setup

No setup needed. iOS saves to the app's private Documents directory. No permissions required.

## 💡 Usage

1. Import the plugin:

   import 'package:file_save_directory/file_save_directory.dart';

2. Save a file:

   final result = await FileSaveDirectory.instance.saveFile(

   fileName: 'example.txt',

   fileBytes: utf8.encode('Hello, Flutter!'),

   location: SaveLocation.downloads, // or SaveLocation.documents, SaveLocation.appDocuments

   openAfterSave: true, // Default to true
   );

### 📍 Save Location Options

🗂️ SaveLocation.downloads → 📂 Public Downloads (Android), 📄 Documents (iOS)

📄 SaveLocation.documents → 📁 Public Documents (Android), 📄 Documents (iOS)

📁 SaveLocation.appDocuments → 📦 App's private documents folder (Android & iOS)

## 🛠 Troubleshooting

✅ Android 11+ requires MANAGE_EXTERNAL_STORAGE for full shared storage access.

📁 If saving fails, ensure your app has storage permissions.

📱 Test on a real device to validate file system behavior.

⚙️ Call FileSaveDirectory.instance.openAppSettings() if you need to prompt users to manually grant storage access.

## 🤝 Contributing

Feel free to open issues or submit pull requests. All contributions are welcome!

```

```
