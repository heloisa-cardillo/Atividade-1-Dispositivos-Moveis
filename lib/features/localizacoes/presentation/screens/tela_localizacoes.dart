import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../utils/formatar_localizacao.dart';
import '../widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  final bool coletaAtiva;

  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  static const Color _vermelho = Color(0xFFEF4444);
  static const Color _cinza = Color(0xFF6B7280);

  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  List<Localizacao> _localizacoes = [];
  int _total = 0;
  bool _carregando = true;
  String? _erro;
  DateTimeRange? _periodo;

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
      final lista = await _repositorio.consultarUltimas(
        de: _periodo?.start,
        ate: _periodo?.end,
      );
      final total = await _repositorio.contar();
      if (!mounted) return;
      setState(() {
        _localizacoes = lista;
        _total = total;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o histórico.';
        _carregando = false;
      });
    }
  }

  Future<void> _escolherPeriodo() async {
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
      helpText: 'Filtrar por datas',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      saveText: 'Aplicar',
    );
    if (!mounted || periodo == null) return;
    setState(() => _periodo = periodo);
    await _carregar();
  }

  Future<void> _limparFiltro() async {
    setState(() => _periodo = null);
    await _carregar();
  }

  Future<void> _confirmarLimpeza() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(
          widget.coletaAtiva
              ? 'Todas as localizações salvas serão apagadas de forma permanente. A coleta continua ativa, então novos registros continuarão sendo salvos.'
              : 'Todas as localizações salvas serão apagadas de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            style: TextButton.styleFrom(foregroundColor: _vermelho),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repositorio.limparTudo();
      if (!mounted) return;
      _mostrarAviso('Histórico apagado.');
    } catch (_) {
      if (!mounted) return;
      _mostrarAviso('Não foi possível apagar o histórico.', erro: true);
    }

    await _carregar();
  }

  void _mostrarAviso(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: erro ? _vermelho : null),
    );
  }

  String _textoPeriodo(DateTimeRange periodo) {
    final inicio = formatarDiaMes(periodo.start);
    final fim = formatarDiaMes(periodo.end);
    return inicio == fim ? inicio : '$inicio a $fim';
  }

  Widget _filtro() {
    final periodo = _periodo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: Image.asset(
            'assets/icons/calendario.png',
            width: 18,
            height: 18,
          ),
          label: Text(
            periodo == null ? 'Todas as datas' : _textoPeriodo(periodo),
          ),
          onPressed: _escolherPeriodo,
          onDeleted: periodo == null ? null : _limparFiltro,
          deleteIcon: Image.asset(
            'assets/icons/fechar.png',
            width: 16,
            height: 16,
          ),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: const StadiumBorder(),
        ),
      ),
    );
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
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final erro = _erro;

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erro != null) {
      return _estado(erro, 'Toque em atualizar para tentar de novo.');
    }

    if (_localizacoes.isEmpty) {
      return _estado(
        'Nenhum rastro por aqui ainda',
        _periodo != null
            ? 'Nenhuma localização nesse período.'
            : 'Inicie a coleta para registrar posições.',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _localizacoes.length + 1,
        itemBuilder: (context, indice) {
          if (indice == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Mostrando ${_localizacoes.length} de $_total registros',
                style: const TextStyle(color: _cinza, fontSize: 13),
              ),
            );
          }

          final posicao = indice - 1;
          return ItemLocalizacao(
            localizacao: _localizacoes[posicao],
            maisRecente: posicao == 0,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: Image.asset(
              'assets/icons/atualizar.png',
              width: 22,
              height: 22,
            ),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando || _total == 0 ? null : _confirmarLimpeza,
            icon: Image.asset('assets/icons/limpar.png', width: 22, height: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          _filtro(),
          Expanded(child: _conteudo()),
        ],
      ),
    );
  }
}
