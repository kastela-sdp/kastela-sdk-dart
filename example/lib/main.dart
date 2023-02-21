import 'package:dio/dio.dart';
import 'package:dio/src/response.dart' as DioResponse;
import 'package:flutter/material.dart';
import 'package:kastela_sdk_dart/SecureChannelToken.dart';
import 'package:kastela_sdk_dart/kastela_sdk_dart.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

String _kastelaUrl = "http://127.0.0.1:3201";
String _backendUrl = "http://127.0.0.1:4000";


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Kastela Client SDK for Dart / Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  KastelaClient kasClient =
  KastelaClient(_kastelaUrl);

  void _request() async {
    List<Map<String, String>> protectionList = [
      {
        "id": "5f77f9c2-2800-4661-b479-a0791aa0eacc",
        "data": "example@mail.id",
      },
      {
        "id": "6980a205-db7a-4b8e-bfce-551709034cc3",
        "data": "INDONESIA",
      },
      {
        "id": "963d8305-f68c-4f9a-b6b4-d568fc3d8f78",
        "data": "1234123412341234",
      },
      {
        "id": "0c392d3c-4ec0-4e11-a5bc-d6e094c21ea0",
        "data": "123-456-7890",
      },
    ];

    List<Future<SecureChannelToken>> tokenList =
    protectionList.map((protection) async {
      DioResponse.Response credRes = await Dio().post(
          "$_backendUrl/api/secure-channel/init",
          data: {
            "protection_id": protection["id"],
            "ttl": 1,
          });
      dynamic credential = credRes.data["credential"];
      return await kasClient.secureChannelSend(credential, protection["data"]);
    }).toList();

    List<SecureChannelToken> finalTokenList = await Future.wait(tokenList);

    GraphQLClient gqlClient = GraphQLClient(
        link: HttpLink("$_backendUrl/graphql"),
        cache: GraphQLCache());

    String mutationGql = r"""
      mutation storeUserSecure($data: UserStoreInput!) {
      store_user_secure(data: $data) {
        id
      }
     }""";

    MutationOptions options = MutationOptions(
        document: gql(mutationGql),
        variables: <String, dynamic>{
          "data": {
            "id": 999,
            "name": "John Doe",
            "email": finalTokenList[0].token,
            "country": finalTokenList[1].token,
            "credit_card": finalTokenList[2].token,
            "phone": finalTokenList[3].token,
          }
        });

    await gqlClient.mutate(options);

    List<Future<dynamic>> finalCommits =
    finalTokenList.map((secureChannel) async {
      return Dio().post(
        "$_backendUrl/api/secure-channel/commit",
        data: {
          "id": secureChannel.id,
        },
      );
    }).toList();

    await Future.wait(finalCommits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: _request, child: const Text("Request!"))
          ],
        ),
      ),
    );
  }
}
