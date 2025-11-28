// import 'package:flutter_test/flutter_test.dart';
// import 'package:zettle_sdk/zettle_sdk.dart';
// import 'package:zettle_sdk/zettle_sdk_platform_interface.dart';
// import 'package:zettle_sdk/zettle_sdk_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockZettleSdkPlatform
//     with MockPlatformInterfaceMixin
//     implements ZettleSdkPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final ZettleSdkPlatform initialPlatform = ZettleSdkPlatform.instance;
//
//   test('$MethodChannelZettleSdk is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelZettleSdk>());
//   });
//
//   test('getPlatformVersion', () async {
//     ZettleSdk zettleSdkPlugin = ZettleSdk();
//     MockZettleSdkPlatform fakePlatform = MockZettleSdkPlatform();
//     ZettleSdkPlatform.instance = fakePlatform;
//
//     expect(await zettleSdkPlugin.getPlatformVersion(), '42');
//   });
// }
