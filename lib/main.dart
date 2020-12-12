import 'package:camera_with_rtmp/camera.dart';
import 'package:flutter/material.dart';

import 'hls_page.dart';

List<CameraDescription> cameras;
final _tab = <Tab> [
  Tab( text:'RTMP', icon: Icon(Icons.not_started_outlined)),
  Tab( text:'HLS', icon: Icon(Icons.ondemand_video)),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {

  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
        length: 2, vsync: this
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "mypage",
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Camera example'),
            bottom: TabBar(
              controller: _tabController,
              tabs: _tab,
            ),
          ),
          body: TabBarView(
              controller: _tabController,
              children: [
                Home(),
                HlsPage(),
              ]
          ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  CameraController controller;
  String url;
  TextEditingController _textFieldController = TextEditingController(
      text: "rtmp://35.243.76.27/live/ios");

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();

    if (cameras == null) {
      return;
    }

    controller = CameraController(
      cameras[1],
      ResolutionPreset.medium,
      enableAudio: true,
      androidUseOpenGL: true,
    );

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Container(
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.value.isStreamingVideoRtmp ?
          onStopButtonPressed() :
          onVideoStreamingButtonPressed();
        },
        label: Text('Start'),
        icon: Icon(
          controller.value.isStreamingVideoRtmp ? Icons.stop : Icons.not_started_outlined,
          // color: Colors.redAccent,
        ),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void onVideoStreamingButtonPressed() {
    print("pressStreaming");
    startVideoStreaming().then((String url) {
      if (mounted) setState(() {});
    });
  }

  void onStopButtonPressed() {
    stopVideoStreaming().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<String> startVideoStreaming() async {
    if (!controller.value.isInitialized) {
      return null;
    }

    if (controller.value.isStreamingVideoRtmp) {
      return null;
    }

    // Open up a dialog for the url
    String myUrl = await _getUrl();

    try {
      url = myUrl;

      if (url == null) {
        return null;
      }

      await controller.startVideoStreaming(url);
    } on CameraException catch (e) {
      return null;
    }
    return url;
  }

  // 配信URL設定用ダイアログ表示
  Future<String> _getUrl() async {
    String result = _textFieldController.text;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Url to Stream to'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Url to Stream to"),
              onChanged: (String str) => result = str,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
                onPressed: () {
                  Navigator.pop(context, result);
                },
              )
            ],
          );
        },
    );
  }

  Future<void> stopVideoStreaming() async {
    if (!controller.value.isStreamingVideoRtmp) {
      return null;
    }

    try {
      await controller.stopVideoStreaming();
    } on CameraException catch (e) {
      return null;
    }
  }
}
