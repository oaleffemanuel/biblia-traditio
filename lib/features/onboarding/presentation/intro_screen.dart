import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/l10n_ext.dart';

/// First-launch intro: the emblem drawing itself, with its soundtrack. Plays
/// once before onboarding; a "skip" is offered from the first frame. Anything
/// that stops the video from playing (missing plugin, autoplay blocked, decode
/// error, a stall) falls through to onboarding instead of trapping the reader.
class IntroScreen extends StatefulWidget {
  /// The background of the clip itself, so letterboxing on any aspect ratio is
  /// invisible.
  static const background = Color(0xFFF5C221);
  static const asset = 'assets/intro/intro.mp4';

  /// What to do when the clip ends or is skipped. Defaults to onboarding.
  final VoidCallback? onDone;
  const IntroScreen({super.key, this.onDone});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _done = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(IntroScreen.asset)
      ..addListener(_onTick);
    // If the clip has not started within this window, don't keep the reader
    // staring at a yellow screen.
    _watchdog = Timer(const Duration(seconds: 3), () {
      if (!_controller.value.isPlaying) _finish();
    });
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.play();
    } catch (_) {
      _finish();
    }
  }

  void _onTick() {
    final v = _controller.value;
    if (v.hasError) return _finish();
    if (v.isInitialized &&
        !v.isPlaying &&
        v.duration > Duration.zero &&
        v.position >= v.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _watchdog?.cancel();
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IntroScreen.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  key: const ValueKey('intro-skip'),
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xB3000000),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  child: Text(context.l10n.introSkip),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
