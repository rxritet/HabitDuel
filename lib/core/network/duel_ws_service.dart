import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';

/// Событие WebSocket дуэла.
class DuelWsEvent {
  const DuelWsEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}

/// Управляет WS-соединением к `/ws/duels/:id`.
/// JWT-аутентификация, автоподключения с экспоненциальным бэкофом (1с → 2с → 4с … макс. 30с).
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

  /// Поток декодированных событий.
  Stream<DuelWsEvent> get events => _controller.stream;

  /// Подключиться к комнате дуэля.
  Future<void> connect(String duelId) async {
    // Отключиться, если уже подключены
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

    // Строим ws:// URL из kBaseUrl
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
      // Игнорируем бракованные сообщения
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

  /// Отключиться. Безопасно вызывать несколько раз.
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

  /// Окончательно уничтожить сервис.
  void dispose() {
    disconnect();
    _controller.close();
  }
}

/// Riverpod-провайдер — один экземпляр на всё время жизни приложения.
final duelWsServiceProvider = Provider<DuelWsService>((ref) {
  final storage = ref.watch(
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage()),
  );
  final svc = DuelWsService(storage);
  ref.onDispose(svc.dispose);
  return svc;
});
