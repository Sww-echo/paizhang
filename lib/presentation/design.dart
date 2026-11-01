import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, LogicalKeyboardKey, TextInputFormatter;

/// C-Neumorphic design tokens from `docs/design/tokens.json`.
///
/// Keep the light and dark values synchronized with that file; it is the
/// source of truth for the visual system.
class PzColors {
  const PzColors({
    required this.bg,
    required this.surface,
    required this.sunken,
    required this.hair,
    required this.border,
    required this.fg,
    required this.muted,
    required this.subtle,
    required this.brand,
    required this.brandInk,
    required this.hero,
    required this.heroInk,
    required this.heroSub,
    required this.tint,
    required this.tintInk,
    required this.onBrand,
    required this.win,
    required this.winTint,
    required this.winInk,
    required this.lose,
    required this.loseTint,
    required this.loseInk,
    required this.warn,
    required this.warnTint,
    required this.warnInk,
    required this.conflict,
    required this.focus,
    required this.scrim,
  });

  final Color bg;
  final Color surface;
  final Color sunken;
  final Color hair;
  final Color border;
  final Color fg;
  final Color muted;
  final Color subtle;
  final Color brand;
  final Color brandInk;
  final Color hero;
  final Color heroInk;
  final Color heroSub;
  final Color tint;
  final Color tintInk;
  final Color onBrand;
  final Color win;
  final Color winTint;
  final Color winInk;
  final Color lose;
  final Color loseTint;
  final Color loseInk;
  final Color warn;
  final Color warnTint;
  final Color warnInk;
  final Color conflict;
  final Color focus;
  final Color scrim;

  static const light = PzColors(
    bg: Color(0xFFE9EEEC),
    surface: Color(0xFFEDF2F0),
    sunken: Color(0xFFE2E8E5),
    hair: Color(0xFFDCE3E0),
    border: Color(0xFFD5DEDA),
    fg: Color(0xFF1E2A26),
    muted: Color(0xFF4E5C56),
    subtle: Color(0xFF5D6A65),
    brand: Color(0xFF387261),
    brandInk: Color(0xFF26584A),
    hero: Color(0xFF2A4A41),
    heroInk: Color(0xFFEAF2EF),
    heroSub: Color(0xFFA9C1B8),
    tint: Color(0xFFD6E3DD),
    tintInk: Color(0xFF1F4438),
    onBrand: Color(0xFFFFFFFF),
    win: Color(0xFFA2472F),
    winTint: Color(0xFFEFDCD6),
    winInk: Color(0xFF7A2F1E),
    lose: Color(0xFF3A6890),
    loseTint: Color(0xFFDCE5EC),
    loseInk: Color(0xFF223F57),
    warn: Color(0xFF8A5A16),
    warnTint: Color(0xFFF3E5CE),
    warnInk: Color(0xFF6B440F),
    conflict: Color(0xFF8A5A16),
    focus: Color(0xFF26584A),
    scrim: Color(0x521E2A26),
  );

  static const dark = PzColors(
    bg: Color(0xFF141A18),
    surface: Color(0xFF19201E),
    sunken: Color(0xFF0F1413),
    hair: Color(0xFF242C2A),
    border: Color(0xFF2C3532),
    fg: Color(0xFFE8EDEB),
    muted: Color(0xFF8E9C97),
    subtle: Color(0xFF85938E),
    brand: Color(0xFF6FBFA5),
    brandInk: Color(0xFF8FD8BE),
    hero: Color(0xFF0F1716),
    heroInk: Color(0xFFE8EDEB),
    heroSub: Color(0xFF8E9C97),
    tint: Color(0xFF1E2F29),
    tintInk: Color(0xFF8FD8BE),
    onBrand: Color(0xFF0B100E),
    win: Color(0xFFE08A72),
    winTint: Color(0xFF33211C),
    winInk: Color(0xFFE8A48F),
    lose: Color(0xFF8AB4DA),
    loseTint: Color(0xFF1B2733),
    loseInk: Color(0xFF9CC4E4),
    warn: Color(0xFFE0B070),
    warnTint: Color(0xFF33280F),
    warnInk: Color(0xFFE8C38C),
    conflict: Color(0xFFE0B070),
    focus: Color(0xFF9AD9C2),
    scrim: Color(0x7A000000),
  );

  static PzColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Stable avatar accents are kept in the design layer so presentation widgets
/// do not scatter raw color literals through the UI.
abstract final class PzAvatarColors {
  static const leaf = Color(0xFF2F7D68);
  static const sun = Color(0xFFE29B2D);
  static const wave = Color(0xFF3B82A0);
  static const star = Color(0xFF7B61A8);
  static const fire = Color(0xFFD65A43);
  static const moon = Color(0xFF44546A);
}

abstract final class PzRadius {
  static const double chip = 999;
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 32;
  static const double control = sm;
  static const double card = md;
  static const double sheet = lg;

  static BorderRadius get controlAll => BorderRadius.circular(control);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get chipAll => BorderRadius.circular(chip);
}

enum PzDepth { flat, raise1, raise2, raise3, sink1, sink2, pressed }

/// Centralized soft-neumorphic shadows. Inner shadows use Flutter's
/// `BlurStyle.inner`; no component should construct a BoxShadow directly.
abstract final class PzShadow {
  static const flat = <BoxShadow>[];
  static const darkFlat = <BoxShadow>[];
  static const raise1 = <BoxShadow>[
    BoxShadow(offset: Offset(3, 3), blurRadius: 7, color: Color(0xFFCFD8D4)),
    BoxShadow(offset: Offset(-3, -3), blurRadius: 7, color: Color(0xFFFFFFFF)),
  ];
  static const raise2 = <BoxShadow>[
    BoxShadow(offset: Offset(6, 6), blurRadius: 14, color: Color(0xFFC9D2CD)),
    BoxShadow(offset: Offset(-6, -6), blurRadius: 14, color: Color(0xFFFFFFFF)),
  ];
  static const raise3 = <BoxShadow>[
    BoxShadow(offset: Offset(10, 10), blurRadius: 26, color: Color(0xFFC2CDC7)),
    BoxShadow(offset: Offset(-8, -8), blurRadius: 20, color: Color(0xFFFFFFFF)),
  ];
  static const sink1 = <BoxShadow>[
    BoxShadow(
      offset: Offset(2, 2),
      blurRadius: 5,
      color: Color(0xFFC8D1CD),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-2, -2),
      blurRadius: 5,
      color: Color(0xFFFFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];
  static const sink2 = <BoxShadow>[
    BoxShadow(
      offset: Offset(4, 4),
      blurRadius: 9,
      color: Color(0xFFC6D0CB),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-4, -4),
      blurRadius: 9,
      color: Color(0xFFFFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];
  static const pressed = <BoxShadow>[
    BoxShadow(
      offset: Offset(2, 2),
      blurRadius: 6,
      color: Color(0xFFC4CEC9),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-1, -1),
      blurRadius: 4,
      color: Color(0xFFFFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];

  static const darkRaise1 = <BoxShadow>[
    BoxShadow(offset: Offset(3, 3), blurRadius: 7, color: Color(0xFF080C0B)),
    BoxShadow(offset: Offset(-3, -3), blurRadius: 7, color: Color(0x14FFFFFF)),
  ];
  static const darkRaise2 = <BoxShadow>[
    BoxShadow(offset: Offset(6, 6), blurRadius: 14, color: Color(0xFF080C0B)),
    BoxShadow(offset: Offset(-6, -6), blurRadius: 14, color: Color(0x14FFFFFF)),
  ];
  static const darkRaise3 = <BoxShadow>[
    BoxShadow(offset: Offset(10, 10), blurRadius: 26, color: Color(0xFF070B0A)),
    BoxShadow(offset: Offset(-8, -8), blurRadius: 20, color: Color(0x17FFFFFF)),
  ];
  static const darkSink1 = <BoxShadow>[
    BoxShadow(
      offset: Offset(2, 2),
      blurRadius: 5,
      color: Color(0xFF070B0A),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-2, -2),
      blurRadius: 5,
      color: Color(0x0AFFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];
  static const darkSink2 = <BoxShadow>[
    BoxShadow(
      offset: Offset(4, 4),
      blurRadius: 9,
      color: Color(0xFF070B0A),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-4, -4),
      blurRadius: 9,
      color: Color(0x0AFFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];
  static const darkPressed = <BoxShadow>[
    BoxShadow(
      offset: Offset(2, 2),
      blurRadius: 6,
      color: Color(0xFF070B0A),
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      offset: Offset(-1, -1),
      blurRadius: 4,
      color: Color(0x10FFFFFF),
      blurStyle: BlurStyle.inner,
    ),
  ];

  static List<BoxShadow> of(PzDepth depth, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return switch (depth) {
        PzDepth.flat => darkFlat,
        PzDepth.raise1 => darkRaise1,
        PzDepth.raise2 => darkRaise2,
        PzDepth.raise3 => darkRaise3,
        PzDepth.sink1 => darkSink1,
        PzDepth.sink2 => darkSink2,
        PzDepth.pressed => darkPressed,
      };
    }
    return switch (depth) {
      PzDepth.flat => flat,
      PzDepth.raise1 => raise1,
      PzDepth.raise2 => raise2,
      PzDepth.raise3 => raise3,
      PzDepth.sink1 => sink1,
      PzDepth.sink2 => sink2,
      PzDepth.pressed => pressed,
    };
  }
}

/// Explicit signed formatting: sign is the first encoding, never color alone.
/// Zero renders without a sign; negatives use U+2212 like the proposal.
String pzSigned(int value) {
  if (value > 0) return '+$value';
  if (value < 0) return '−${value.abs()}';
  return '0';
}

/// Tabular, monospaced-feeling numerals used for scores and amounts.
TextStyle pzMonoStyle({
  required double size,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: -0.2,
  );
}

/// Shared page transition: a quiet fade with a small upward settle.
class PzPageRoute<T> extends PageRouteBuilder<T> {
  PzPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
            return child;
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}

/// Staggered entrance used for first-screen cards and rows.
class PzReveal extends StatefulWidget {
  const PzReveal({required this.child, this.delay = Duration.zero, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<PzReveal> createState() => _PzRevealState();
}

class _PzRevealState extends State<PzReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Positive/negative score text with explicit sign and unit.
class PzScoreText extends StatelessWidget {
  const PzScoreText(
    this.value, {
    super.key,
    this.unit,
    this.size = 21,
    this.color,
    this.alignment = TextAlign.right,
  });

  final int value;
  final String? unit;
  final double size;
  final Color? color;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final tone =
        color ??
        (value > 0
            ? c.win
            : value < 0
            ? c.lose
            : c.muted);
    final visible = unit == null || unit!.isEmpty
        ? pzSigned(value)
        : '${pzSigned(value)} $unit';
    final spoken = value > 0
        ? '收入 ${value.abs()} ${unit ?? ''}'
        : value < 0
        ? '支出 ${value.abs()} ${unit ?? ''}'
        : '持平 0 ${unit ?? ''}';
    return Semantics(
      label: spoken.trim(),
      excludeSemantics: true,
      child: Text(
        visible,
        textAlign: alignment,
        style: pzMonoStyle(size: size, color: tone),
      ),
    );
  }
}

enum PzButtonTone { primary, secondary, ghost }

/// 48 px minimum touch target; the primary action is 52 px tall.
class PzButton extends StatefulWidget {
  const PzButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = PzButtonTone.primary,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PzButtonTone tone;
  final bool busy;
  final String? busyLabel;

  @override
  State<PzButton> createState() => _PzButtonState();
}

class _PzButtonState extends State<PzButton> {
  bool _down = false;

  void _releaseAfterPress() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _down = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final enabled = !widget.busy && widget.onPressed != null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final text = widget.busy ? (widget.busyLabel ?? '正在提交…') : widget.label;
    final child = widget.icon == null
        ? Text(text)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
            ],
          );
    const textStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700);
    final isPrimary = widget.tone == PzButtonTone.primary;
    final isGhost = widget.tone == PzButtonTone.ghost;
    final background = !enabled
        ? c.sunken
        : isPrimary
        ? c.brand
        : isGhost
        ? c.bg
        : c.surface;
    final foreground = !enabled
        ? c.subtle
        : isPrimary
        ? c.onBrand
        : c.brandInk;
    final depth = !enabled
        ? PzDepth.flat
        : _down
        ? (isGhost ? PzDepth.sink1 : PzDepth.pressed)
        : (isGhost
              ? PzDepth.flat
              : (isPrimary ? PzDepth.raise2 : PzDepth.raise1));
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _down = true) : null,
      onPointerCancel: enabled ? (_) => setState(() => _down = false) : null,
      onPointerUp: enabled ? (_) => _releaseAfterPress() : null,
      child: AnimatedScale(
        scale: reduceMotion || !_down ? 1 : .98,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutQuad,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutQuad,
          constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(PzRadius.sm),
            boxShadow: PzShadow.of(depth, Theme.of(context).brightness),
          ),
          child: FilledButton(
            onPressed: enabled
                ? () {
                    widget.onPressed?.call();
                    unawaited(HapticFeedback.lightImpact());
                    _releaseAfterPress();
                  }
                : null,
            style:
                FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: foreground,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: foreground,
                  minimumSize: const Size(48, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PzRadius.sm),
                  ),
                  textStyle: textStyle,
                  overlayColor: Colors.transparent,
                ).copyWith(
                  side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
                    if (states.contains(WidgetState.focused)) {
                      return BorderSide(color: c.focus, width: 2);
                    }
                    return BorderSide.none;
                  }),
                ),
            child: DefaultTextStyle.merge(
              style: textStyle.copyWith(color: foreground),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick-select chip (常用金额、平摊、正负切换).
class PzChip extends StatefulWidget {
  const PzChip({
    super.key,
    required this.label,
    this.onTap,
    this.hot = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool hot;
  final bool enabled;

  @override
  State<PzChip> createState() => _PzChipState();
}

class _PzChipState extends State<PzChip> {
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final background = widget.hot ? c.brand : c.surface;
    final foreground = widget.hot ? c.onBrand : c.fg;
    final enabled = widget.enabled && widget.onTap != null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    void activate() {
      if (!enabled) return;
      setState(() => _down = false);
      widget.onTap?.call();
      unawaited(HapticFeedback.lightImpact());
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (focused) {
          if (mounted) setState(() => _focused = focused);
        },
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTap: enabled ? activate : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          child: AnimatedContainer(
            duration: reduceMotion
                ? const Duration(milliseconds: 120)
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? background : c.sunken,
              borderRadius: PzRadius.chipAll,
              border: _focused ? Border.all(color: c.focus, width: 2) : null,
              boxShadow: PzShadow.of(
                enabled && (_down || widget.hot)
                    ? (_down ? PzDepth.pressed : PzDepth.raise1)
                    : PzDepth.flat,
                Theme.of(context).brightness,
              ),
            ),
            child: Text(
              widget.label,
              style: pzMonoStyle(
                size: 13,
                weight: FontWeight.w600,
                color: enabled ? foreground : c.subtle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded status pill used in board headers.
class PzPill extends StatelessWidget {
  const PzPill(this.label, {super.key, this.tone = PzPillTone.brand});

  final String label;
  final PzPillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final (background, foreground) = switch (tone) {
      PzPillTone.brand => (c.tint, c.brandInk),
      PzPillTone.accent => (c.warnTint, c.warnInk),
      PzPillTone.grey => (c.sunken, c.muted),
      PzPillTone.win => (c.winTint, c.winInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: PzRadius.chipAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

enum PzPillTone { brand, accent, grey, win }

/// Surface board: the single grouping primitive for lists of rows.
class PzBoard extends StatelessWidget {
  const PzBoard({
    super.key,
    this.title,
    this.pill,
    this.headerTrailing,
    this.children = const [],
    this.dividerBetween = true,
    this.background,
    this.onHeaderTap,
  });

  final String? title;
  final Widget? pill;
  final Widget? headerTrailing;
  final List<Widget> children;
  final bool dividerBetween;

  /// Defaults to the surface token; dialogs use the sunken token.
  final Color? background;

  /// Makes the header row tappable (展开／收起 etc.).
  final VoidCallback? onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      rows.add(children[index]);
      if (dividerBetween && index != children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, color: c.hair));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: PzRadius.cardAll,
        boxShadow: PzShadow.of(PzDepth.raise2, Theme.of(context).brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            _PzBoardHeader(
              title: title!,
              pill: pill,
              trailing: headerTrailing,
              onTap: onHeaderTap,
            ),
          ...rows,
        ],
      ),
    );
  }
}

class _PzBoardHeader extends StatefulWidget {
  const _PzBoardHeader({
    required this.title,
    required this.pill,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final Widget? pill;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<_PzBoardHeader> createState() => _PzBoardHeaderState();
}

class _PzBoardHeaderState extends State<_PzBoardHeader> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final enabled = widget.onTap != null;
    void activate() {
      if (!enabled) return;
      widget.onTap?.call();
    }

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.title,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (focused) {
          if (mounted) setState(() => _focused = focused);
        },
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: enabled ? activate : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutQuad,
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              border: _focused ? Border.all(color: c.focus, width: 2) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.fg,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  const SizedBox(width: 8),
                ],
                ?widget.pill,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Board row: rank / avatar / name / detail / trailing value.
class PzBoardRow extends StatefulWidget {
  const PzBoardRow({
    super.key,
    this.rank,
    this.avatar,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
    this.highlight = false,
    this.titleColor,
  });

  final String? rank;
  final Widget? avatar;
  final String title;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? titleColor;

  @override
  State<PzBoardRow> createState() => _PzBoardRowState();
}

class _PzBoardRowState extends State<PzBoardRow> {
  bool _down = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final enabled = widget.onTap != null;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutQuad,
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: widget.highlight || _down ? c.sunken : null,
        border: _focused ? Border.all(color: c.focus, width: 2) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 尾部（分数/金额）最多占行宽的 45%，剩余留给标题区。
          // 用 LayoutBuilder 而不是 MediaQuery：真实行宽还要扣掉页面 padding
          // 与 PzBoard 内边距，MediaQuery 只反映屏幕宽，窄屏 + 大字号时会溢出。
          final trailingMaxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 0.45
              : double.infinity;
          return Row(
            children: [
              if (widget.rank != null) ...[
                SizedBox(
                  width: 22,
                  child: Text(
                    widget.rank!,
                    textAlign: TextAlign.center,
                    style: pzMonoStyle(size: 11.5, color: c.subtle),
                  ),
                ),
                const SizedBox(width: 9),
              ],
              if (widget.avatar != null) ...[
                widget.avatar!,
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.titleColor ?? c.fg,
                      ),
                    ),
                    if (widget.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 9),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: trailingMaxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: widget.trailing!,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
    if (!enabled) return content;

    void activate() {
      setState(() => _down = false);
      unawaited(HapticFeedback.lightImpact());
      widget.onTap?.call();
    }

    return Semantics(
      button: true,
      enabled: true,
      label: widget.detail == null
          ? widget.title
          : '${widget.title}，${widget.detail}',
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) {
          if (mounted) setState(() => _focused = focused);
        },
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTap: activate,
          onTapCancel: () => setState(() => _down = false),
          child: content,
        ),
      ),
    );
  }
}

/// Sunken summary meter (合计转出、本回合差额).
class PzMeter extends StatelessWidget {
  const PzMeter({
    super.key,
    required this.label,
    required this.value,
    this.tone = PzMeterTone.neutral,
  });

  final String label;
  final String value;
  final PzMeterTone tone;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final valueColor = switch (tone) {
      PzMeterTone.neutral => c.fg,
      PzMeterTone.balanced => c.brandInk,
      PzMeterTone.unbalanced => c.warn,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: PzRadius.controlAll,
        boxShadow: PzShadow.of(PzDepth.sink1, Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: c.muted),
            ),
          ),
          Text(value, style: pzMonoStyle(size: 13.5, color: valueColor)),
        ],
      ),
    );
  }
}

enum PzMeterTone { neutral, balanced, unbalanced }

/// Inline warning box for pending/conflict/closed states.
class PzNotice extends StatelessWidget {
  const PzNotice({super.key, required this.message, this.title, this.trailing});

  final String message;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.warnTint,
        borderRadius: PzRadius.controlAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.warnInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(message, style: TextStyle(fontSize: 13, color: c.warnInk)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Sunken context block: "周五夜局 · 晚场麻将" + secondary line.
class PzContextBox extends StatelessWidget {
  const PzContextBox({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: PzRadius.controlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.fg,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
          if (child != null) ...[const SizedBox(height: 10), child!],
        ],
      ),
    );
  }
}

/// Field label, always visible above its input.
class PzLabel extends StatelessWidget {
  const PzLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.fg,
        ),
      ),
    );
  }
}

/// Sunken text field with a single, accessible focus ring.
class PzTextField extends StatefulWidget {
  const PzTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.suffix,
    this.semanticsLabel,
    this.autoFill = false,
    this.textAlign = TextAlign.start,
    this.fieldKey,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffix;
  final String? semanticsLabel;

  /// Tinted fill for 自动补齐 / 平摊填入 values.
  final bool autoFill;
  final TextAlign textAlign;

  /// Key placed on the inner [TextField] (form-field level, not the wrapper).
  final Key? fieldKey;

  @override
  State<PzTextField> createState() => _PzTextFieldState();
}

class _PzTextFieldState extends State<PzTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _setFocusNode(widget.focusNode);
  }

  void _setFocusNode(FocusNode? focusNode) {
    _focusNode = focusNode ?? FocusNode();
    _ownsFocusNode = focusNode == null;
  }

  @override
  void didUpdateWidget(covariant PzTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    if (_ownsFocusNode) _focusNode.dispose();
    _setFocusNode(widget.focusNode);
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      style: TextStyle(fontSize: 15, color: c.fg),
      textAlign: widget.textAlign,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: widget.hint,
        hintStyle: TextStyle(fontSize: 14, color: c.subtle),
        suffixIcon: widget.suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: InputBorder.none,
      ),
    );
    Widget result(bool focused) => AnimatedContainer(
      duration: reduceMotion
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: !widget.enabled
            ? c.sunken
            : widget.autoFill
            ? c.tint
            : c.sunken,
        borderRadius: BorderRadius.circular(PzRadius.sm),
        border: focused ? Border.all(color: c.focus, width: 2) : null,
        boxShadow: PzShadow.of(
          focused ? PzDepth.sink1 : PzDepth.sink2,
          Theme.of(context).brightness,
        ),
      ),
      child: field,
    );
    final wrapped = AnimatedBuilder(
      animation: _focusNode,
      builder: (_, _) => result(_focusNode.hasFocus),
    );
    if (widget.semanticsLabel == null) return wrapped;
    return Semantics(
      label: widget.semanticsLabel,
      textField: true,
      child: wrapped,
    );
  }
}

/// Token-styled dropdown (牌局选择 etc.).
class PzDropdown<T> extends StatelessWidget {
  const PzDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: c.muted),
      dropdownColor: c.surface,
      style: TextStyle(fontSize: 15, color: c.fg),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: c.sunken,
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: c.muted),
        floatingLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.brandInk,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: PzRadius.controlAll,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class PzHint extends StatelessWidget {
  const PzHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 12, height: 1.6, color: c.muted),
    );
  }
}

class PzFormError extends StatelessWidget {
  const PzFormError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final c = PzColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message!,
        style: TextStyle(fontSize: 13, height: 1.5, color: c.conflict),
      ),
    );
  }
}

/// Checkbox line with a 48 px touch target.
class PzCheckline extends StatelessWidget {
  const PzCheckline({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: PzRadius.controlAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (next) => onChanged!(next ?? false),
              activeColor: c.brand,
              checkColor: c.onBrand,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: c.fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading inside pages.
class PzSectionTitle extends StatelessWidget {
  const PzSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.fg,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Dialog shell: surface card, 32 radius, actions row with the primary last.
class PzDialogShell extends StatelessWidget {
  const PzDialogShell({
    super.key,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.actions = const [],
    this.maxWidth = 440,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Last entry is rendered as the primary action (flex 7 vs 5).
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PzRadius.xl),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(PzRadius.xl),
          boxShadow: PzShadow.of(PzDepth.raise3, Theme.of(context).brightness),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(context).height * .84,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.fg,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: c.muted,
                    ),
                  ),
                ],
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < children.length; i++) ...[
                            if (i != 0) const SizedBox(height: 12),
                            children[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i != 0) const SizedBox(width: 8),
                          Expanded(
                            flex: i == actions.length - 1 ? 7 : 5,
                            child: actions[i],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared theme built from the same tokens.
abstract final class PzTheme {
  static ThemeData light() => _build(PzColors.light, Brightness.light);

  static ThemeData dark() => _build(PzColors.dark, Brightness.dark);

  static ThemeData _build(PzColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.brand,
          brightness: brightness,
        ).copyWith(
          primary: c.brand,
          onPrimary: c.onBrand,
          primaryContainer: c.tint,
          onPrimaryContainer: c.tintInk,
          primaryFixed: c.brand,
          primaryFixedDim: c.brand,
          onPrimaryFixed: c.onBrand,
          onPrimaryFixedVariant: c.onBrand,
          secondary: c.brand,
          onSecondary: c.onBrand,
          secondaryContainer: c.tint,
          onSecondaryContainer: c.tintInk,
          secondaryFixed: c.brand,
          secondaryFixedDim: c.brand,
          onSecondaryFixed: c.onBrand,
          onSecondaryFixedVariant: c.onBrand,
          tertiary: c.warn,
          onTertiary: c.onBrand,
          tertiaryContainer: c.warnTint,
          onTertiaryContainer: c.warnInk,
          tertiaryFixed: c.warn,
          tertiaryFixedDim: c.warn,
          onTertiaryFixed: c.onBrand,
          onTertiaryFixedVariant: c.onBrand,
          surface: c.bg,
          onSurface: c.fg,
          error: c.win,
          onError: c.onBrand,
          errorContainer: c.winTint,
          onErrorContainer: c.winInk,
          surfaceDim: c.bg,
          surfaceBright: c.surface,
          surfaceContainerLowest: c.sunken,
          surfaceContainer: c.surface,
          surfaceContainerHigh: c.surface,
          outline: c.border,
          outlineVariant: c.hair,
          shadow: c.sunken,
          scrim: c.scrim,
          inverseSurface: c.hero,
          onInverseSurface: c.heroInk,
          inversePrimary: c.brandInk,
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: c.sunken,
          surfaceContainerLow: c.surface,
          onSurfaceVariant: c.muted,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'PingFang SC',
      fontFamilyFallback: const [
        'Noto Sans CJK SC',
        'Microsoft YaHei',
        'sans-serif',
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.fg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.fg,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.tint,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fg),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.hair, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.sunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PzRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PzRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PzRadius.sm),
          borderSide: BorderSide(color: c.focus, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PzRadius.sm),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: c.subtle),
        labelStyle: TextStyle(color: c.muted),
        floatingLabelStyle: TextStyle(
          color: c.brandInk,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: PzRadius.cardAll),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.hero,
        contentTextStyle: TextStyle(color: c.heroInk, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.tint,
      ),
    );
  }
}

/// All dialogs share the C-Neumorphic scrim token.
Future<T?> showPzDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: PzColors.of(context).scrim,
    builder: builder,
  );
}

/// 前置确认：说明动作后果，返回用户是否确认。
Future<bool> pzConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '取消',
  bool primaryConfirm = true,
}) async {
  final confirmed = await showPzDialog<bool>(
    context: context,
    builder: (dialogContext) => PzDialogShell(
      title: title,
      actions: [
        PzButton(
          label: cancelLabel,
          tone: PzButtonTone.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        PzButton(
          label: confirmLabel,
          tone: primaryConfirm ? PzButtonTone.primary : PzButtonTone.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
      children: [PzHint(message)],
    ),
  );
  return confirmed ?? false;
}
