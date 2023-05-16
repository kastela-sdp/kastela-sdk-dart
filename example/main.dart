import 'package:dio/dio.dart';
import 'package:dio/src/response.dart' as DioResponse;
import 'package:kastela_sdk_dart/secure_protection_token.dart';
import 'package:kastela_sdk_dart/kastela_sdk_dart.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:kastela_sdk_dart/secure_protection_values.dart';
import 'package:kastela_sdk_dart/secure_vault_token.dart';
import 'package:kastela_sdk_dart/secure_vault_values.dart';

String _kastelaUrl = "http://127.0.0.1:3201";
String _backendUrl = "http://127.0.0.1:4000";
KastelaClient kasClient = KastelaClient(_kastelaUrl);

void main() async {
  List<Map<String, dynamic>> protectionList = [
    {
      "id": "5f77f9c2-2800-4661-b479-a0791aa0eacc",
      "data": ["example@company.com"],
    },
    {
      "id": "6980a205-db7a-4b8e-bfce-551709034cc3",
      "data": ["Indonesia"],
    },
    {
      "id": "963d8305-f68c-4f9a-b6b4-d568fc3d8f78",
      "data": ["1234567890123456"],
    },
    {
      "id": "0c392d3c-4ec0-4e11-a5bc-d6e094c21ea0",
      "data": ["123-456-7890"],
    },
  ];

  List<Map<String, dynamic>> vaultList = [
    {
      "id": "b64e2268-fca6-4605-8b5a-307a315b266d",
      "data": ["1945-08-17"],
    }
  ];

  int id = 19067;

  void _store() async {
    DioResponse.Response credentialRes = await Dio().post(
        "$_backendUrl/api/secure/protection/init",
        data: {
          "operation": "WRITE",
          "protection_ids":
          protectionList.map((protection) => protection["id"]).toList(),
          "ttl": 1,
        });
    dynamic protectionCredential = credentialRes.data["credential"];
    SecureProtectionToken protectionToken =
    await kasClient.secureProtectionSend(
        protectionCredential,
        protectionList
            .map((protection) => protection["data"] as List<dynamic>)
            .toList());

    DioResponse.Response vaultRes = await Dio().post(
        "$_backendUrl/api/secure/vault/init",
        data: {
          "operation": "WRITE",
          "vault_ids": vaultList.map((vault) => vault["id"]).toList(),
          "ttl": 1,
        });
    dynamic vaultCredential = vaultRes.data["credential"];

    SecureVaultToken vaultToken = await kasClient.secureVaultSend(
      vaultCredential,
      vaultList.map((vault) => vault["data"] as List<dynamic>).toList(),
    );

    GraphQLClient gqlClient = GraphQLClient(
        link: HttpLink("$_backendUrl/graphql"),
        cache: GraphQLCache());

    String mutationGql = r"""
      mutation storeUserSecure($data: UserStoreInput!, $credential: String!) {
      store_user_secure(data: $data, credential: $credential)
     }""";

    MutationOptions options = MutationOptions(
        document: gql(mutationGql),
        variables: <String, dynamic>{
          "data": {
            "id": id,
            "name": "Dendy Test SDK",
            "email": protectionToken.tokens[0][0],
            "country": protectionToken.tokens[1][0],
            "credit_card": protectionToken.tokens[2][0],
            "phone": protectionToken.tokens[3][0],
            "birthdate": vaultToken.tokens[0][0],
          },
          "credential": protectionCredential
        });

    await gqlClient.mutate(options);
    print("============ STORE OK! ============");
  }

  void _update() async {
    DioResponse.Response credentialRes = await Dio().post(
        "$_backendUrl/api/secure/protection/init",
        data: {
          "operation": "WRITE",
          "protection_ids": [protectionList[0]["id"]].toList(),
          "ttl": 1,
        });
    dynamic protectionCredential = credentialRes.data["credential"];
    SecureProtectionToken protectionToken =
    await kasClient.secureProtectionSend(protectionCredential, [
      ["example-update@company.com"]
    ]);

    DioResponse.Response vaultRes = await Dio().post(
        "$_backendUrl/api/secure/vault/init",
        data: {
          "operation": "WRITE",
          "vault_ids": [vaultList[0]["id"]].toList(),
          "ttl": 1,
        });
    dynamic vaultCredential = vaultRes.data["credential"];

    SecureVaultToken vaultToken = await kasClient.secureVaultSend(
      vaultCredential,
      [
        ["2009-09-09"]
      ],
    );

    GraphQLClient gqlClient = GraphQLClient(
        link: HttpLink("$_backendUrl/graphql"),
        cache: GraphQLCache());

    String mutationGql = r"""
      mutation updateUserSecure($data: UserUpdateInput!, $id: Int!, $credential: String!) {
      update_user_secure(id: $id, data: $data, credential: $credential)
     }""";

    MutationOptions options = MutationOptions(
        document: gql(mutationGql),
        variables: <String, dynamic>{
          "id": id,
          "data": {
            "email": protectionToken.tokens[0][0],
            "birthdate": vaultToken.tokens[0][0],
          },
          "credential": protectionCredential
        });

    await gqlClient.mutate(options);
    print("============ UPDATE OK! ============");
  }

  void _get() async {
    GraphQLClient gqlClient = GraphQLClient(
        link: HttpLink("$_backendUrl/graphql"),
        cache: GraphQLCache());

    String mutationGql = r"""
      query getUserSecure($id: Int!) {
      get_user_secure(id: $id) {
        id
        email
        country
        credit_card
        phone
        birthdate
      }
     }""";

    QueryOptions options =
    QueryOptions(document: gql(mutationGql), variables: <String, dynamic>{
      "id": id,
    });
    QueryResult res = await gqlClient.query(options);

    dynamic queryData = res.data?["get_user_secure"];

    if(queryData != null) {
      DioResponse.Response credentialRes = await Dio().post(
          "$_backendUrl/api/secure/protection/init",
          data: {
            "operation": "READ",
            "protection_ids":
            protectionList.map((protection) => protection["id"]).toList(),
            "ttl": 1,
          });

      dynamic protectionCredential = credentialRes.data["credential"];

      List<List<String>> protectionTokens = [
        [queryData["email"]],
        [queryData["country"]],
        [queryData["credit_card"]],
        [queryData["phone"]]
      ];

      SecureProtectionValues protectionValues = await kasClient.secureProtectionReceive(protectionCredential, protectionTokens);

      print("============ BEGIN GET PROTECTION ============");
      print("email : ${protectionValues.values[0][0]}");
      print("country : ${protectionValues.values[1][0]}");
      print("credit card : ${protectionValues.values[2][0]}");
      print("phone : ${protectionValues.values[3][0]}");

      DioResponse.Response vaultRes = await Dio().post(
          "$_backendUrl/api/secure/vault/init",
          data: {
            "operation": "READ",
            "vault_ids": vaultList.map((vault) => vault["id"]).toList(),
            "ttl": 1,
          });
      dynamic vaultCredential = vaultRes.data["credential"];

      List<List<String>> vaultTokens = [[queryData["birthdate"]]];

      SecureVaultValues vaultValues = await kasClient.secureVaultReceive(vaultCredential, vaultTokens);

      print("============ BEGIN GET VAULT ============");
      print("birthdate: ${vaultValues.values[0][0]}");
    } else {
      print("DATA IS NULL");
    }
  }

  void exec() async {
    _store();
    _get();
    _update();
    _get();
  }
}
