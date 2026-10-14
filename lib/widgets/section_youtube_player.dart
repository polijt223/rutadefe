// youtube_player_iframe has no Windows plugin, so the analyzer on Windows
// cannot resolve the package even though Android builds it.
// ignore_for_file: uri_does_not_exist, undefined_class, undefined_identifier, undefined_method

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class SectionYoutubePlayer extends StatefulWidget {
  final String url;
  const SectionYoutubePlayer({super.key, required this.url});

  @override
  State<SectionYoutubePlayer> createState() => _SectionYoutubePlayerState();
}

class _SectionYoutubePlayerState extends State<SectionYoutubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(controller: _controller!),
    );
  }
}
