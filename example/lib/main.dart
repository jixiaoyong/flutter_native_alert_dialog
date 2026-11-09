import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_alert_dialog/native_alert_dialog.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = NativeAlertDialog();
  String _platform = '读取中';
  String _result = '点击下方入口验收；原生弹窗关闭后结果显示在这里。';
  static const _specialKey = '协议\'"&?#中文/换行\n结束';

  @override
  void initState() {
    super.initState();
    _loadPlatform();
  }

  Future<void> _loadPlatform() async {
    try {
      final version = await _plugin.getPlatformVersion();
      if (mounted) setState(() => _platform = version ?? '未知');
    } on PlatformException catch (error) {
      _record('读取平台失败：${error.code}');
    }
  }

  void _record(String text) {
    if (mounted) setState(() => _result = text);
  }

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error) {
      _record('原生返回：${error.code} ${error.message ?? ''}');
    } catch (error) {
      _record('调用失败：$error');
    }
  }

  Future<void> _dialog(
    BuildContext context, {
    bool outside = false,
    bool special = false,
  }) async {
    final result = await _plugin.showDialog(
      themeColor: Theme.of(context).colorScheme.primary,
      title: special ? '特殊 key 回调验收' : '确定 / 取消 / 背景关闭',
      desText: special ? null : '确定应返回 true；取消、返回或允许的背景关闭应返回 false。',
      desSpans:
          special
              ? [
                MessageSpan(
                  text: '点击此协议链接（点击后显示原生提示）',
                  clickable: true,
                  clickKey: _specialKey,
                ),
              ]
              : null,
      cancelText: '取消',
      desTextAlign: TextAlign.left,
      isDismissOnTouchOutside: outside,
      onDesSpanTap:
          special
              ? (key) {
                final matches = key == _specialKey;
                _record('特殊 key 完整一致：$matches\n收到：$key');
                unawaited(
                  _perform(
                    () => _plugin.showToast(
                      message:
                          matches ? '协议点击成功：特殊 key 完整一致' : '协议点击失败：key 不一致',
                    ),
                  ),
                );
              }
              : null,
    );
    if (!special) _record('Dialog 结果：$result');
  }

  Future<void> _repeatDialog() async {
    final first = _plugin.showDialog(
      title: '第一个弹窗',
      desText: '重复调用应被拒绝，不替换本弹窗。',
      cancelText: '取消',
    );
    try {
      await _plugin.showDialog(title: '第二个弹窗不应出现');
      _record('重复调用未被拒绝，请检查');
    } on PlatformException catch (error) {
      _record('重复调用：${error.code}；第一个弹窗仍应正常响应');
    }
    final result = await first;
    _record('重复调用已结束；首个弹窗结果：$result');
  }

  Future<void> _loading() async {
    await _plugin.showLoading(
      message: '加载中，2 秒后自动隐藏',
      dismissOnTouchOutside: false,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    await _plugin.hideLoading();
    _record('Loading 已显示并隐藏');
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Builder(
      builder:
          (context) => Scaffold(
            appBar: AppBar(title: const Text('原生弹窗独立验收')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('运行平台：$_platform'),
                const SizedBox(height: 12),
                SelectableText(_result, key: const Key('result')),
                const SizedBox(height: 12),
                _button('Dialog 确定 / 取消', () => _dialog(context)),
                _button('Dialog 允许背景取消', () => _dialog(context, outside: true)),
                _button('仅确定按钮（cancelText 为空）', () async {
                  final result = await _plugin.showDialog(
                    title: '只有确定按钮',
                    desText: '取消按钮应隐藏',
                  );
                  _record('仅确定结果：$result');
                }),
                _button('特殊 key 富文本回调', () => _dialog(context, special: true)),
                _button('重复调用（拒绝第二次）', _repeatDialog),
                _button('Loading 显示并自动隐藏', _loading),
                _button('Loading 允许背景关闭', () async {
                  await _plugin.showLoading(
                    message: '点击背景关闭',
                    dismissOnTouchOutside: true,
                  );
                  _record('点击背景关闭后，可继续测试 Dialog');
                }),
                _button('隐藏 Loading（可重复）', () async {
                  await _plugin.hideLoading();
                  _record('隐藏 Loading 已返回');
                }),
                _button('无标题网页（检查关闭入口）', () async {
                  await _plugin.openUrl(url: 'https://example.com');
                  _record('网页已打开，请使用关闭入口返回');
                }),
                _button(
                  '显示 Toast',
                  () => _plugin.showToast(message: '原生 Toast 验收'),
                ),
              ],
            ),
          ),
    ),
  );

  Widget _button(String label, Future<void> Function() action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ElevatedButton(
      onPressed: () => _perform(action),
      child: Text(label),
    ),
  );
}
