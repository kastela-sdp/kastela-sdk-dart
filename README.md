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
	https://some-sites.xyz, //Your Kastela URL
);
```

## Usage
Basic implementation of `Secure Protection Send` and `Secure Vault Receive`

```dart  
SecureProtectionToken protectionToken = await client.secureChannelSend(
	credential,
	[[data]]
);

print("Token: ${protectionToken.tokens[0][0]}");

SecureVaultValues vaultValues = await client.secureVaultReceive(
    credential, 
    [[vaultTokens]]
);

print("Vault Values: ${vaultValues.values[0][0]}");
```

Please refer to the [example](https://github.com/kastela-sdp/kastela-sdk-dart/blob/master/example/main.dart) for more information about how to use the client SDK.