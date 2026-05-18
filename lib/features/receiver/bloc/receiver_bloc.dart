import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/morse_constants.dart';
import '../models/receiver_state_model.dart';
import '../services/camera_service.dart';
import '../services/morse_decoder.dart';
import 'receiver_event.dart';
import 'receiver_state.dart';

class ReceiverBloc extends Bloc<ReceiverEvent, ReceiverState> {
  final CameraService _camera  = CameraService();
  final MorseDecoder  _decoder = MorseDecoder();

  ReceiverBloc() : super(ReceiverState.initial()) {
    on<ScanStarted>                   (_onScanStarted);
    on<ScanStopped>                   (_onScanStopped);
    on<DecodingReset>                 (_onDecodingReset);
    on<InternalFrameAnalysed>         (_onFrameAnalysed);
    on<InternalSymbolAppended>        (_onSymbolAppended);
    on<InternalLetterCommitted>       (_onLetterCommitted);
    on<InternalWordCommitted>         (_onWordCommitted);
    on<InternalWordCommittedWithLetter>(_onWordCommittedWithLetter);
    on<InternalCameraError>           (_onCameraError);
  }

  // ── User events ─────────────────────────────────────────────────────────────

  Future<void> _onScanStarted(
    ScanStarted event,
    Emitter<ReceiverState> emit,
  ) async {
    emit(state.copyWith(
      model: state.model.copyWith(
        status:        ReceiverStatus.scanning,
        statusMessage: 'OPENING CAMERA',
      ),
    ));

    _decoder.reset();

    final success = await _camera.startScanning(
      onFrame: ({required bool isOn, required double brightness}) {
        add(InternalFrameAnalysed(isOn: isOn, brightness: brightness));
      },
      onTransition: ({required bool wasOn, required int durationMs}) {
        // The decoder is the single source of truth for timing logic.
        // The callback reads its output and dispatches the matching event.
        final output = _decoder.processTransition(
          wasOn:      wasOn,
          durationMs: durationMs,
        );
        switch (output) {
          case SymbolAppended(:final fragment):
            add(InternalSymbolAppended(fragment));
          case LetterCommitted(:final letter):
            add(InternalLetterCommitted(letter));
          case WordCommitted():
            add(const InternalWordCommitted());
          case WordCommittedWithLetter(:final letter):
            // Single dispatch — BLoC handler adds letter then flushes word.
            add(InternalWordCommittedWithLetter(letter));
          case DecoderIdle():
            break;
        }
      },
    );

    if (!success) {
      add(const InternalCameraError(
          'Camera unavailable. Grant camera permission and try again.'));
      return;
    }

    emit(state.copyWith(
      cameraController: _camera.controller,
      model: state.model.copyWith(
        status:        ReceiverStatus.scanning,
        statusMessage: 'RX · SCANNING',
      ),
    ));
  }

  Future<void> _onScanStopped(
    ScanStopped event,
    Emitter<ReceiverState> emit,
  ) async {
    // Flush any in-progress letter before stopping.
    final flush = _decoder.flush();
    if (flush case LetterCommitted(:final letter)) {
      emit(state.copyWith(
        model: state.model.copyWith(
          currentWord: state.model.currentWord + letter,
        ),
      ));
    }

    await _camera.stopScanning();

    emit(state.copyWith(
      clearCamera: true,
      model: state.model.copyWith(
        status:               ReceiverStatus.stopped,
        statusMessage:        'STOPPED',
        currentMorseFragment: '',
        signalIsOn:           false,
        signalLevel:          0.0,
      ),
    ));
  }

  void _onDecodingReset(
    DecodingReset event,
    Emitter<ReceiverState> emit,
  ) {
    _decoder.reset();
    emit(ReceiverState.initial());
  }

  // ── Internal events ──────────────────────────────────────────────────────────

  void _onFrameAnalysed(
    InternalFrameAnalysed event,
    Emitter<ReceiverState> emit,
  ) {
    emit(state.copyWith(
      model: state.model.copyWith(
        signalLevel: event.brightness,
        signalIsOn:  event.isOn,
      ),
    ));
  }

  void _onSymbolAppended(
    InternalSymbolAppended event,
    Emitter<ReceiverState> emit,
  ) {
    emit(state.copyWith(
      model: state.model.copyWith(
        currentMorseFragment: event.fragment,
      ),
    ));
  }

  void _onLetterCommitted(
    InternalLetterCommitted event,
    Emitter<ReceiverState> emit,
  ) {
    emit(state.copyWith(
      model: state.model.copyWith(
        currentWord:          state.model.currentWord + event.letter,
        currentMorseFragment: '',
        statusMessage:        'LETTER: ${event.letter}',
      ),
    ));
  }

  void _onWordCommitted(
    InternalWordCommitted event,
    Emitter<ReceiverState> emit,
  ) {
    final word = state.model.currentWord;
    if (word.isEmpty) return;

    emit(state.copyWith(
      model: state.model.copyWith(
        committedWords:       List<String>.from(state.model.committedWords)
            ..add(word),
        currentWord:          '',
        currentMorseFragment: '',
        statusMessage:        'WORD: $word',
      ),
    ));
  }

  void _onWordCommittedWithLetter(
    InternalWordCommittedWithLetter event,
    Emitter<ReceiverState> emit,
  ) {
    // First apply the implicit letter commit to the current word.
    final wordWithLetter = state.model.currentWord + event.letter;

    // Then flush that completed word to committedWords.
    emit(state.copyWith(
      model: state.model.copyWith(
        committedWords:       List<String>.from(state.model.committedWords)
            ..add(wordWithLetter),
        currentWord:          '',
        currentMorseFragment: '',
        statusMessage:        'WORD: $wordWithLetter',
      ),
    ));
  }

  void _onCameraError(
    InternalCameraError event,
    Emitter<ReceiverState> emit,
  ) {
    emit(state.copyWith(
      clearCamera: true,
      model: state.model.copyWith(
        status:        ReceiverStatus.idle,
        statusMessage: event.message,
      ),
    ));
  }

  @override
  Future<void> close() async {
    await _camera.dispose();
    return super.close();
  }
}
