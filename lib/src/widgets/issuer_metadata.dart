import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'loading.dart';

class IssuerMetadataWidget extends StatelessWidget {
  const IssuerMetadataWidget({
    Key key,
    @required this.issuerUri,
  }) : super(key: key);

  final Uri issuerUri;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      FutureBuilder<Issuer>(
        future: Issuer.discover(issuerUri),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LoadingWidget();
          var issuer = snapshot.data;
          var metadata = issuer.metadata;
          return ExpansionPanelList(
            children: [
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Endpoints");
                  },
                  isExpanded: true,
                  body: new Column(children: [
                    Text("authorization: ${metadata.authorizationEndpoint}"),
                    Text("registration: ${metadata.registrationEndpoint}"),
                    Text("token: ${metadata.tokenEndpoint}"),
                    Text("userinfo: ${metadata.userinfoEndpoint}")
                  ])),
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Response types supported");
                  },
                  isExpanded: true,
                  body: new Column(
                    children: (issuer.metadata.responseTypesSupported ?? [])
                        .map((v) => Text(v))
                        .toList(),
                  )),
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Grant types supported");
                  },
                  isExpanded: true,
                  body: new Column(
                    children: (issuer.metadata.grantTypesSupported ?? [])
                        .map((v) => Text(v))
                        .toList(),
                  )),
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Claim types supported");
                  },
                  isExpanded: true,
                  body: new Column(
                    children: (issuer.metadata.claimTypesSupported ?? [])
                        .map((v) => Text(v))
                        .toList(),
                  )),
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Claims supported");
                  },
                  isExpanded: true,
                  body: new Column(
                    children: (issuer.metadata.claimsSupported ?? [])
                        .map((v) => Text(v))
                        .toList(),
                  )),
              ExpansionPanel(
                  headerBuilder: (context, expanded) {
                    return Text("Scopes supported");
                  },
                  isExpanded: true,
                  body: new Column(
                    children: issuer.metadata.scopesSupported
                        .map((v) => Text(v))
                        .toList(),
                  )),
            ],
          );
        },
      )
    ]);
  }
}
