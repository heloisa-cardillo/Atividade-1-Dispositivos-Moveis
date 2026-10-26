import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../../utils/formatar_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta>
    with SingleTickerProviderStateMixin {
  static const Color _azul = Color(0xFF2A49EB);
  static const Color _azulClaro = Color(0xFF3366F0);
  static const Color _vermelho = Color(0xFFEF4444);
  static const Color _verde = Color(0xFF4ADE80);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _fundoIcone = Color(0xFFEEF2FF);

  final ServicoLocalizacao _servico = ServicoLocalizacao();
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  StreamSubscription<Position>? _assinatura;
  Future<void> _filaGravacao = Future.value();
  bool _iniciando = false;
  int _total = 0;
  Localizacao? _ultima;
  String? _aviso;
  String? _textoAcao;
  VoidCallback? _acao;

  bool get _coletando => _assinatura != null;

  @override
  void initState() {
    super.initState();
    _atualizarResumo();
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  Future<void> _atualizarResumo() async {
    try {
      final total = await _repositorio.contar();
      final ultimas = await _repositorio.consultarUltimas();
      if (!mounted) return;
      setState(() {
        _total = total;
        _ultima = ultimas.isEmpty ? null : ultimas.first;
      });
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem(
        'Não foi possível ler as localizações salvas.',
        erro: true,
      );
    }
  }

  void _definirAviso(String? texto, {String? textoAcao, VoidCallback? acao}) {
    setState(() {
      _aviso = texto;
      _textoAcao = textoAcao;
      _acao = acao;
    });
  }

  Future<void> _iniciar() async {
    if (_coletando || _iniciando) return;

    setState(() => _iniciando = true);
    _definirAviso(null);

    ResultadoPermissao resultado;
    try {
      resultado = await _servico.verificarPermissoes();
    } catch (_) {
      resultado = ResultadoPermissao.negada;
    }

    if (!mounted) return;

    switch (resultado) {
      case ResultadoPermissao.gpsDesligado:
        _definirAviso(
          'O GPS está desligado. Ligue a localização do aparelho para iniciar a coleta.',
          textoAcao: 'Ligar GPS',
          acao: _servico.abrirConfiguracoesGps,
        );
      case ResultadoPermissao.negada:
        _definirAviso(
          'A permissão de localização foi recusada. Toque em Iniciar coleta para pedir de novo.',
        );
      case ResultadoPermissao.negadaParaSempre:
        _definirAviso(
          'A permissão de localização está bloqueada. Libere o acesso nas configurações do aplicativo.',
          textoAcao: 'Abrir configurações',
          acao: _servico.abrirConfiguracoesApp,
        );
      case ResultadoPermissao.concedida:
        setState(() {
          _assinatura = _servico.posicoes().listen(
            _aoReceberPosicao,
            onError: _aoFalhar,
          );
        });
        _pulso.repeat(reverse: true);
        _mostrarMensagem('Coleta iniciada.');
    }

    setState(() => _iniciando = false);
  }

  void _aoReceberPosicao(Position posicao) {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );

    _filaGravacao = _filaGravacao.then((_) => _gravar(localizacao));
  }

  Future<void> _gravar(Localizacao localizacao) async {
    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _total++;
        _ultima = localizacao;
      });
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar a localização.', erro: true);
    }
  }

  void _aoFalhar(Object erro) {
    _pararAssinatura();
    if (!mounted) return;
    _definirAviso(
      'A coleta foi interrompida porque a localização ficou indisponível. Verifique o GPS e as permissões.',
      textoAcao: 'Abrir configurações',
      acao: _servico.abrirConfiguracoesApp,
    );
  }

  Future<void> _parar() async {
    if (!_coletando) return;
    await _pararAssinatura();
    if (!mounted) return;
    _mostrarMensagem('Coleta parada.');
  }

  Future<void> _pararAssinatura() async {
    final assinatura = _assinatura;
    _assinatura = null;
    _pulso
      ..stop()
      ..value = 0;
    if (mounted) setState(() {});
    await assinatura?.cancel();
  }

  Future<void> _abrirHistorico() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaLocalizacoes(coletaAtiva: _coletando),
      ),
    );
    await _atualizarResumo();
  }

  Future<void> _abrirMapa() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaMapa()),
    );
    await _atualizarResumo();
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: erro ? _vermelho : null,
        ),
      );
  }

  Widget _indicador() {
    final cor = _coletando ? _verde : Colors.white54;

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_coletando)
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1).animate(_pulso),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _cartaoStatus() {
    final ultima = _ultima;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_azul, _azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _indicador(),
              const SizedBox(width: 8),
              Text(
                _coletando ? 'Coletando' : 'Parado',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/icons/coelho_branco.png',
                width: 40,
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ),
          ),
          Text(
            _total == 1 ? 'registro salvo' : 'registros salvos',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Text(
            ultima == null
                ? 'Nenhuma posição salva ainda'
                : 'Última: ${formatarCoordenada(ultima.latitude)}, '
                      '${formatarCoordenada(ultima.longitude)} · '
                      '${formatarHora(ultima.instante)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _cartaoAviso() {
    final acao = _acao;
    final textoAcao = _textoAcao;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(_aviso ?? '', style: const TextStyle(fontSize: 13)),
          ),
          if (acao != null && textoAcao != null)
            TextButton(onPressed: acao, child: Text(textoAcao)),
        ],
      ),
    );
  }

  Widget _botaoIniciar() {
    final habilitado = !_coletando && !_iniciando;

    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          gradient: habilitado
              ? const LinearGradient(colors: [_azul, _azulClaro])
              : null,
          color: habilitado ? null : _borda,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: habilitado ? _iniciar : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: habilitado ? 1 : 0.5,
                child: Image.asset(
                  'assets/icons/iniciar.png',
                  width: 18,
                  height: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _iniciando ? 'Iniciando…' : 'Iniciar coleta',
                style: TextStyle(
                  color: habilitado ? Colors.white : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoParar() {
    return OutlinedButton.icon(
      onPressed: _coletando ? _parar : null,
      icon: Opacity(
        opacity: _coletando ? 1 : 0.4,
        child: Image.asset('assets/icons/parar.png', width: 18, height: 18),
      ),
      label: const Text('Parar coleta'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _vermelho,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: _coletando ? _vermelho : _borda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _atalho(
    String icone,
    String texto,
    VoidCallback aoTocar, {
    bool horizontal = false,
  }) {
    final circulo = Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: _fundoIcone,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Image.asset(icone, width: 20, height: 20),
    );
    final rotulo = Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: horizontal
              ? Row(
                  children: [
                    circulo,
                    const SizedBox(width: 12),
                    Expanded(child: rotulo),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [circulo, const SizedBox(height: 10), rotulo],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/localizacoes.png',
                width: 30,
                height: 30,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Localizações'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cartaoStatus(),
              if (_aviso != null) _cartaoAviso(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _botaoIniciar()),
                  const SizedBox(width: 10),
                  Expanded(child: _botaoParar()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _atalho(
                      'assets/icons/historico.png',
                      'Consultar histórico',
                      _abrirHistorico,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _atalho(
                      'assets/icons/mapa.png',
                      'Ver mapa',
                      _abrirMapa,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _atalho(
                'assets/icons/configuracoes.png',
                'Configurações de permissão',
                _servico.abrirConfiguracoesApp,
                horizontal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
