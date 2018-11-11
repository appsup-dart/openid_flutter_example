import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:openid_client/openid_client.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:openid_client/openid_client_io.dart';

class Storage {
  final SharedPreferences _prefs;

  final Map<String, BehaviorSubject<dynamic>> _subjects = {};

  Storage(this._prefs);

  static Future<Storage> _instance = new Future(() async {
    return new Storage(await SharedPreferences.getInstance());
  });
  static Future<Storage> getInstance() => _instance;

  void set(String key, dynamic value) {
    var s = json.encode(value);
    _prefs.setString(key, s);
    _subjects[key]?.add(value);
  }

  dynamic _get(String key) {
    try {
      var s = _prefs.getString(key);
      return s == null ? null : json.decode(s);
    } catch (e) {
      return null;
    }
  }

  void update(String key, dynamic updater(dynamic value)) {
    set(key, updater(_get(key)));
  }

  BehaviorSubject<dynamic> get(String key, [dynamic seedValue]) {
    return _subjects.putIfAbsent(key, () {
      return new BehaviorSubject()..add(_get(key) ?? seedValue);
    });
  }
}

class OpenIdStore {
  final Storage _storage;

  OpenIdStore(this._storage) {
//    _storage._prefs.clear();
    _storage.update(
        "issuers",
        (l) => l is List
            ? l
            : Issuer.knownIssuers.map((v) => v.toString()).toList());
  }

  Stream<Iterable<Uri>> getIssuers() {
    return _storage
        .get("issuers", [])
        .stream
        .map((l) => l.map<Uri>((v) => Uri.parse(v)));
  }

  Future<void> addIssuer(String issuer) async {
    var uri = Uri.parse(issuer);
    await Issuer.discover(uri);
    _storage.update("issuers", (l) => (l ?? [])..add(issuer));
  }

  Future<void> removeIssuer(String issuer) async =>
      _storage.update("issuers", (l) => (l ?? [])..remove(issuer));

  Map<String, dynamic> createClient(Uri issuer) {
    var r = new Random(new DateTime.now().millisecondsSinceEpoch);
    var chars = "0123456789abcdefghijklmnopqrstuvwxyz";
    var id =
        new Iterable.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
    return {
      "id": id,
      "issuer": issuer.toString(),
      "client_id": "",
      "client_secret": "",
      "redirect_uri": null,
      "name": "Client $id",
      "scopes": ""
    };
  }

  Map<String, BehaviorSubject<Iterable<Map<String, dynamic>>>> _clientsStreams =
      {};

  Stream<Iterable<Map<String, dynamic>>> getClients(Uri issuer) {
    var key = "clients:$issuer";
    return _clientsStreams.putIfAbsent(key, () {
      var s = new BehaviorSubject<Iterable<Map<String, dynamic>>>();
      s.addStream(_storage.get(key, []).stream.map((l) {
            if (l is! Map) return [];

            return (l as Map).values.whereType<Map>().cast();
          }));
      return s;
    }).stream;
  }

  Future<void> storeClient(Map<String, dynamic> client) async {
    var issuer = client["issuer"];
    _storage.update("clients:$issuer", (m) {
      return (m ?? {})..[client["id"]] = client;
    });
  }

  Future<void> removeClient(Map<String, dynamic> client) async {
    var issuer = client["issuer"];
    _storage.update("clients:$issuer", (m) {
      return (m ?? {})..remove(client["id"]);
    });
  }

  Future<void> signOff(Map<String, dynamic> clientInfo) async {
    _storage.set("token_response:${clientInfo["id"]}", {});
  }

  Future<UserInfo> signIn(Map<String, dynamic> clientInfo) async {
    var uri = Uri.parse(clientInfo["issuer"]);
    var issuer = await Issuer.discover(uri);
    var client = new Client(
      issuer,
      clientInfo["client_id"],
    );
    var authenticator = new Authenticator(client,
        scopes: clientInfo["scopes"].split(","),
        redirectUri: clientInfo["redirect_uri"] == null
            ? null
            : Uri.parse(clientInfo["redirect_uri"]),
        port: 4000, urlLancher: (url) async {
      if (await canLaunch(url)) {
        await launch(url, forceWebView: true);
      } else {
        throw 'Could not launch $url';
      }
    });
    var c = await authenticator.authorize();
    closeWebView();
    _storage.set("token:${clientInfo["id"]}", c.refreshToken);
    _storage.set("token_response:${clientInfo["id"]}", c.response);
    return _userFromCredential(c);
  }

  Future<UserInfo> _userFromCredential(Credential c) async {
    if (c.refreshToken != null) return await c.getUserInfo();

    return _userFromResponse(c.response);
  }

  UserInfo _userFromResponse(Map<String, dynamic> response) =>
      new UserInfo.fromJson({
        "given_name": "",
        "family_name": "",
        "email": json.encode(response)
      });

  final Map<String, BehaviorSubject<UserInfo>> _currentUsers = {};

  Stream<UserInfo> currentUser(Map<String, dynamic> clientInfo) {
    var key = "token_response:${clientInfo["id"]}";

    return _currentUsers.putIfAbsent(key, () {
      var s = new BehaviorSubject<UserInfo>();
      s.addStream(_storage.get(key, {}).cast<Map>().asyncMap((t) async {
            if (t.isEmpty) return null;
            if (t["refresh_token"] != null) {
              var uri = Uri.parse(clientInfo["issuer"]);
              var issuer = await Issuer.discover(uri);
              var client = new Client(
                issuer,
                clientInfo["client_id"],
              );

              var c = client.createCredential(refreshToken: t["refresh_token"]);
              return await c.getUserInfo();
            } else {
              return _userFromResponse(t);
            }
          }));
      return s;
    }).stream;
  }
}

OpenIdStore openIdStore;

Future<void> init() async {
  openIdStore = new OpenIdStore(await Storage.getInstance());
}
