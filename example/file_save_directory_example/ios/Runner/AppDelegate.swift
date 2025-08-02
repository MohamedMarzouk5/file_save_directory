import UIKit
import Flutter
import MobileCoreServices

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var pendingFlutterResult: FlutterResult?
  private var tempFileURL: URL?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.filesave/file_save_directory", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler { (call, result) in
      if call.method == "saveFileWithPicker" {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String,
              let fileBytes = args["fileBytes"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
        }

        self.saveFileWithPicker(fileName: fileName, fileData: fileBytes.data, viewController: controller, flutterResult: result)
      } else if call.method == "createFolder" {
        guard let args = call.arguments as? [String: Any],
              let folderName = args["folderName"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing folder name", details: nil))
          return
        }
        
        self.createFolder(folderName: folderName, viewController: controller, flutterResult: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveFileWithPicker(fileName: String, fileData: Data, viewController: UIViewController, flutterResult: @escaping FlutterResult) {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    do {
      try fileData.write(to: tempURL)
      self.tempFileURL = tempURL
      self.pendingFlutterResult = flutterResult
    } catch {
      flutterResult(FlutterError(code: "FILE_WRITE_FAILED", message: "Could not write temp file", details: error.localizedDescription))
      return
    }

    let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
    documentPicker.shouldShowFileExtensions = true
    documentPicker.delegate = self
    viewController.present(documentPicker, animated: true, completion: nil)
  }
  
  private func createFolder(folderName: String, viewController: UIViewController, flutterResult: @escaping FlutterResult) {
    let documentPicker = UIDocumentPickerViewController(forExporting: [])
    documentPicker.shouldShowFileExtensions = false
    documentPicker.allowsMultipleSelection = false
    documentPicker.delegate = self
    documentPicker.directoryURL = nil
    
    // Store the folder creation request
    self.pendingFlutterResult = flutterResult
    
    viewController.present(documentPicker, animated: true, completion: nil)
  }
}

// MARK: - UIDocumentPickerViewControllerDelegate
extension AppDelegate: UIDocumentPickerViewControllerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      pendingFlutterResult?(FlutterError(code: "NO_URL_SELECTED", message: "No URL selected", details: nil))
      cleanup()
      return
    }
    
    // If we have a temp file, move it to the selected location
    if let tempURL = tempFileURL {
      do {
        let destinationURL = url.appendingPathComponent(tempURL.lastPathComponent)
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        pendingFlutterResult?(true)
      } catch {
        pendingFlutterResult?(FlutterError(code: "FILE_MOVE_FAILED", message: "Could not move file to destination", details: error.localizedDescription))
      }
    } else {
      // This was a folder creation request
      pendingFlutterResult?(true)
    }
    
    cleanup()
  }
  
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingFlutterResult?(FlutterError(code: "CANCELLED", message: "User cancelled the operation", details: nil))
    cleanup()
  }
  
  private func cleanup() {
    pendingFlutterResult = nil
    tempFileURL = nil
  }
}
