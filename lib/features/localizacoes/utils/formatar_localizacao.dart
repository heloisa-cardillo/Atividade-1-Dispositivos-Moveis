String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

String formatarDataHora(DateTime instante) {
  final local = instante.toLocal();
  return '${_doisDigitos(local.day)}/${_doisDigitos(local.month)}/${local.year} '
      '${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}:${_doisDigitos(local.second)}';
}

String formatarHora(DateTime instante) {
  final local = instante.toLocal();
  return '${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}';
}

String formatarDiaMes(DateTime data) {
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';
}

String formatarCoordenada(double valor) => valor.toStringAsFixed(6);

String formatarPrecisao(double metros) {
  return '${metros.toStringAsFixed(1).replaceAll('.', ',')} m';
}
