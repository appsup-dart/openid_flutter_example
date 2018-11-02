import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import '../blocs.dart';
import 'loading.dart';

class ClientDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> clientDetails;
  ClientDetailsWidget({@required this.clientDetails})
      : super(key: Key("Client-${clientDetails["id"]}"));

  @override
  State<StatefulWidget> createState() => new _ClientDetailsWidgetState();
}

class _ClientDetailsWidgetState extends State<ClientDetailsWidget> {
  final Map<String, TextEditingController> controllers = {};

  _ClientDetailsWidgetState();

  @override
  void initState() {
    var c = widget.clientDetails;
    c.forEach((k, v) {
      if (v is! String) return;
      controllers[k] ??= TextEditingController();
      controllers[k].text = v;
    });
    super.initState();
  }

  Map<String, dynamic> get data {
    var c = widget.clientDetails;
    controllers.forEach((k, v) {
      c[k] = v.text;
    });
    return c;
  }

  Widget _form;

  @override
  Widget build(BuildContext context) {
    return _form ??= Scaffold(
        key: GlobalKey<ScaffoldState>(),
        appBar: AppBar(actions: [
          FlatButton(
            child: Text("SAVE"),
            onPressed: () async {
              await openIdStore.storeClient(data);
              Navigator.pop(context);
            },
          ),
          FlatButton(
            child: Text("DELETE"),
            onPressed: () async {
              await openIdStore.removeClient(data);
              Navigator.pop(context);
            },
          )
        ], title: Text("Edit client")),
        body: FutureBuilder<Issuer>(
            future: Issuer.discover(Uri.parse(widget.clientDetails["issuer"])),
            builder: (context, snapshot) {
              var issuer = snapshot.data;
              if (issuer == null) return LoadingWidget();
              return Form(
                  autovalidate: true,
                  child: ListView(children: [
                    TextFormField(
                      controller: controllers["name"],
                      decoration: InputDecoration(labelText: "name"),
                    ),
                    TextFormField(
                      controller: controllers["issuer"],
                      enabled: false,
                      decoration: InputDecoration(labelText: "issuer"),
                    ),
                    TextFormField(
                      controller: controllers["client_id"],
                      validator: (v) {
                        if (v.isEmpty) return "client id is required";
                      },
                      decoration: InputDecoration(labelText: "client id"),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controllers["scopes"],
                        builder: (context, scopes, widget) {
                          var selectedScopes = scopes.text
                              .split(",")
                              .where((s) => s.isNotEmpty)
                              .toSet();
                          return Column(
                              children:
                                  issuer.metadata.scopesSupported.map((s) {
                            return CheckboxListTile(
                              title: Text(s),
                              value: selectedScopes.contains(s),
                              onChanged: (v) {
                                if (v)
                                  selectedScopes.add(s);
                                else
                                  selectedScopes.remove(s);
                                controllers["scopes"].text =
                                    selectedScopes.join(",");
                              },
                            );
                          }).toList());
                        })
                  ]));
            }));
  }
}
