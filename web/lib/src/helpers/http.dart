// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import '../dom.dart';
import 'events/events.dart' show XHRGetters;

/// > [!WARNING]
/// > This class is deprecated and will be
/// > removed in a future release of `package:web`.
/// >
/// > You should instead use the cross-platform
/// > [`package:http`](https://pub.dev/packages/http) and its
/// > [`BrowserClient`](https://pub.dev/documentation/http/latest/browser_client/BrowserClient-class.html)
/// > adapter on top of [XMLHttpRequest].
///
/// A helper used to make it easier to operate over [XMLHttpRequest]s.
///
/// The logic here was copied from `dart:html` to help bridge a functionality
/// gap missing in `package:web`.
///
/// HttpRequest can be used to obtain data from HTTP and FTP protocols,
/// and is useful for AJAX-style page updates.
///
/// The simplest way to get the contents of a text file, such as a
/// JSON-formatted file, is with [getString].
/// For example, the following code gets the contents of a JSON file
/// and prints its length:
///
///     var path = 'myData.json';
///     HttpRequest.getString(path).then((String fileContents) {
///       print(fileContents.length);
///     }).catchError((error) {
///       print(error.toString());
///     });
///
/// ## Fetching data from other servers
///
/// For security reasons, browsers impose restrictions on requests
/// made by embedded apps.
/// With the default behavior of this class,
/// the code making the request must be served from the same origin
/// (domain name, port, and application layer protocol)
/// as the requested resource.
/// In the example above, the myData.json file must be co-located with the
/// app that uses it.
///
/// ## Other resources
///
/// * [Fetch data dynamically](https://dart.dev/tutorials/web/fetch-data/),
///   a tutorial shows how to load data from a static file or from a server.
/// * [JS XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest)
/// * [Using XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest_API/Using_XMLHttpRequest)
@Deprecated('Instead use package:http.')
class HttpRequest {
  // Constants are kept to match the old names used in `dart:html`
  static const int UNSENT = 0;
  static const int OPENED = 1;
  static const int HEADERS_RECEIVED = 2;
  static const int LOADING = 3;
  static const int DONE = 4;

  /// Creates a GET request for the specified [url].
  ///
  /// Similar to [request], but specialized for HTTP GET requests which return text content.
  ///
  /// Example of adding query parameters:
  ///
  ///     var name = Uri.encodeQueryComponent('John');
  ///     var id = Uri.encodeQueryComponent('42');
  ///     HttpRequest.getString('users.json?name=$name&id=$id')
  ///       .then((String resp) {
  ///         // Do something with the response.
  ///     });
  ///
  /// See also [request].
  static Future<String> getString(
    String url, {
    bool? withCredentials,
    void Function(ProgressEvent)? onProgress,
  }) async {
    final response = await request(
      url,
      withCredentials: withCredentials,
      onProgress: onProgress,
    );
    return response.responseText;
  }

  /// Makes a server POST request with the specified data encoded as form data.
  ///
  /// This is roughly the POST equivalent of [getString]. This method is similar
  /// to sending a [FormData] object with broader browser support but limited to
  /// String values.
  ///
  /// Example usage:
  ///
  ///     var data = {'firstName': 'John', 'lastName': 'Doe'};
  ///     HttpRequest.postFormData('/send', data).then((HttpRequest resp) {
  ///       // Do something with the response.
  ///     });
  ///
  /// See also [request].
  static Future<XMLHttpRequest> postFormData(
    String url,
    Map<String, String> data, {
    bool? withCredentials,
    String? responseType,
    Map<String, String>? requestHeaders,
    void Function(ProgressEvent)? onProgress,
  }) {
    final formData = data.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');

    requestHeaders ??= {};
    requestHeaders.putIfAbsent(
      'Content-Type',
      () => 'application/x-www-form-urlencoded; charset=UTF-8',
    );

    return request(
      url,
      method: 'POST',
      withCredentials: withCredentials,
      responseType: responseType,
      requestHeaders: requestHeaders,
      sendData: formData,
      onProgress: onProgress,
    );
  }

  /// Creates and sends a URL request for the specified [url].
  ///
  /// Supports various HTTP methods (`GET`, `POST`, etc.), optional headers, and data.
  ///
  /// Example usage:
  ///
  ///     var myForm = querySelector('form#myForm');
  ///     var data = FormData(myForm);
  ///     HttpRequest.request('/submit', method: 'POST', sendData: data)
  ///       .then((HttpRequest resp) {
  ///         // Do something with the response.
  ///     });
  static Future<XMLHttpRequest> request(
    String url, {
    String? method,
    bool? withCredentials,
    String? responseType,
    String? mimeType,
    Map<String, String>? requestHeaders,
    Object? sendData,
    void Function(ProgressEvent)? onProgress,
  }) {
    final completer = Completer<XMLHttpRequest>();
    final xhr = XMLHttpRequest();

    xhr.open(method ?? 'GET', url, true);

    if (withCredentials != null) xhr.withCredentials = withCredentials;
    if (responseType != null) xhr.responseType = responseType;
    if (mimeType != null) xhr.overrideMimeType(mimeType);

    requestHeaders?.forEach(xhr.setRequestHeader);
    if (onProgress != null) xhr.onProgress.listen(onProgress);

    xhr.onLoad.listen((ProgressEvent e) {
      final status = xhr.status;
      if ((status >= 200 && status < 300) || status == 0 || status == 304) {
        completer.complete(xhr);
      } else {
        completer.completeError(e);
      }
    });

    xhr.onError.listen(completer.completeError);

    xhr.send(sendData is String ? sendData.toJS : sendData?.jsify());

    return completer.future;
  }
}
