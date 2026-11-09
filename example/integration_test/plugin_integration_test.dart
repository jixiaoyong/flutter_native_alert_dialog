import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_alert_dialog/native_alert_dialog.dart';
import 'package:native_alert_dialog_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final plugin = NativeAlertDialog();
  const channel = MethodChannel('io.github.jixiaoyong.native_alert_dialog');

  testWidgets('真机平台、Loading 显隐与中文验收首页', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect((await plugin.getPlatformVersion())?.isNotEmpty, true);
    await plugin.showLoading(message: '真机自动验收');
    await tester.pump(const Duration(milliseconds: 300));
    await plugin.hideLoading();
    await plugin.hideLoading();
    expect(find.text('原生弹窗独立验收'), findsOneWidget);
  });

  testWidgets('原生拒绝非 HTTP(S) URL 与错误嵌套参数', (tester) async {
    await expectLater(
      plugin.openUrl(url: 'javascript:alert(1)'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      channel.invokeMethod<bool>('showDialog', {
        'title': '错误参数不得显示弹窗',
        'desSpans': [42],
      }),
      throwsA(isA<PlatformException>()),
    );
  });
}
