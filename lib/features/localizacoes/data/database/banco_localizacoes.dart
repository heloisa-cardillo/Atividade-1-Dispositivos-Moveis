import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  static const String nomeArquivo = 'localizacoes.db';
  static const int versao = 1;
  static const String tabela = 'localizacoes';

  static Future<Database>? _abertura;

  static Future<Database> abrir() async {
    _abertura ??= _criarConexao();

    try {
      return await _abertura!;
    } catch (erro) {
      _abertura = null;
      rethrow;
    }
  }

  static Future<Database> _criarConexao() async {
    final pasta = await getDatabasesPath();
    final caminho = join(pasta, nomeArquivo);

    return openDatabase(
      caminho,
      version: versao,
      onCreate: (banco, versao) async {
        await banco.execute('''
          CREATE TABLE $tabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
