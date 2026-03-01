import 'package:flutter/material.dart';

/// Токены анимации дизайн-системы Premium Glass.
///
/// Длительности и кривые DESIGN.md §4.1.
/// Используйте эти константы везде для единообразия движения.
abstract final class AppAnimations {
  // ══════════════════════════════════════════════════════════════════
  //  ДЛИТЕЛЬНОСТИ  (DESIGN.md §4.1)
  // ══════════════════════════════════════════════════════════════════

  /// Переход между страницами: слайд + фейд. 400 ms
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  /// Обратная связь нажатия кнопки. 150 ms
  static const Duration buttonPressDuration = Duration(milliseconds: 150);

  /// Обратная связь нажатия карточки. 200 ms
  static const Duration cardPressDuration = Duration(milliseconds: 200);

  /// Открытие модального окна. 300 ms
  static const Duration modalOpenDuration = Duration(milliseconds: 300);

  /// Закрытие модального окна. 200 ms
  static const Duration modalCloseDuration = Duration(milliseconds: 200);

  /// Заполнение индикатора прогресса. 800 ms
  static const Duration progressBarFillDuration = Duration(milliseconds: 800);

  /// Цикл пульсации значка серии. 2 000 ms (бесконечный цикл)
  static const Duration streakBadgePulseDuration = Duration(milliseconds: 2000);

  /// Полная последовательность после check-in. 600 ms
  static const Duration checkinSuccessDuration = Duration(milliseconds: 600);

  /// Счётчик очков. 400 ms
  static const Duration numberCounterDuration = Duration(milliseconds: 400);

  /// WebSocket - слайд уведомления. 250 ms
  static const Duration wsNotificationDuration = Duration(milliseconds: 250);

  /// Фейд автоскрытия уведомления. 200 ms
  static const Duration wsNotificationDismissDuration =
      Duration(milliseconds: 200);

  /// Вспышка конфетти. 1 500 ms
  static const Duration confettiDuration = Duration(milliseconds: 1500);

  // ══════════════════════════════════════════════════════════════════
  //  КРИВЫЕ  (DESIGN.md §4.1)
  // ══════════════════════════════════════════════════════════════════

  /// Переход страницы — плавное замедление.
  static const Curve pageTransitionCurve = Curves.easeOutCubic;

  /// Нажатие кнопки — быстрый ease-out.
  static const Curve buttonPressCurve = Curves.easeOut;

  /// Нажатие карточки — мягкий ease-out.
  static const Curve cardPressCurve = Curves.easeOut;

  /// Открытие модального окна — пружинное замедление.
  static const Curve modalOpenCurve = Curves.fastOutSlowIn;

  /// Закрытие модального окна — ease-in.
  static const Curve modalCloseCurve = Curves.easeIn;

  /// Заполнение индикатора — сильное замедление.
  static const Curve progressBarFillCurve = Curves.easeOutQuart;

  /// Пульс значка — плавное дыхание.
  static const Curve streakBadgePulseCurve = Curves.easeInOut;

  /// Check-in — пружинный ease-out.
  static const Curve checkinSuccessCurve = Curves.elasticOut;

  /// Счётчик — ease-out expo.
  static const Curve numberCounterCurve = Curves.easeOutExpo;

  /// WebSocket — слайд уведомления. = Curves.fastOutSlowIn;

  // ══════════════════════════════════════════════════════════════════
  //  ФИЗИКА ПРУЖИН  (для Hero / check-in)
  // ══════════════════════════════════════════════════════════════════

  /// Пружина по умолчанию для модалов / check-in.
  /// damping = 0.8, stiffness = 100.
  static SpringDescription get defaultSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 14.0, // ≈ критичецкое затухание 0.8
  );

  // ══════════════════════════════════════════════════════════════════
  //  ПРОФИЛИ КЛЮЧЕВЫХ КАДРОВ  (DESIGN.md §4.2)
  // ══════════════════════════════════════════════════════════════════

  // \u2500\u2500 \u041d\u0430\u0436\u0430\u0442\u0438\u0435 \u043a\u043d\u043e\u043f\u043a\u0438
  /// \u041c\u0430\u0441\u0448\u0442\u0430\u0431 \u043f\u0440\u0438 \u043d\u0430\u0436\u0430\u0442\u0438\u0438 \u043a\u043d\u043e\u043f\u043a\u0438.
  static const double buttonPressScaleDown = 0.96;

  /// \u041f\u0440\u043e\u0437\u0440\u0430\u0447\u043d\u043e\u0441\u0442\u044c \u043f\u0440\u0438 \u043d\u0430\u0436\u0430\u0442\u0438\u0438 \u043a\u043d\u043e\u043f\u043a\u0438.
  static const double buttonPressOpacityDown = 0.85;

  // \u2500\u2500 \u041d\u0430\u0436\u0430\u0442\u0438\u0435 \u043a\u0430\u0440\u0442\u043e\u0447\u043a\u0438
  /// \u041c\u0430\u0441\u0448\u0442\u0430\u0431 \u043f\u0440\u0438 \u043d\u0430\u0436\u0430\u0442\u0438\u0438 \u043a\u0430\u0440\u0442\u043e\u0447\u043a\u0438.
  static const double cardPressScaleDown = 0.98;

  // \u2500\u2500 \u041f\u0435\u0440\u0435\u0445\u043e\u0434 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b
  /// \u0421\u043c\u0435\u0449\u0435\u043d\u0438\u0435 \u0432\u044c\u0435\u0437\u0436\u0430\u044e\u0449\u0435\u0433\u043e \u044d\u043a\u0440\u0430\u043d\u0430 \u043f\u043e X.
  static const double pageEnterOffsetX = 1.0; // 100%

  /// \u0421\u043c\u0435\u0449\u0435\u043d\u0438\u0435 \u0443\u0445\u043e\u0434\u044f\u0449\u0435\u0433\u043e \u044d\u043a\u0440\u0430\u043d\u0430 \u043f\u043e X.
  static const double pageExitOffsetX = -0.3; // -30%

  // \u2500\u2500 \u0423\u0441\u043f\u0435\u0448\u043d\u044b\u0439 check-in
  /// \u0424\u0430\u0437\u0430 1 \u2014 \u0441\u0436\u0430\u0442\u0438\u0435 \u043a\u043d\u043e\u043f\u043a\u0438.
  static const double checkinButtonScaleDown = 0.95;

  /// \u0424\u0430\u0437\u0430 2 \u2014 \u0440\u0430\u0441\u0448\u0438\u0440\u0435\u043d\u0438\u0435 \u0441 \u043f\u0435\u0440\u0435\u043b\u0451\u0442\u043e\u043c.
  static const double checkinButtonScaleUp = 1.1;

  // \u2500\u2500 \u041f\u0443\u043b\u044c\u0441 \u0437\u043d\u0430\u0447\u043a\u0430 \u0441\u0435\u0440\u0438\u0438
  /// \u041c\u0430\u043a\u0441\u0438\u043c\u0430\u043b\u044c\u043d\u044b\u0439 \u043c\u0430\u0441\u0448\u0442\u0430\u0431 \u043f\u0443\u043b\u044c\u0441\u0430.
  static const double streakBadgePulseMaxScale = 1.08;

  /// \u041c\u0438\u043d\u0438\u043c\u0430\u043b\u044c\u043d\u0430\u044f \u0441\u0435\u0440\u0438\u044f \u0434\u043b\u044f \u0432\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f \u043f\u0443\u043b\u044c\u0441\u0430.
  static const int streakBadgePulseThreshold = 3;

  // \u2500\u2500 WebSocket \u0443\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u0435
  /// \u0412\u0440\u0435\u043c\u044f \u0432\u0438\u0434\u0438\u043c\u043e\u0441\u0442\u0438 \u0443\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f \u043f\u0435\u0440\u0435\u0434 \u0444\u0435\u0439\u0434\u043e\u043c.
  static const Duration wsNotificationVisibleDuration =
      Duration(seconds: 4);
}

