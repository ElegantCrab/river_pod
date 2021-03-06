import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Using the package `Freezed` to create our [Configuration] class.
///
/// This is not needed, but reduce the boilerplate.
@freezed
abstract class Configuration with _$Configuration {
  @JsonSerializable(fieldRename: FieldRename.snake)
  factory Configuration({
    @required String publicKey,
    @required String privateKey,
  }) = _Configuration;

  factory Configuration.fromJson(Map<String, dynamic> json) =>
      _$ConfigurationFromJson(json);
}

class Repository {
  Repository(this._configuration);

  final Configuration _configuration;
  final _client = Dio();

  Future<List<Comic>> fetchComics() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = md5
        .convert(utf8.encode(
          '$timestamp${_configuration.privateKey}${_configuration.publicKey}',
        ))
        .toString();

    final result = await _client.get<Map<String, dynamic>>(
      'http://gateway.marvel.com/v1/public/comics',
      queryParameters: <String, dynamic>{
        'ts': timestamp,
        'apikey': _configuration.publicKey,
        'hash': hash,
      },
    );
    final response = MarvelResponse.fromJson(result.data);

    return response //
        .data
        .results
        .map((e) => Comic.fromJson(e))
        .toList();
  }

  void dispose() {
    _client.close(force: true);
  }
}

@freezed
abstract class MarvelResponse with _$MarvelResponse {
  factory MarvelResponse(MarvelData data) = _MarvelResponse;

  factory MarvelResponse.fromJson(Map<String, dynamic> json) =>
      _$MarvelResponseFromJson(json);
}

@freezed
abstract class MarvelData with _$MarvelData {
  factory MarvelData(
    List<Map<String, dynamic>> results,
  ) = _MarvelData;

  factory MarvelData.fromJson(Map<String, dynamic> json) =>
      _$MarvelDataFromJson(json);
}

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    @required int id,
    @required String title,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}
