import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  static const Color _cinza = Color(0xFF6B7280);

  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  List<Localizacao>? _localizacoes;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _repositorio.consultarUltimas();
      if (!mounted) return;
      setState(() {
        _localizacoes = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);

      if (_localizacoes == null) {
        setState(() => _erro = 'Não foi possível carregar o mapa.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o mapa.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _estado(String titulo, String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/coelho.png', width: 72, height: 72),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _cinza),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: Image.asset(
                'assets/icons/atualizar.png',
                width: 18,
                height: 18,
              ),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final lista = _localizacoes;
    final erro = _erro;

    if (lista == null && _carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lista == null) {
      return _estado(
        erro ?? 'Não foi possível carregar o mapa.',
        'Tente atualizar.',
      );
    }

    if (lista.isEmpty) {
      return _estado(
        'Nenhum rastro por aqui ainda',
        'Inicie a coleta para ver suas posições no mapa.',
      );
    }

    return Stack(
      children: [
        MapaLocalizacoes(localizacoes: lista, onAtualizar: _carregar),
        if (_carregando)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: _conteudo(),
    );
  }
}
