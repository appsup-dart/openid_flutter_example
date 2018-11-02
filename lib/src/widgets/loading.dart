import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }
}

class LoadingStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T initialData;
  final AsyncWidgetBuilder<T> builder;

  const LoadingStreamBuilder(
      {Key key, this.initialData, this.stream, @required this.builder})
      : assert(builder != null),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: key,
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return new LoadingWidget();
        return builder(context, snapshot);
      },
      initialData: initialData,
    );
  }
}
