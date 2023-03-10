library flutter_kastela_pkg;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kastela_sdk_dart/SecureChannelToken.dart';
import 'package:pinenacl/x25519.dart';
import 'package:pinenacl/tweetnacl.dart';

String _expectedVersion = "v0.3";
String _secureChannelPath = "api/secure/protection";

class KastelaClient {
  late String _kastelaUrl;

  //CONSTRUCTOR
  KastelaClient(String kastelaUrl) {
    _kastelaUrl = kastelaUrl;
  }

  Future<dynamic> _request(String method, String url, dynamic body) async {
    try {
      Dio dioInstance = Dio(BaseOptions(
        method: method,
        headers: {
          Headers.acceptHeader: "application/json, text/plain, */*",
        },
      ));

      Response response = await dioInstance.request(
        url,
        data: body,
      );
      Headers responseHeaders = response.headers;
      String? actualKastelaVersion = responseHeaders.value("x-kastela-version");
      if (actualKastelaVersion != null) {
        List<String> expectedSplitted =
            _expectedVersion.substring(1).split(".");
        List<String> actualSplitted =
            actualKastelaVersion.substring(1).split(".");
        int actualMajor = int.parse(actualSplitted[0]);
        int actualMinor = int.parse(actualSplitted[1]);
        int expectedMajor = int.parse(expectedSplitted[0]);
        int expectedMinor = int.parse(expectedSplitted[1]);

        if ((expectedMajor == actualMajor && expectedMinor == actualMinor) ||
            actualKastelaVersion == "v0.0.0") {
          return response.data;
        }
      }

      throw ("Kastela server version mismatch. Expected: $_expectedVersion.x, actual: $actualKastelaVersion");
    } on DioError catch (error) {
      if (error.response!.data != null) {
        throw (error.response!.data.toString());
      }
      rethrow;
    }
  }

  String _generateCipherText(String dataToCipher, PrivateKey clientPrivateKey,
      PublicKey serverPublicKey) {
    Uint8List plainText = Uint8List.fromList(dataToCipher.toString().codeUnits);
    Uint8List nonce = PineNaClUtils.randombytes(TweetNaCl.nonceLength);
    EncryptedMessage cipherText =
        Box(myPrivateKey: clientPrivateKey, theirPublicKey: serverPublicKey)
            .encrypt(plainText, nonce: nonce);
    return base64Encode(cipherText);
  }

  Future<SecureChannelToken> secureChannelSend(
      String credential, List<List<dynamic>> data) async {
    try {
      PrivateKey clientPrivateKey = PrivateKey.generate();
      PublicKey clientPublicKey = clientPrivateKey.publicKey;

      Map<String, dynamic> beginRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureChannelPath/begin",
        {
          "credential": credential,
          "client_public_key": base64Encode(clientPublicKey)
        },
      );

      PublicKey serverPubKey =
          PublicKey(base64Decode(beginRes["server_public_key"]));

      List<List<String>> fullTexts = data
          .map((protectionsDatas) => protectionsDatas
              .map((val) =>
                  _generateCipherText(val, clientPrivateKey, serverPubKey))
              .toList())
          .toList();

      dynamic sendRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureChannelPath/insert",
        {"credential": credential, "data": fullTexts},
      );

      List<dynamic> tokens = sendRes!["tokens"]
          .map((token) => token.map((value) => value as String).toList())
          .toList();

      return SecureChannelToken(tokens);
    } on DioError catch (err) {
      if (err.response?.data != null) {
        var data = err.response!.data;
        throw (data.toString());
      }
      rethrow;
    }
  }
}
