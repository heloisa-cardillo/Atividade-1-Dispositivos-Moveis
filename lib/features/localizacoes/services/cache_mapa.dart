import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CacheMapa {
  static const int tamanhoMaximo = 200 * 1024 * 1024;

  Future<BuiltInMapCachingProvider> preparar() async {
    final pastaPrivada = await getApplicationSupportDirectory();
    final caminho = join(pastaPrivada.path, 'cache_mapa');

    return BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: caminho,
      maxCacheSize: tamanhoMaximo,
    );
  }
}
