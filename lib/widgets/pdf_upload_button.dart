import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pdf_provider.dart';

class PdfUploadButton extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onUploadComplete;
  final String? folderId;

  const PdfUploadButton({
    Key? key,
    this.onUploadComplete,
    this.folderId,
  }) : super(key: key);

  @override
  ConsumerState<PdfUploadButton> createState() => _PdfUploadButtonState();
}

class _PdfUploadButtonState extends ConsumerState<PdfUploadButton> {
  String? _errorMessage;

  Future<void> _uploadPdf() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single.path;
        if (file == null) {
          throw Exception('Invalid file path');
        }
        
        final response = await ref
            .read(pdfProvider.notifier)
            .uploadPdf(File(file), folderId: widget.folderId);
        
        if (widget.onUploadComplete != null) {
          widget.onUploadComplete!(response);
        }

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(response['error'] ?? 'Upload failed');
        }
      }
    } catch (e, stack) {
      debugPrint('PDF upload failed: $e\n$stack');
      setState(() {
        _errorMessage = 'Upload failed. Please try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: ref.watch(pdfProvider).isUploading ? null : _uploadPdf,
          child: ref.watch(pdfProvider).isUploading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...'),
                  ],
                )
              : Text('Upload PDF'),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
