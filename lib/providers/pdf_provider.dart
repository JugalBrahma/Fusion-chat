import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_chat/services/pdf_service.dart';

class PdfState {
  final bool isUploading;
  final bool isDeleting;

  const PdfState({
    this.isUploading = false,
    this.isDeleting = false,
  });

  PdfState copyWith({bool? isUploading, bool? isDeleting}) {
    return PdfState(
      isUploading: isUploading ?? this.isUploading,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class PdfNotifier extends StateNotifier<PdfState> {
  PdfNotifier(this._pdfService) : super(const PdfState());

  final PdfService _pdfService;

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPdfs() {
    return _pdfService.getUserPdfs();
  }

  Stream<int> pdfCountStream(String folderId) {
    return _pdfService.pdfCountStream(folderId);
  }

  Future<Map<String, dynamic>> uploadPdf(File file, {String? folderId}) async {
    state = state.copyWith(isUploading: true);
    try {
      return await _pdfService.uploadPdf(file, folderId: folderId);
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  Future<void> deletePdf(String pdfId, {String? folderId}) async {
    state = state.copyWith(isDeleting: true);
    try {
      await _pdfService.deletePdf(pdfId, folderId: folderId);
    } finally {
      state = state.copyWith(isDeleting: false);
    }
  }
}

final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>((ref) {
  return PdfNotifier(PdfService());
});
