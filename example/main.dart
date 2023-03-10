import 'package:dio/dio.dart';
import 'package:dio/src/response.dart' as DioResponse;
import 'package:kastela_sdk_dart/secure_channel_token.dart';
import 'package:kastela_sdk_dart/kastela_sdk_dart.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

String _kastelaUrl = "http://127.0.0.1:3201";
String _backendUrl = "http://127.0.0.1:4000";
KastelaClient kasClient = KastelaClient(_kastelaUrl);

void main() async {
  List<Map<String, dynamic>> protectionList = [
    {
      "id": "5f77f9c2-2800-4661-b479-a0791aa0eacc",
      "data": ["example@mail.id"],
    },
    {
      "id": "6980a205-db7a-4b8e-bfce-551709034cc3",
      "data": ["INDONESIA"],
    },
    {
      "id": "963d8305-f68c-4f9a-b6b4-d568fc3d8f78",
      "data": ["1234123412341234"],
    },
    {
      "id": "0c392d3c-4ec0-4e11-a5bc-d6e094c21ea0",
      "data": ["123-456-7890"],
    },
  ];

  DioResponse.Response credRes =
      await Dio().post("$_backendUrl/api/secure/protection/init", data: {
    "operation": "WRITE",
    "protection_ids": protectionList.map((value) => value["id"]).toList(),
    "ttl": 1,
  });

  String credential = credRes.data!["credential"];
  List<List<String>> protectionDataList = protectionList
      .map((protection) => protection["data"] as List<String>)
      .toList();

  SecureChannelToken finalTokenList =
      await kasClient.secureChannelSend(credential, protectionDataList);

  GraphQLClient gqlClient = GraphQLClient(
      link: HttpLink("$_backendUrl/graphql"), cache: GraphQLCache());

  String mutationGql = r"""
      mutation storeUserSecure($data: UserStoreInput!, $credential: String!) {
        store_user_secure(data: $data, credential: $credential)
     }""";

  MutationOptions options =
      MutationOptions(document: gql(mutationGql), variables: <String, dynamic>{
    "data": {
      "id": 999,
      "name": "John Doe",
      "email": finalTokenList.tokens[0][0],
      "country": finalTokenList.tokens[1][0],
      "credit_card": finalTokenList.tokens[2][0],
      "phone": finalTokenList.tokens[3][0],
    },
    "credential": credential
  });

  await gqlClient.mutate(options);
}
