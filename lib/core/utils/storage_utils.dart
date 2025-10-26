import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

/// 💾 Storage Utilities
/// 
/// Helper functions for file system operations and storage management
class StorageUtils {
  StorageUtils._();

  // ═══════════════════════════════════════════════════════════════
  // DIRECTORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════
  
  /// Get the app's documents directory
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get the models directory (creates if doesn't exist)
  static Future<Directory> getModelsDirectory() async {
    final appDir = await getAppDirectory();
    final modelsDir = Directory(path.join(appDir.path, AppConstants.modelsDirectory));
    
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    return modelsDir;
  }
  
  /// Get the audio directory (creates if doesn't exist)
  static Future<Directory> getAudioDirectory() async {
    final appDir = await getAppDirectory();
    final audioDir = Directory(path.join(appDir.path, AppConstants.audioDirectory));
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    return audioDir;
  }
  
  /// Get directory for a specific language pack
  static Future<Directory> getPackDirectory(String packId) async {
    final modelsDir = await getModelsDirectory();
    final packDir = Directory(path.join(modelsDir.path, packId));
    
    if (!await packDir.exists()) {
      await packDir.create(recursive: true);
    }
    
    return packDir;
  }
  
  /// Get temporary directory for downloads
  static Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }
  
  // ═══════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════
  
  /// Check if a file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }
  
  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }
  
  /// Delete a file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Copy file from source to destination
  static Future<bool> copyFile(String sourcePath, String destPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Move file from source to destination
  static Future<bool> moveFile(String sourcePath, String destPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.rename(destPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // DIRECTORY SIZE CALCULATION
  // ═══════════════════════════════════════════════════════════════
  
  /// Calculate total size of a directory (recursive)
  static Future<int> getDirectorySize(Directory directory) async {
    int totalSize = 0;
    
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      // Ignore errors and return accumulated size
    }
    
    return totalSize;
  }
  
  /// Get size of all language packs
  static Future<int> getTotalPacksSize() async {
    final modelsDir = await getModelsDirectory();
    return await getDirectorySize(modelsDir);
  }
  
  /// Get size of audio files
  static Future<int> getAudioFilesSize() async {
    final audioDir = await getAudioDirectory();
    return await getDirectorySize(audioDir);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // STORAGE SPACE CHECKING
  // ═══════════════════════════════════════════════════════════════
  
  /// Check available storage space (platform-specific)
  /// Note: This is a simplified version. For production, use a plugin like:
  /// - disk_space (for Android/iOS)
  /// - path_provider + StatFS (for Android)
  static Future<int> getAvailableStorage() async {
    // This is a placeholder - implement with appropriate plugin
    // For now, return a large number to allow downloads
    return 10 * 1024 * 1024 * 1024; // 10 GB
  }
  
  /// Check if there's enough space for a download
  static Future<bool> hasEnoughSpace(int requiredBytes) async {
    final available = await getAvailableStorage();
    // Add 100MB buffer for safety
    final buffer = 100 * 1024 * 1024;
    return available >= (requiredBytes + buffer);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // CLEANUP OPERATIONS
  // ═══════════════════════════════════════════════════════════════
  
  /// Delete old audio files (older than retention days)
  static Future<int> cleanOldAudioFiles() async {
    int deletedCount = 0;
    
    try {
      final audioDir = await getAudioDirectory();
      final now = DateTime.now();
      final retentionDays = AppConstants.audioRetentionDays;
      
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > retentionDays) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    
    return deletedCount;
  }
  
  /// Delete all audio files
  static Future<int> clearAllAudioFiles() async {
    int deletedCount = 0;
    
    try {
      final audioDir = await getAudioDirectory();
      
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }
    } catch (e) {
      // Ignore errors
    }
    
    return deletedCount;
  }
  
  /// Delete a language pack completely
  static Future<bool> deleteLanguagePack(String packId) async {
    try {
      final packDir = await getPackDirectory(packId);
      if (await packDir.exists()) {
        await packDir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all temporary files
  static Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTempDirectory();
      await for (final entity in tempDir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (e) {
          // Ignore individual file errors
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PACK VERIFICATION
  // ═══════════════════════════════════════════════════════════════
  
  /// Check if a language pack is installed
  static Future<bool> isPackInstalled(String packId) async {
    try {
      final packDir = await getPackDirectory(packId);
      if (!await packDir.exists()) return false;
      
      // Check if directory has any files
      final files = await packDir.list().toList();
      return files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get list of installed pack IDs
  static Future<List<String>> getInstalledPacks() async {
    final List<String> packs = [];
    
    try {
      final modelsDir = await getModelsDirectory();
      
      await for (final entity in modelsDir.list()) {
        if (entity is Directory) {
          final packId = path.basename(entity.path);
          if (await isPackInstalled(packId)) {
            packs.add(packId);
          }
        }
      }
    } catch (e) {
      // Return empty list on error
    }
    
    return packs;
  }
  
  /// Verify pack integrity (basic check)
  static Future<bool> verifyPackIntegrity(String packId) async {
    try {
      final packDir = await getPackDirectory(packId);
      if (!await packDir.exists()) return false;
      
      // Check for required subdirectories
      final sttDir = Directory(path.join(packDir.path, 'stt'));
      final translationDir = Directory(path.join(packDir.path, 'translation'));
      final ttsDir = Directory(path.join(packDir.path, 'tts'));
      
      return await sttDir.exists() && 
             await translationDir.exists() && 
             await ttsDir.exists();
    } catch (e) {
      return false;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATH HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Get path for downloaded pack zip file
  static Future<String> getDownloadPath(String fileName) async {
    final tempDir = await getTempDirectory();
    return path.join(tempDir.path, fileName);
  }
  
  /// Get path for extracted pack
  static Future<String> getPackPath(String packId) async {
    final packDir = await getPackDirectory(packId);
    return packDir.path;
  }
  
  /// Get path for audio file
  static Future<String> getAudioFilePath(String fileName) async {
    final audioDir = await getAudioDirectory();
    return path.join(audioDir.path, fileName);
  }
}
