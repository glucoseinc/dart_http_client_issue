import 'dart:io';

void main(List<String> arguments) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080)
    ..listen((proxyRequest) async {
      final realUrl = Uri.parse(
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4${proxyRequest.uri.path}');

      print('${proxyRequest.uri} -> $realUrl');

      final client = HttpClient();

      try {
        final req = await client.openUrl(proxyRequest.method, realUrl);
        final realResponse = await req.close();

        proxyRequest.response.statusCode = realResponse.statusCode;
        const headerWhiteList = [
          'date',
          'content-length',
          'content-type',
          'accept-ranges',
          'last-modified',
          'etag',
        ];
        realResponse.headers.forEach((key, value) {
          if (headerWhiteList.contains(key)) {
            proxyRequest.response.headers.add(key, value);
          }
        });

        await proxyRequest.response.addStream(realResponse);
        await proxyRequest.response.flush();
        await proxyRequest.response.close();
      } finally {
        client.close();
      }
    });

  print('🚀 http://${server.address.host}:${server.port}');
}
