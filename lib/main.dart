import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyADZxIJPw27XxuCxyFx9w0tPObh3PWFR0s',
      appId: '1:1032095210983:android:552f23a1ac30f175b53142',
      messagingSenderId: '1032095210983',
      projectId: 'jordannow-547ee',
      storageBucket: 'jordannow-547ee.appspot.com',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late DatabaseReference _databaseReference;
  late ChewieController _chewieController;
  bool isLive = false;
  String appName = "Jordan now TV";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializePlayer();
    _databaseReference = FirebaseDatabase.instance.ref().child('Url');
    loadVideoUrlFromFirebase();
  }

  void initializePlayer() {
    _controller = VideoPlayerController.network("");
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
      placeholder: Center(child: CircularProgressIndicator()),
    );
  }

  void loadVideoUrlFromFirebase() {
    _databaseReference.once().then((event) {
      if (event.snapshot.value != null) {
        String videoUrl = event.snapshot.value.toString();
        if (videoUrl.isNotEmpty) {
          _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          _controller.initialize().then((_) {
            setState(() {
              _controller.play();
              _chewieController = ChewieController(
                videoPlayerController: _controller,
                autoPlay: true,
                looping: true,
                placeholder: Center(child: CircularProgressIndicator()),
              );
            });
          });
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.play();
        break;
      case AppLifecycleState.paused:
        _controller.pause();
        break;
      case AppLifecycleState.inactive:
      // App is in an inactive state and might be killed
        break;
      case AppLifecycleState.detached:
      // App is detached from the view hierarchy
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _controller.seekTo(_controller.value.position + Duration(seconds: 10));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _controller.seekTo(_controller.value.position - Duration(seconds: 10));
            } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
              _controller.setVolume(_controller.value.volume == 0 ? 1.0 : 0.0);
            }
          }
        },
        child: Center(
          child: _chewieController != null && _chewieController.videoPlayerController.value.isInitialized
              ? Stack(
            children: [
              Chewie(
                controller: _chewieController,
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/JordanNowIcon.png',
                    width: 24,
                    height: 24,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      isLive = true;
                      _controller.seekTo(Duration(seconds: 0));
                    });
                  },
                ),
              ),
            ],
          )
              : CircularProgressIndicator(),
        ),
      ),
    );
  }
}