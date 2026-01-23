import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class PdfUploadService extends StateNotifier<PdfUploadState> {
  PdfUploadService() : super(const PdfUploadState(uploadProgress: 0.0));

  final FilePicker _filePicker = FilePicker.platform;

  PlatformFile? get selectedFile => state.selectedFile;
  String? get selectedFileName => state.selectedFileName;
  double? get uploadProgress => state.uploadProgress;

  void pickFile() async {
    try {
      final result = await _filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Select PDF File',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        
        state = PdfUploadState(
          selectedFile: file,
          selectedFileName: fileName,
          uploadProgress: 0.0,
        );
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void clearSelectedFile() {
    state = const PdfUploadState(
      selectedFile: null,
      selectedFileName: null,
      uploadProgress: 0.0,
    );
  }

  void updateUploadProgress(double progress) {
    if (progress >= 0.0 && progress <= 1.0) {
      state = PdfUploadState(
        selectedFile: state.selectedFile,
        selectedFileName: state.selectedFileName,
        uploadProgress: progress,
      );
    }
  }
}

class PdfUploadState {
  final PlatformFile? selectedFile;
  final String? selectedFileName;
  final double uploadProgress;

  const PdfUploadState({
    this.selectedFile,
    this.selectedFileName,
    required this.uploadProgress,
  });

  @override
  bool operator ==(Object other) {
    if (other is PdfUploadState &&
        identical(this.selectedFile, other.selectedFile) &&
        identical(this.selectedFileName, other.selectedFileName) &&
        this.uploadProgress == other.uploadProgress) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hash(selectedFile.hashCode, selectedFileName.hashCode, uploadProgress.hashCode);
  }
}

final pdfUploadProvider = StateNotifierProvider<PdfUploadService, PdfUploadState>((ref) {
  return PdfUploadService();
});
