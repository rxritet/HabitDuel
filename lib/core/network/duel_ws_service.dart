import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';

/// Event received from the duel WebSocket.
class DuelWsEvent {
  const DuelWsEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}

/// Manages a single WebSocket connection to `/ws/duels/:id`.
/// Handles JWT authentication, automatic reconnection with
/// exponential backoff (1s → 2s → 4s … → 30s cap).
class DuelWsService {
  DuelWsService(this._storage);

  final FlutterSecureStorage _storage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  String? _currentDuelId;
  bool _disposed = false;
  int _retryCount = 0;

  static const _maxBackoff = Duration(seconds: 30);
  static const _baseBackoff = Duration(seconds: 1);

  final _controller = StreamController<DuelWsEvent>.broadcast();

  /// Stream of decoded events from the WebSocket.
  Stream<DuelWsEvent> get events => _controller.stream;

  /// Connect to a duel room.
  Future<void> connect(String duelId) async {
    // Disconnect previous if any
    await disconnect();
    _disposed = false;
    _currentDuelId = duelId;
    _retryCount = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed || _currentDuelId == null) return;

    final token = await _storage.read(key: kTokenKey);
    if (token == null) return;

    // Build ws:// URL from kBaseUrl
    final httpUri = Uri.parse(kBaseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: wsScheme,
      host: httpUri.host,
      port: httpUri.port,
      path: '/ws/duels/$_currentDuelId',
      queryParameters: {'token': token},
    );

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
      _retryCount = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = data['event'] as String? ?? 'unknown';
      _controller.add(DuelWsEvent(event, data));
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onError(Object error) {
    _scheduleReconnect();
  }

  void _onDone() {
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    final delay = Duration(
      milliseconds: min(
        _maxBackoff.inMilliseconds,
        _baseBackoff.inMilliseconds * pow(2, _retryCount).toInt(),
      ),
    );
    _retryCount++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  /// Disconnect from the current room. Safe to call multiple times.
  Future<void> disconnect() async {
    _disposed = true;
    _currentDuelId = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Permanently dispose this service.
  void dispose() {
    disconnect();
    _controller.close();
  }
}

/// Riverpod provider — one instance per app lifetime.
final duelWsServiceProvider = Provider<DuelWsService>((ref) {
  final storage = ref.watch(
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage()),
  );
  final svc = DuelWsService(storage);
  ref.onDispose(svc.dispose);
  return svc;
});
