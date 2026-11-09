import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_alert_dialog/native_alert_dialog_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platform = MethodChannelNativeAlertDialog();
  final channel = platform.methodChannel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();
  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall) respond;

  Future<void> spanTap(Object? arguments) async {
    final completed = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall('onDesSpanTap', arguments)),
      (_) => completed.complete(),
    );
    await completed.future;
  }

  setUp(() {
    calls = [];
    respond = (_) async => null;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return respond(call);
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion uses the actual plugin channel', () async {
    expect(channel.name, 'io.github.jixiaoyong.native_alert_dialog');
    respond = (_) async => '42';
    expect(await platform.getPlatformVersion(), '42');
  });

  test(
    'dialog serializes nullable cancel, alignment and outside dismissal',
    () async {
      respond = (_) async => false;
      expect(
        await platform.showDialog(
          title: '标题',
          desText: '说明',
          desSpans: [
            {'text': '链接', 'clickable': true, 'clickKey': 'link'},
          ],
          desTextAlign: TextAlign.center,
          isDismissOnTouchOutside: true,
        ),
        false,
      );
      expect(calls.single.arguments, {
        'title': '标题',
        'desText': '说明',
        'cancelText': null,
        'confirmText': '确定',
        'desTextAlign': 'center',
        'isDismissOnTouchOutside': true,
      });
      await platform.showDialog(title: '标题', cancelText: '取消');
      expect(calls.last.arguments['cancelText'], '取消');
      expect(calls.last.arguments['isDismissOnTouchOutside'], false);
    },
  );

  test('empty plain text falls back to rich spans for both platforms',
      () async {
    final spans = [
      {'text': '链接', 'clickable': true, 'clickKey': 'link'},
    ];
    await platform.showDialog(title: '标题', desText: '', desSpans: spans);
    expect(calls.single.arguments.containsKey('desText'), false);
    expect(calls.single.arguments['desSpans'], spans);
  });

  test('theme color is encoded as unsigned ARGB and omitted by default',
      () async {
    await platform.showDialog(title: 'default');
    expect(calls.last.arguments.containsKey('themeColor'), false);
    for (final argb in [0xFF6750A4, 0x80007AFF, 0x00000000]) {
      await platform.showDialog(title: 'theme', themeColor: Color(argb));
      expect(calls.last.arguments['themeColor'], argb);
    }
  });

  test('loading and toast forward all parameters', () async {
    await platform.showLoading();
    await platform.showLoading(message: '加载中', dismissOnTouchOutside: true);
    await platform.hideLoading();
    await platform.showToast(message: '提示', duration: 1234);
    expect(calls.map((call) => call.method), [
      'showLoading',
      'showLoading',
      'hideLoading',
      'showToast',
    ]);
    expect(calls[0].arguments, {
      'message': null,
      'dismissOnTouchOutside': false,
    });
    expect(calls[1].arguments, {
      'message': '加载中',
      'dismissOnTouchOutside': true,
    });
    expect(calls[2].arguments, null);
    expect(calls[3].arguments, {'message': '提示', 'duration': 1234});
  });

  test('http and https URLs are forwarded without a new whitelist', () async {
    for (final url in ['http://example.com/a', 'https://example.com/a?q=1']) {
      await platform.openUrl(url: url, title: '网页');
      expect(calls.last.arguments, {'url': url, 'title': '网页'});
    }
  });

  test(
    'busy is shared by instances and cannot replace the active callback',
    () async {
      final result = Completer<bool?>();
      respond = (_) => result.future;
      final tapped = <String>[];
      final rejected = <String>[];
      final first = platform.showDialog(
        title: 'first',
        onDesSpanTap: tapped.add,
      );
      await expectLater(
        MethodChannelNativeAlertDialog().showDialog(
          title: 'second',
          onDesSpanTap: rejected.add,
        ),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'busy')),
      );
      const key = '引号\'"\\换行\n</script>🌟';
      await spanTap({'key': key});
      await spanTap(null);
      await spanTap('invalid');
      await spanTap({'key': 42});
      expect(tapped, [key]);
      expect(rejected, isEmpty);
      expect(calls, hasLength(1));
      result.complete(true);
      expect(await first, true);
      await spanTap({'key': 'late'});
      expect(tapped, [key]);
      respond = (_) async => null;
      expect(await platform.showDialog(title: 'next'), null);
      await spanTap({'key': 'stale'});
      expect(tapped, [key]);
    },
  );

  for (final result in [true, false, null]) {
    test('completion $result releases the channel', () async {
      respond = (_) async => result;
      expect(await platform.showDialog(title: 'first'), result);
      expect(
        await MethodChannelNativeAlertDialog().showDialog(title: 'next'),
        result,
      );
    });
  }

  for (final failure in [
    PlatformException(code: 'native_error'),
    MissingPluginException('missing'),
    'not a bool',
  ]) {
    test('failure $failure clears busy and callback state', () async {
      final tapped = <String>[];
      respond = (_) async {
        if (failure is Exception) throw failure;
        return failure;
      };
      await expectLater(
        platform.showDialog(title: 'failure', onDesSpanTap: tapped.add),
        throwsA(anything),
      );
      await spanTap({'key': 'late'});
      expect(tapped, isEmpty);
      respond = (_) async => true;
      expect(
        await MethodChannelNativeAlertDialog().showDialog(title: 'next'),
        true,
      );
    });
  }

  test(
    'invalid nested span fields fail before invoking native or claiming busy',
    () async {
      for (final span in <Map<String, dynamic>>[
        {'text': 42},
        {'text': 'text', 'clickable': 'yes'},
        {'text': 'text', 'clickKey': 42},
      ]) {
        await expectLater(
          platform.showDialog(title: 'invalid', desSpans: [span]),
          throwsArgumentError,
        );
      }
      expect(calls, isEmpty);
      await platform.showDialog(title: 'valid');
      expect(calls, hasLength(1));
    },
  );
}
