import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum ResultadoPermissao { concedida, gpsDesligado, negada, negadaParaSempre }

class ServicoLocalizacao {
  Future<ResultadoPermissao> verificarPermissoes() async {
    final gpsLigado = await Geolocator.isLocationServiceEnabled();
    if (!gpsLigado) return ResultadoPermissao.gpsDesligado;

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.deniedForever) {
      return ResultadoPermissao.negadaParaSempre;
    }
    if (permissao == LocationPermission.denied) {
      return ResultadoPermissao.negada;
    }

    await Permission.notification.request();
    return ResultadoPermissao.concedida;
  }

  Stream<Position> posicoes() {
    final configuracao = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 20),
      distanceFilter: 0,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Coleta de localização ativa',
        notificationText: 'Salvando sua posição a cada 20 segundos.',
        notificationIcon: AndroidResource(
          name: 'icone_localizacoes',
          defType: 'drawable',
        ),
        enableWakeLock: true,
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: configuracao);
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesGps() => Geolocator.openLocationSettings();
}
