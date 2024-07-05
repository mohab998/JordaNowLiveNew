import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
void enableWakelock() {
  WakelockPlus.enable();
}

void disableWakelock() {
  WakelockPlus.disable();
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
  FocusNode _focusNode = FocusNode();
  bool isLive = false;
  bool isFullScreen = false;
  Color videoRowColor = Colors.red;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializePlayer();
    enableWakelock();
    _databaseReference = FirebaseDatabase.instance.ref().child('Url');
    loadVideoUrlFromFirebase();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void initializePlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(""));
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
      placeholder: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(videoRowColor),
        ),
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: videoRowColor,
        handleColor: videoRowColor,
        backgroundColor: Colors.transparent,
        bufferedColor: videoRowColor.withOpacity(0.5),
      ),
    );
  }


  void loadVideoUrlFromFirebase() {
    _databaseReference.once().then((event) {
      if (event.snapshot.value != null) {
        String videoUrl = event.snapshot.value.toString();
        if (videoUrl.isNotEmpty) {
          _controller.dispose();
          _chewieController.dispose();
          _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          _controller.initialize().then((_) {
            setState(() {
              _controller.play();
              _chewieController = ChewieController(
                videoPlayerController: _controller,
                autoPlay: true,
                looping: true,
                placeholder: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(videoRowColor),
                  ),
                ),
                materialProgressColors: ChewieProgressColors(
                  playedColor: videoRowColor,
                  handleColor: videoRowColor,
                  backgroundColor: Colors.transparent,
                  bufferedColor: videoRowColor.withOpacity(0.5),
                ),
              );
              isLoading = false;
            });
          }).catchError((error) {
            print('Error initializing video player: $error');
          });
        }
      }
    }).catchError((error) {
      print('Error loading video URL from Firebase: $error');
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.play();
        enableWakelock();
        break;
      case AppLifecycleState.paused:
        _controller.pause();
        disableWakelock();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        disableWakelock();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disableWakelock();
    _controller.dispose();
    _chewieController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
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
            }
          }
        },
        child: Center(
          child: Stack(
            children: [
              _chewieController.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController)
                  : isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(videoRowColor),
                ),
              )
                  : Container(),
              if (isFullScreen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: toggleFullScreen,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}