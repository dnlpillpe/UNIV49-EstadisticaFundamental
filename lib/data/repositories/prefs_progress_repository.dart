import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';

/// Persistencia del progreso en `SharedPreferences`.
///
/// Se guarda el estado completo como un único JSON. Con un historial de
/// centenares de intentos el documento ronda las decenas de kB, muy por debajo
/// de lo que hace lento este almacenamiento, y a cambio se elimina la clase de
/// error más molesta: un progreso a medio escribir tras cerrar la app.
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository();

  static const String _key = 'learner_state_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<LearnerState> load() async {
    final SharedPreferences prefs = await _instance;
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return LearnerState.empty().copyWith(
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }
    try {
      return LearnerState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Estado corrupto o de una versión anterior incompatible: se descarta.
      // Perder el progreso es malo; dejar la app sin arrancar es peor.
      await prefs.remove(_key);
      return LearnerState.empty().copyWith(
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  @override
  Future<void> save(LearnerState state) async {
    final SharedPreferences prefs = await _instance;
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await _instance;
    await prefs.remove(_key);
  }
}
