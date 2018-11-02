import 'package:flutter/material.dart';
import 'issuer_metadata.dart';
import 'client_details.dart';
import 'client_list.dart';
import '../blocs.dart';

class IssuerPage extends StatefulWidget {
  final Uri issuerUri;

  IssuerPage(this.issuerUri);

  @override
  State<StatefulWidget> createState() => new _IssuerPageState();
}

class _IssuerPageState extends State<IssuerPage> {
  Widget _fab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Builder(builder: (context) {
          DefaultTabController.of(context).addListener(() => setState(() {}));
          var index = DefaultTabController.of(context).index;
          _fab ??= FloatingActionButton(
            onPressed: () async {
              var client = openIdStore.createClient(widget.issuerUri);
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return new ClientDetailsWidget(clientDetails: client);
              }));
            },
            tooltip: 'Add client',
            child: Icon(Icons.add),
          );
          var fab = index == 1 ? null : _fab;
          return Scaffold(
              appBar: AppBar(
                  // Here we take the value from the MyHomePage object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text(widget.issuerUri.toString()),
                  bottom: TabBar(
                    tabs: [
                      Tab(text: "clients"),
                      Tab(text: "metadata"),
                    ],
                  ),
                  actions: [
                    FlatButton(
                      child: Text("DELETE"),
                      onPressed: () {
                        openIdStore.removeIssuer(widget.issuerUri.toString());
                        Navigator.pop(context);
                      },
                    )
                  ]),
              body: TabBarView(
                children: [
                  new ClientListWidget(
                    issuerUri: widget.issuerUri,
                  ),
                  new IssuerMetadataWidget(issuerUri: widget.issuerUri),
                ],
              ),
              floatingActionButton: fab);
        }));
  }
}
