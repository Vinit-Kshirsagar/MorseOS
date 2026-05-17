import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transmission_mode.dart';
import '../models/transmitter_state_model.dart';
import '../services/morse_converter.dart';
import '../services/transmission_engine.dart';
import '../services/torch_service.dart';
import '../services/audio_service.dart';
import 'transmitter_event.dart';
import 'transmitter_state.dart';

class TransmitterBloc extends Bloc<TransmitterEvent, TransmitterState> {
  final TorchService _torch = TorchService();
  final AudioService _audio = AudioService();
  late final TransmissionEngine _engine;

  TransmitterBloc() : super(TransmitterState.initial()) {
    _engine = TransmissionEngine(_torch, _audio);

    on<TextChanged>            (_onTextChanged);
    on<ModeChanged>            (_onModeChanged);
    on<SpeedChanged>           (_onSpeedChanged);
    on<TransmitStarted>        (_onTransmitStarted);
    on<TransmitPaused>         (_onTransmitPaused);
    on<TransmitResumed>        (_onTransmitResumed);
    on<TransmitCancelled>      (_onTransmitCancelled);
    on<InternalProgressTicked> (_onProgressTicked);
    on<InternalTransmitDone>   (_onTransmitDone);
  }

  void _onTextChanged(TextChanged event, Emitter<TransmitterState> emit) {
    final upper      = event.text.toUpperCase();
    final hasInvalid = !RegExp(r'^[A-Z0-9 ]*$').hasMatch(upper);
    final words      = MorseConverter.toWords(upper);
    emit(state.copyWith(
      model: state.model.copyWith(
        inputText:      upper,
        hasInvalidChar: hasInvalid,
        status:         TransmissionStatus.idle,
        clearActivePosition: true,
      ),
      morseWords: words,
    ));
  }

  void _onModeChanged(ModeChanged event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(mode: event.mode));

  void _onSpeedChanged(SpeedChanged event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(
        model: state.model.copyWith(speed: event.speed),
      ));

  Future<void> _onTransmitStarted(
      TransmitStarted event, Emitter<TransmitterState> emit) async {
    final text = state.model.inputText.trim();
    if (text.isEmpty) return;

    // toSignals now returns both the list and the position map
    final result = MorseConverter.toSignals(text, state.model.speed);
    if (result.signals.isEmpty) return;

    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.transmitting,
        totalSignals:     result.signals.length,
        completedSignals: 0,
        clearActivePosition: true,
      ),
      positionMap: result.positionMap,
    ));

    _engine.transmit(
      signals: result.signals,
      mode:    state.mode,
      onProgress: (completed) {
        // Look up which letter this signal belongs to
        final map = state.positionMap;
        final pos = (completed - 1 < map.length) ? map[completed - 1] : null;
        add(InternalProgressTicked(completed, pos));
      },
    ).then((_) => add(const InternalTransmitDone()));
  }

  void _onTransmitPaused(
      TransmitPaused event, Emitter<TransmitterState> emit) {
    _engine.pause();
    emit(state.copyWith(
      model: state.model.copyWith(status: TransmissionStatus.paused),
    ));
  }

  void _onTransmitResumed(
      TransmitResumed event, Emitter<TransmitterState> emit) {
    _engine.resume();
    emit(state.copyWith(
      model: state.model.copyWith(status: TransmissionStatus.transmitting),
    ));
  }

  void _onTransmitCancelled(
      TransmitCancelled event, Emitter<TransmitterState> emit) {
    _engine.cancel();
    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.idle,
        completedSignals: 0,
        totalSignals:     0,
        clearActivePosition: true,
      ),
      positionMap: const [],
    ));
  }

  void _onProgressTicked(
      InternalProgressTicked event, Emitter<TransmitterState> emit) {
    emit(state.copyWith(
      model: state.model.copyWith(
        completedSignals: event.completed,
        activePosition:   event.position,
      ),
    ));
  }

  void _onTransmitDone(
      InternalTransmitDone event, Emitter<TransmitterState> emit) {
    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.done,
        completedSignals: state.model.totalSignals,
        clearActivePosition: true,
      ),
      positionMap: const [],
    ));
  }

  @override
  Future<void> close() async {
    _engine.cancel();
    await _audio.dispose();
    return super.close();
  }
}
