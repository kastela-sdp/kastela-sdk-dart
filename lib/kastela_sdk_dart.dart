library flutter_kastela_pkg;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kastela_sdk_dart/secure_channel_token.dart';
import 'package:pinenacl/x25519.dart';
import 'package:pinenacl/tweetnacl.dart';

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

      return response.data;
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
