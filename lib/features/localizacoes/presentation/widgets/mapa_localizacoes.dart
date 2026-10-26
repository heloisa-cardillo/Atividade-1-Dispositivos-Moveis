import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import 'item_localizacao.dart';

class MapaLocalizacoes extends StatefulWidget {
  final List<Localizacao> localizacoes;
  final VoidCallback onAtualizar;

  const MapaLocalizacoes({
    super.key,
    required this.localizacoes,
    required this.onAtualizar,
  });

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  static const Color _azul = Color(0xFF2A49EB);

  final MapController _controle = MapController();
  BuiltInMapCachingProvider? _cache;
  bool _cachePronto = false;
  bool _mapaPronto = false;
  Localizacao? _selecionada;

  @override
  void initState() {
    super.initState();
    _prepararCache();
  }

  @override
  void didUpdateWidget(MapaLocalizacoes antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.localizacoes != widget.localizacoes) {
      _selecionada = null;
      _enquadrar();
    }
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  Future<void> _prepararCache() async {
    BuiltInMapCachingProvider? cache;
    try {
      cache = await CacheMapa().preparar();
    } catch (_) {
      cache = null;
    }
    if (!mounted) return;
    setState(() {
      _cache = cache;
      _cachePronto = true;
    });
  }

  List<LatLng> get _pontos =>
      widget.localizacoes.map((l) => LatLng(l.latitude, l.longitude)).toList();

  void _enquadrar() {
    final pontos = _pontos;
    if (pontos.isEmpty || !_mapaPronto) return;

    if (pontos.length == 1) {
      _controle.move(pontos.first, 17);
      return;
    }

    _controle.fitCamera(
      CameraFit.coordinates(
        coordinates: pontos,
        padding: const EdgeInsets.all(56),
        maxZoom: 17,
      ),
    );
  }

  List<Marker> _marcadores() {
    final marcadores = <Marker>[];

    for (var i = widget.localizacoes.length - 1; i >= 0; i--) {
      final localizacao = widget.localizacoes[i];
      final recente = i == 0;
      final tamanho = recente ? 48.0 : 32.0;

      marcadores.add(
        Marker(
          point: LatLng(localizacao.latitude, localizacao.longitude),
          width: tamanho,
          height: tamanho,
          child: GestureDetector(
            onTap: () => setState(() => _selecionada = localizacao),
            child: Image.asset(
              recente
                  ? 'assets/icons/marcador_recente.png'
                  : 'assets/icons/marcador_patinha.png',
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  Widget _botao(String icone, String dica, VoidCallback aoTocar) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: dica,
        onPressed: aoTocar,
        icon: Image.asset(icone, width: 22, height: 22),
      ),
    );
  }

  Widget _painel(Localizacao selecionada) {
    final maisRecente = identical(selecionada, widget.localizacoes.first);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  maisRecente ? 'Posição mais recente' : 'Posição registrada',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => setState(() => _selecionada = null),
                icon: Image.asset(
                  'assets/icons/fechar.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ItemLocalizacao(
              localizacao: selecionada,
              maisRecente: maisRecente,
              linhaDoTempo: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pontos = _pontos;
    final selecionada = _selecionada;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controle,
          options: MapOptions(
            initialCenter: pontos.first,
            initialZoom: 16,
            onMapReady: () {
              _mapaPronto = true;
              _enquadrar();
            },
            onTap: (_, _) => setState(() => _selecionada = null),
          ),
          children: [
            if (_cachePronto)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.atividade_localizacoes',
                tileProvider: NetworkTileProvider(cachingProvider: _cache),
              ),
            if (pontos.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: pontos,
                    color: _azul.withValues(alpha: 0.6),
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [8, 6]),
                  ),
                ],
              ),
            MarkerLayer(markers: _marcadores()),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _botao(
                'assets/icons/atualizar.png',
                'Atualizar',
                widget.onAtualizar,
              ),
              const SizedBox(height: 8),
              _botao('assets/icons/enquadrar.png', 'Enquadrar', _enquadrar),
            ],
          ),
        ),
        if (selecionada != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 40,
            child: _painel(selecionada),
          ),
      ],
    );
  }
}
