import 'package:flutter/material.dart' hide Flow;
import 'client_details.dart';
import 'loading.dart';
import 'package:openid_client/openid_client.dart';
import '../blocs.dart';

class ClientListWidget extends StatelessWidget {
  final Uri issuerUri;

  const ClientListWidget({Key key, @required this.issuerUri}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new LoadingStreamBuilder<Iterable<Map<String, dynamic>>>(
        stream: openIdStore.getClients(issuerUri),
        builder: (context, snapshot) {
          var clients = snapshot.data;
          return ListView(
              children: clients.map((c) {
            return new ClientCard(clientInfo: c);
          }).toList());
        });
  }
}

class ClientCard extends StatelessWidget {
  ClientCard({
    Key key,
    @required this.clientInfo,
  }) : super(key: key);

  final Map<String, dynamic> clientInfo;

  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(clientInfo["issuer"]);
    return Card(
        margin: EdgeInsets.all(8),
        child: InkWell(
            onTap: () {},
            child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(children: [
                  ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(uri.resolve("favicon.ico").toString()),
                      ),
                      trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return new ClientDetailsWidget(
                                  clientDetails: clientInfo);
                            }));
                          }),
                      title: Text(
                        clientInfo["name"],
                      ),
                      subtitle: Text(
                        clientInfo["client_id"],
                        overflow: TextOverflow.fade,
                      )),
                  StreamBuilder<UserInfo>(
                      stream: openIdStore.currentUser(clientInfo),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) {
                          return MaterialButton(
                            child: Text("LOGIN"),
                            onPressed: () async {
                              try {
                                var user = await openIdStore.signIn(clientInfo);
                                Scaffold.of(context).showSnackBar(SnackBar(
                                    content:
                                        Text('Welcome ${user.givenName}')));
                              } catch (e) {
                                Scaffold.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            },
                          );
                        }
                        var user = snapshot.data;
                        return Container(
                            decoration: BoxDecoration(color: Color(0xFFCCCCCC)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(user.picture?.toString()),
                              ),
                              title:
                                  Text("${user.givenName} ${user.familyName}"),
                              subtitle: Text("${user.email}"),
                              trailing: IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    openIdStore.signOff(clientInfo);
                                  }),
                            ));
                      })
                ]))));
  }
}
