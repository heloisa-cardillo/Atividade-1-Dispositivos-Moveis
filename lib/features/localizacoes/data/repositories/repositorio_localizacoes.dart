import 'package:sqflite/sqflite.dart';

import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

class RepositorioLocalizacoes {
  static const int limiteConsulta = 100;

  Future<void> inserir(Localizacao localizacao) async {
    final banco = await BancoLocalizacoes.abrir();
    final dados = localizacao.paraMapa()..remove('id');
    await banco.insert(BancoLocalizacoes.tabela, dados);
  }

  Future<List<Localizacao>> consultarUltimas({
    DateTime? de,
    DateTime? ate,
  }) async {
    final banco = await BancoLocalizacoes.abrir();
    final condicoes = <String>[];
    final valores = <Object>[];

    if (de != null) {
      final inicio = DateTime(de.year, de.month, de.day);
      condicoes.add('instante >= ?');
      valores.add(inicio.toUtc().toIso8601String());
    }

    if (ate != null) {
      final fim = DateTime(ate.year, ate.month, ate.day + 1);
      condicoes.add('instante < ?');
      valores.add(fim.toUtc().toIso8601String());
    }

    final linhas = await banco.query(
      BancoLocalizacoes.tabela,
      where: condicoes.isEmpty ? null : condicoes.join(' AND '),
      whereArgs: valores.isEmpty ? null : valores,
      orderBy: 'instante DESC, id DESC',
      limit: limiteConsulta,
    );

    return linhas.map(Localizacao.deMapa).toList();
  }

  Future<int> contar() async {
    final banco = await BancoLocalizacoes.abrir();
    final resultado = await banco.rawQuery(
      'SELECT COUNT(*) FROM ${BancoLocalizacoes.tabela}',
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> limparTudo() async {
    final banco = await BancoLocalizacoes.abrir();
    await banco.delete(BancoLocalizacoes.tabela);
  }
}
