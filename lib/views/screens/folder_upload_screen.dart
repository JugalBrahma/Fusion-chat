import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/pdf_viewmodel.dart';
import '../widgets/pdf_upload_button.dart';

class FolderUploadScreen extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;

  const FolderUploadScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  ConsumerState<FolderUploadScreen> createState() => _FolderUploadScreenState();
}

class _FolderUploadScreenState extends ConsumerState<FolderUploadScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _deletingPdfs = <String>{};
  
  void _handleUploadComplete(Map<String, dynamic> response) {
    if (response['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deletePdf(String pdfId, String fileName) async {
    setState(() {
      _deletingPdfs.add(pdfId);
    });

    try {
      await ref.read(pdfProvider.notifier).deletePdf(pdfId, folderId: widget.folderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, size: 20),
                SizedBox(width: 8),
                Text('$fileName deleted successfully'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, size: 20),
                SizedBox(width: 8),
                Text('Failed to delete $fileName'),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingPdfs.remove(pdfId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Upload PDF files',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add documents to your folder',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: 24),
                StreamBuilder<int>(
                  stream: ref.watch(pdfProvider.notifier).pdfCountStream(widget.folderId),
                  builder: (context, snapshot) {
                    final pdfCount = snapshot.data ?? 0;
                    final isLimitReached = pdfCount >= 3;

                    return isLimitReached
                        ? Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_outlined, color: const Color(0xFFF59E0B)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PDF limit reached',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                      Text(
                                        'Maximum 3 PDFs per folder',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : PdfUploadButton(
                            folderId: widget.folderId,
                            onUploadComplete: _handleUploadComplete,
                          );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Uploaded Files',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.headlineMedium?.color,
                          ),
                        ),
                        StreamBuilder<int>(
                          stream: ref.watch(pdfProvider.notifier).pdfCountStream(widget.folderId),
                          builder: (context, snapshot) {
                            final pdfCount = snapshot.data ?? 0;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: pdfCount >= 3 
                                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                    : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$pdfCount/3 PDFs',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: pdfCount >= 3
                                      ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                                      : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser?.uid)
                          .collection('folders')
                          .doc(widget.folderId)
                          .collection('pdfs')
                          .orderBy('uploaded_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load PDFs',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final pdfs = snapshot.data?.docs ?? [];

                        if (pdfs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 48,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No PDFs uploaded yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Upload your first PDF to get started',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: pdfs.length,
                          itemBuilder: (context, index) {
                            final data = pdfs[index].data();
                            final pdfId = pdfs[index].id;

                            final fileName = (data['file_name'] as String?) ?? 'Unnamed PDF';
                            final textLength = data['text_length'];

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                              ),
                              child: Dismissible(
                                key: Key(pdfId),
                                direction: _deletingPdfs.contains(pdfId) ? DismissDirection.none : DismissDirection.endToStart,
                                background: Container(
                                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444)),
                                      SizedBox(height: 4),
                                      Text(
                                        'Delete',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onDismissed: _deletingPdfs.contains(pdfId) ? null : (direction) {
                                  _deletePdf(pdfId, fileName);
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _deletingPdfs.contains(pdfId)
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                            ),
                                          )
                                        : Icon(
                                            Icons.picture_as_pdf,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                  ),
                                  title: Text(
                                    fileName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _deletingPdfs.contains(pdfId) 
                                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                                          : theme.textTheme.headlineMedium?.color,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _deletingPdfs.contains(pdfId) ? 'Deleting...' : 'Length: ${textLength ?? '-'} chars',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
