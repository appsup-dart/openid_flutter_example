import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'issuer_page.dart';
import 'loading.dart';
import '../blocs.dart';

class IssuerListWidget extends StatelessWidget {
  IssuerListWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      appBar: AppBar(
        title: Text("OpenID issuers"),
      ),
      body: LoadingStreamBuilder<Iterable<Uri>>(
          stream: openIdStore.getIssuers(),
          builder: (context, snapshot) => ListView(
                  children: snapshot.data.map((uri) {
                return new IssuerCard(
                  issuerUri: uri,
                );
              }).toList())),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog<Uri>(
              context: context,
              builder: (BuildContext context) {
                return new AddIssuerDialog();
              });
        },
        tooltip: 'Add issuer',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddIssuerDialog extends StatefulWidget {
  AddIssuerDialog({
    Key key,
  }) : super(key: Key("add-issuer"));

  @override
  State<StatefulWidget> createState() => new _AddIssuerDialogState();
}

class _AddIssuerDialogState extends State<AddIssuerDialog> {
  final TextEditingController controller =
      new TextEditingController(text: "https://");

  String error;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('New issuer'),
      children: <Widget>[
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(errorText: error),
        ),
        MaterialButton(
          onPressed: () async {
            try {
              await openIdStore.addIssuer(controller.text);
              Navigator.pop(context);
            } catch (e) {
              setState(() {
                error = "$e";
              });
            }
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

class IssuerCard extends StatelessWidget {
  final Uri issuerUri;

  const IssuerCard({Key key, @required this.issuerUri}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.all(8),
        child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return IssuerPage(issuerUri);
              }));
            },
            child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Image.network(issuerUri.resolve("favicon.ico").toString(),
                        width: 64, height: 64),
                    Text(issuerUri.toString())
                  ],
                ))));
  }
}
