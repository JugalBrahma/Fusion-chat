import 'package:flutter_riverpod/flutter_riverpod.dart';

class McqSelectionNotifier extends StateNotifier<Map<String, String?>> {
  McqSelectionNotifier() : super({});

  static String _key(String messageId, int mcqIndex) => '$messageId/$mcqIndex';

  void selectOption(String messageId, int mcqIndex, String optionLetter) {
    final key = _key(messageId, mcqIndex);
    state = {
      ...state,
      key: optionLetter,
    };
  }

  String? getSelection(String messageId, int mcqIndex) {
    return state[_key(messageId, mcqIndex)];
  }

  void clearSelectionsForMessage(String messageId) {
    final updated = Map<String, String?>.from(state)
      ..removeWhere((key, _) => key.startsWith('$messageId/'));
    state = updated;
  }
}

final mcqSelectionProvider =
    StateNotifierProvider<McqSelectionNotifier, Map<String, String?>>(
  (ref) => McqSelectionNotifier(),
);
