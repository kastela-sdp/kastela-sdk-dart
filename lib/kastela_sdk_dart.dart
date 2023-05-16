library flutter_kastela_pkg;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kastela_sdk_dart/secure_protection_token.dart';
import 'package:kastela_sdk_dart/secure_protection_values.dart';
import 'package:kastela_sdk_dart/secure_vault_token.dart';
import 'package:kastela_sdk_dart/secure_vault_values.dart';
import 'package:pinenacl/x25519.dart';
import 'package:pinenacl/tweetnacl.dart';

String _secureProtectionPath = "api/secure/protection";
String _secureVaultPath = "api/secure/vault";

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

  String _generateCipherText(dynamic dataToCipher, PrivateKey clientPrivateKey,
      PublicKey serverPublicKey) {
    Uint8List finalPlainText =
        Uint8List.fromList(jsonEncode(dataToCipher).codeUnits);
    Uint8List nonce = PineNaClUtils.randombytes(TweetNaCl.nonceLength);
    EncryptedMessage cipherText =
        Box(myPrivateKey: clientPrivateKey, theirPublicKey: serverPublicKey)
            .encrypt(finalPlainText, nonce: nonce);
    return base64Encode(cipherText);
  }

  dynamic _generatePlainText(
      String data, PrivateKey clientPrivateKey, PublicKey serverPublicKey) {
    Uint8List fulltext = base64Decode(data);
    Uint8List nonce = fulltext.sublist(0, TweetNaCl.nonceLength);
    Uint8List cipherText = fulltext.sublist(TweetNaCl.nonceLength);
    Uint8List plainText =
        Box(myPrivateKey: clientPrivateKey, theirPublicKey: serverPublicKey)
            .decrypt(ByteList(cipherText), nonce: nonce);

    if (plainText.isEmpty) {
      throw ("Decryption failed");
    }

    return jsonDecode(utf8.decode(plainText));
  }

  Future<SecureProtectionToken> secureProtectionSend(
      String credential, List<List<dynamic>> data) async {
    try {
      PrivateKey clientPrivateKey = PrivateKey.generate();
      PublicKey clientPublicKey = clientPrivateKey.publicKey;

      Map<String, dynamic> beginRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureProtectionPath/begin",
        {
          "credential": credential,
          "client_public_key": base64Encode(clientPublicKey)
        },
      );

      PublicKey serverPubKey =
          PublicKey(base64Decode(beginRes["server_public_key"]));

      List<List<dynamic>> fullTexts = data
          .map((protectionsDatas) => protectionsDatas
              .map((val) =>
                  _generateCipherText(val, clientPrivateKey, serverPubKey))
              .toList())
          .toList();

      dynamic sendRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureProtectionPath/store",
        {"credential": credential, "values": fullTexts},
      );

      List<List<dynamic>> finalTokens = (sendRes!["tokens"] as List)
          .map((e) => (e as List).map((v) => v.toString()).toList())
          .toList();

      return SecureProtectionToken(finalTokens);
    } on DioError catch (err) {
      if (err.response?.data != null) {
        var data = err.response!.data;
        throw (data.toString());
      }
      rethrow;
    }
  }

  Future<SecureProtectionValues> secureProtectionReceive(
      String credential, List<List<String>> tokens) async {
    try {
      PrivateKey clientPrivateKey = PrivateKey.generate();
      PublicKey clientPublicKey = clientPrivateKey.publicKey;

      Map<String, dynamic> beginRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureProtectionPath/begin",
        {
          "credential": credential,
          "client_public_key": base64Encode(clientPublicKey)
        },
      );

      PublicKey serverPubKey =
          PublicKey(base64Decode(beginRes["server_public_key"]));

      dynamic protectionPayload = {"credential": credential, "tokens": tokens};

      dynamic protectionRes = await _request("POST",
          "$_kastelaUrl/$_secureProtectionPath/fetch", protectionPayload);

      List<List<dynamic>> values = (protectionRes!["values"] as List)
          .map((value) => (value as List)
              .map((rv) =>
                  _generatePlainText(rv, clientPrivateKey, serverPubKey))
              .toList())
          .toList();

      return SecureProtectionValues(values);
    } on DioError catch (err) {
      if (err.response?.data != null) {
        var data = err.response!.data;
        throw (data.toString());
      }
      rethrow;
    }
  }

  Future<SecureVaultToken> secureVaultSend(
      String credential, List<List<dynamic>> data) async {
    try {
      PrivateKey clientPrivateKey = PrivateKey.generate();
      PublicKey clientPublicKey = clientPrivateKey.publicKey;

      Map<String, dynamic> beginRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureVaultPath/begin",
        {
          "credential": credential,
          "client_public_key": base64Encode(clientPublicKey)
        },
      );

      PublicKey serverPubKey =
          PublicKey(base64Decode(beginRes["server_public_key"]));

      List<List<dynamic>> fullTexts = data
          .map((protectionsDatas) => protectionsDatas
              .map((val) =>
                  _generateCipherText(val, clientPrivateKey, serverPubKey))
              .toList())
          .toList();

      dynamic sendRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureVaultPath/store",
        {"credential": credential, "values": fullTexts},
      );

      List<List<dynamic>> tokens = (sendRes!["tokens"] as List)
          .map((token) =>
              (token as List).map((value) => value.toString()).toList())
          .toList();

      return SecureVaultToken(tokens);
    } on DioError catch (err) {
      if (err.response?.data != null) {
        var data = err.response!.data;
        throw (data.toString());
      }
      rethrow;
    }
  }

  Future<SecureVaultValues> secureVaultReceive(
      String credential, List<List<String>> tokens) async {
    try {
      PrivateKey clientPrivateKey = PrivateKey.generate();
      PublicKey clientPublicKey = clientPrivateKey.publicKey;

      Map<String, dynamic> beginRes = await _request(
        "POST",
        "$_kastelaUrl/$_secureVaultPath/begin",
        {
          "credential": credential,
          "client_public_key": base64Encode(clientPublicKey)
        },
      );

      PublicKey serverPubKey =
          PublicKey(base64Decode(beginRes["server_public_key"]));

      dynamic vaultPayload = {"credential": credential, "tokens": tokens};

      dynamic vaultRes = await _request("POST",
          "$_kastelaUrl/$_secureVaultPath/fetch", vaultPayload);

      List<List<dynamic>> values = (vaultRes!["values"] as List)
          .map((value) => (value as List)
              .map((rv) =>
                  _generatePlainText(rv, clientPrivateKey, serverPubKey))
              .toList())
          .toList();

      return SecureVaultValues(values);
    } on DioError catch (err) {
      if (err.response?.data != null) {
        var data = err.response!.data;
        throw (data.toString());
      }
      rethrow;
    }
  }
}
