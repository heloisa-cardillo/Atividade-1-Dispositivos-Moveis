import 'package:flutter/material.dart';

import '../../models/localizacao.dart';
import '../../utils/formatar_localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  final Localizacao localizacao;
  final bool maisRecente;
  final bool linhaDoTempo;

  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.maisRecente = false,
    this.linhaDoTempo = true,
  });

  static const Color _azul = Color(0xFF2A49EB);
  static const Color _vermelho = Color(0xFFEF4444);

  (Color fundo, Color texto) _coresPrecisao(double metros) {
    if (metros <= 10) return (const Color(0xFFDCFCE7), const Color(0xFF166534));
    if (metros <= 30) return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
    return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
  }

  @override
  Widget build(BuildContext context) {
    final (fundoSelo, textoSelo) = _coresPrecisao(localizacao.precisao);

    final cartao = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatarDataHora(localizacao.instante),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fundoSelo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatarPrecisao(localizacao.precisao),
                  style: TextStyle(
                    color: textoSelo,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatarCoordenada(localizacao.latitude)}, '
            '${formatarCoordenada(localizacao.longitude)}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );

    if (!linhaDoTempo) return cartao;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(width: 2, color: const Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: maisRecente ? _vermelho : _azul,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: cartao,
            ),
          ),
        ],
      ),
    );
  }
}
