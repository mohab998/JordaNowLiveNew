import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomChewieProgress extends StatefulWidget {
  final ChewieController controller;

  const CustomChewieProgress({
    required this.controller,
  });

  @override
  _CustomChewieProgressState createState() => _CustomChewieProgressState();
}

class _CustomChewieProgressState extends State<CustomChewieProgress> {
  late VideoPlayerValue _latestValue;
  late double _progress;

  @override
  void initState() {
    super.initState();
    _latestValue = widget.controller.videoPlayerController.value;
    _progress = _latestValue.position.inMilliseconds /
        widget.controller.videoPlayerController.value.duration.inMilliseconds;
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _latestValue = widget.controller.videoPlayerController.value;
      _progress = _latestValue.position.inMilliseconds /
          widget.controller.videoPlayerController.value.duration.inMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Container(
                  height: 4.0,
                  width: MediaQuery.of(context).size.width * _progress,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }
}
