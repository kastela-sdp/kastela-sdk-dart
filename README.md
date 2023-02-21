Kastela Client SDK for Dart / Flutter.

## Getting started

To start using the SDK, simply run :
```
flutter pub add kastela_sdk_dart
```
Then
```dart
flutter pub get
```

To import Kastela Client SDK
```dart
import 'package:kastela_sdk_dart/kastela_sdk_dart.dart';
```
Initialize Kastela Client SDK
```dart
KastelaClient client = KastelaClient(
	https://www.some-sites.xyz, //Your Kastela URL
);
```

## Usage
Retrieving `Secure Channel Token`

```dart  
SecureChannelToken secureChannel = await client.secureChannelSend(
	credential,
	data
);
```