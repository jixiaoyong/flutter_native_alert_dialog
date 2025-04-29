import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:native_alert_dialog/native_alert_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _nativeAlertDialogPlugin = NativeAlertDialog();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _nativeAlertDialogPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Alert Dialog Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                onPressed: () async {
                  final result = await _nativeAlertDialogPlugin.showDialog(
                    title: '是否打开微信？',
                    cancelText: '取消',
                    confirmText: '打开',
                  );

                  if (result == true) {
                    _nativeAlertDialogPlugin.showToast(
                      message: '用户点击了确认按钮',
                      duration: 2000,
                    );
                  } else {
                    _nativeAlertDialogPlugin.showToast(
                      message: '用户点击了取消按钮',
                      duration: 2000,
                    );
                  }
                },
                child: const Text('【仅标题和按钮】'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final result = await _nativeAlertDialogPlugin.showDialog(
                    title: '温馨提示',
                    desText: '这是纯文本描述内容，仅展示不可点击。',
                    cancelText: '取消',
                    confirmText: '确定',
                  );
                  _nativeAlertDialogPlugin.showToast(
                    message: result == true ? '点击了确定' : '点击了取消',
                    duration: 2000,
                  );
                },
                child: const Text('【纯文本描述】'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final result = await _nativeAlertDialogPlugin.showDialog(
                    title: '服务协议和隐私政策指引',
                    desSpans: [
                      MessageSpan(text: "请阅读并同意", clickable: false),
                      MessageSpan(
                        text: "《服务条款》",
                        clickable: true,
                        clickKey: "service",
                      ),
                      MessageSpan(text: "和", clickable: false),
                      MessageSpan(
                        text: "《隐私政策》",
                        clickable: true,
                        clickKey: "privacy",
                      ),
                    ],
                    cancelText: '不同意',
                    confirmText: '同意并继续',
                    onDesSpanTap: (key) {
                      if (key == "service") {
                        _nativeAlertDialogPlugin.showToast(
                          message: '点击了服务条款',
                          duration: 2000,
                        );
                      } else if (key == "privacy") {
                        _nativeAlertDialogPlugin.showToast(
                          message: '点击了隐私政策',
                          duration: 2000,
                        );
                      }
                    },
                  );
                  _nativeAlertDialogPlugin.showToast(
                    message: result == true ? '点击了同意' : '点击了不同意',
                    duration: 2000,
                  );
                },
                child: const Text('【富文本描述+点击回调】'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _nativeAlertDialogPlugin.showToast(
                    message: '这是一条 Toast 消息',
                    duration: 2000,
                  );
                },
                child: const Text('显示 Toast'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
