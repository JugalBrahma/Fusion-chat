import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:backendtest/services/pdf_upload_service_new.dart';
import 'package:backendtest/providers/folder_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      await ref.read(folderProvider.notifier).loadFolders();
    } catch (e) {
      print('Error loading folders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Documents',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
),
),
        backgroundColor: Color(0xFF1E293B),
        elevation: 2,
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📁 Folder Selection Section
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
),
                ],
),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Folder',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
),
),
                  const SizedBox(height: 12),
                  // Folder Dropdown
                  Consumer(
                    builder: (context, ref, child) {
                      final folderAsync = ref.watch(folderProvider);
                      
                      return folderAsync.when(
                        data: (folders) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFE0E0E6)),
                            borderRadius: BorderRadius.circular(8),
),
                          child: DropdownButton<String>(
                            hint: Text(
                              'Choose a folder...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Color(0xFF64748B),
),
),
                            value: _selectedFolderId,
                            items: folders.map<DropdownMenuItem<String>>(
                              (folder) => DropdownMenuItem(
                                value: folder['id'],
                                child: Text(folder['name'] ?? 'Unnamed'),
),
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFolderId = value;
                              });
                            },
),
),
                        loading: () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFE0E0E6)),
                            borderRadius: BorderRadius.circular(8),
),
                          child: Center(child: CircularProgressIndicator()),
),
                        error: (error, stack) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFE0E0E6)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Error loading folders'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📤 PDF Upload Section
            Expanded(
              child: _buildPdfUploadSection(),
),
          ],
),
),
    );
  }

  Widget _buildPdfUploadSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
),
        ],
),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload PDF Document',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
),
),
          const SizedBox(height: 16),
          
          // 📄 Page Limit Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFFF9800)),
),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📄 Page Limit: 50 pages maximum',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
),
),
                      const SizedBox(height: 4),
                      Text(
                        'Large PDFs will be rejected to ensure system performance.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Color(0xFF64748B),
),
),
                    ],
),
),

              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 📤 Upload Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE0E0E6), width: 2),
),
              child: Column(
                children: [
                  // Drag and Drop Area
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE0E0E6), style: BorderStyle.solid, width: 1),
),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, 
                            size: 48, 
                            color: Color(0xFF1E293B)),
                          const SizedBox(height: 8),
                          Text(
                            'Drag & Drop PDF here',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
),
),
                        ],
),
),
),
                  const SizedBox(height: 16),
                  
                  // File Input (Hidden)
                  Consumer(
                    builder: (context, ref, child) {
                      final uploadService = ref.read(pdfUploadProvider.notifier);
                      final uploadState = ref.watch(pdfUploadProvider);
                      return _buildFileInput(uploadService, uploadState);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInput(PdfUploadService uploadService, PdfUploadState uploadState) {
    if (uploadState.selectedFile != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '✅ ${uploadState.selectedFile!.name}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
),
),
),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => uploadService.clearSelectedFile(),
              icon: const Icon(Icons.clear, color: Colors.green),
              tooltip: 'Clear file',
),
          ],
),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E6)),
),
      child: InkWell(
        onTap: () => uploadService.pickFile(),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E6), style: BorderStyle.solid, width: 2),
),
          child:  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, 
                  size: 48, 
                  color: Color(0xFF1E293B)),
                const SizedBox(height: 8),
                Text(
                  'Click to select PDF',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
),
),
              ],
),
),
),
),
    );
  }
}
