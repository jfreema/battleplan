import 'package:cloud_functions/cloud_functions.dart';

/// Answers a callable: return its data, or throw a
/// [FirebaseFunctionsException] to fail it.
typedef CallableHandler = Object? Function(Object? data);

/// A [FirebaseFunctions] for data-layer tests (SPEC §8.1): records every
/// call and answers from [handlers].
class FakeFunctions implements FirebaseFunctions {
  new([Map<String, CallableHandler>? handlers]) : handlers = handlers ?? {};

  final Map<String, CallableHandler> handlers;

  /// Every call, in order: the callable's name and the data sent.
  final calls = <(String, Object?)>[];

  /// The data of the last call to [name].
  Object? lastData(String name) => calls.lastWhere((c) => c.$1 == name).$2;

  /// Makes [name] fail with [code].
  void fail(String name, String code, [String message = 'refused']) =>
      handlers[name] = (_) =>
          throw FirebaseFunctionsException(code: code, message: message);

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _FakeCallable(this, name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCallable implements HttpsCallable {
  new(this._functions, this._name);

  final FakeFunctions _functions;
  final String _name;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _functions.calls.add((_name, parameters));
    final handler = _functions.handlers[_name];
    // Unanswered: null, or an empty map where the caller needs one.
    final data = handler != null
        ? handler(parameters)
        : (null is T ? null : <String, dynamic>{});
    return _FakeResult<T>(data as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResult<T> implements HttpsCallableResult<T> {
  new(this.data);

  @override
  final T data;
}
