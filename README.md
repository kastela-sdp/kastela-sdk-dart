Kastela Client SDK for Flutter.

## Getting started

To start using the SDK, simply run :
```
flutter pub add flutter_kastela_pkg
```
Then
```dart
flutter pub get
```

To import Kastela Client SDK
```dart
import 'package:flutter_kastela_pkg/flutter_kastela_pkg.dart';
```
Initialize Kastela Client SDK
```dart
KastelaClient client = KastelaClient(
	https://some-sites.xyz, //Your Kastela URL
	https://some-other-sites.xyz, //Your Server URL
);
```

## Usage
Retrieving `Secure Channel Token`

```dart  
SecureChannelToken secureChannel = await client.secureChannelSend(
	id,
	data
);
```