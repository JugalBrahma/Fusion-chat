import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_upload_service.dart';

class PdfUploadButton extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUploadComplete;
  final String? folderId;

  const PdfUploadButton({
    Key? key,
    this.onUploadComplete,
    this.folderId,
  }) : super(key: key);

  @override
  State<PdfUploadButton> createState() => _PdfUploadButtonState();
}

class _PdfUploadButtonState extends State<PdfUploadButton> {
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _uploadPdf() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final uploadService = PdfUploadService();
        
        final response = await uploadService.uploadPdf(file, folderId: widget.folderId);
        
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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadPdf,
          child: _isUploading
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
