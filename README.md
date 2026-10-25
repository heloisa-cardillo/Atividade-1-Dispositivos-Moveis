# Coleta de Localizações

Atividade 1 da disciplina Programação para Dispositivos Móveis I (Prof. Arley, FATEC São José dos Campos).

App Flutter para Android que coleta a localização do aparelho em segundo plano, salva cada posição em SQLite e mostra o histórico em lista e em um mapa interativo.


<details>
<summary><strong>Telas e funcionalidades</strong></summary>

<br>

**Coleta**

- Botões Iniciar coleta, Parar coleta, Consultar histórico, Ver mapa e Configurações de permissão.
- Card de status com o estado da coleta, o total de registros e a última posição salva.
- Iniciar e Parar habilitados conforme o estado, evitando assinatura duplicada e gravações sobrepostas.
- Coleta por stream de posições, com alta precisão e intervalo solicitado de 20 segundos.
- Serviço em primeiro plano com notificação visível enquanto a coleta está ativa. A coleta continua ao trocar de tela e ao minimizar o app.

**Histórico**

- Últimas 100 localizações, da mais recente para a mais antiga.
- Data e hora locais, latitude e longitude com seis casas decimais e precisão em metros com uma casa decimal.
- Selo colorido indicando a precisão de cada leitura.
- Filtro por intervalo de datas.
- Atualização da lista sem interromper a coleta.
- Limpeza de todo o histórico com confirmação, avisando quando a coleta está ativa.

**Mapa**

- Últimas 100 posições como marcadores sobre uma base com ruas.
- Posição mais recente destacada em vermelho.
- Enquadramento automático ao carregar, botão para enquadrar de novo e botão para atualizar.
- Painel com os detalhes ao tocar em um marcador.

</details>

<details>
<summary><strong>Permissões</strong></summary>

<br>

Declaradas no `AndroidManifest.xml` e pedidas durante a execução quando necessário:

- `ACCESS_FINE_LOCATION` e `ACCESS_COARSE_LOCATION`: localização do aparelho.
- `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION`: coleta em primeiro plano.
- `POST_NOTIFICATIONS`: notificação da coleta (Android 13 ou superior).
- `INTERNET`: imagens do mapa.

O app verifica se o GPS está ligado, trata recusa da permissão e, em caso de recusa permanente, orienta a abrir as configurações do aplicativo.

</details>

<details>
<summary><strong>Persistência</strong></summary>

<br>

Banco `localizacoes.db`, tabela `localizacoes`:

| Coluna | Tipo | Observação |
| --- | --- | --- |
| id | INTEGER | Chave primária com autoincremento |
| latitude | REAL | Obrigatória |
| longitude | REAL | Obrigatória |
| precisao | REAL | Obrigatória, em metros |
| instante | TEXT | Obrigatória, UTC em ISO 8601 |

O limite de 100 vale só para a consulta; nenhum registro antigo é apagado automaticamente. A limpeza remove todas as linhas e mantém a tabela e o arquivo do banco. Nenhum banco com coordenadas está incluído neste repositório.

</details>

<details>
<summary><strong>Recursos utilizados</strong></summary>

<br>

- `geolocator`: permissões, verificação do GPS, stream de posições e serviço em primeiro plano.
- `sqflite` e `path`: banco SQLite local.
- `flutter_map` e `latlong2`: mapa interativo.
- `path_provider`: pasta privada usada pelo cache das imagens do mapa.
- Mapa base do OpenStreetMap, com atribuição exibida no próprio mapa e cache conforme a política de uso dos tiles.
- Fonte Plus Jakarta Sans e ícones próprios em PNG.

</details>

<details>
<summary><strong>Arquitetura</strong></summary>

<br>

- **Coleta**: o `servico_localizacao` entrega o stream de posições, a `tela_coleta` recebe cada posição e grava pelo `repositorio_localizacoes`, que usa o `banco_localizacoes`.
- **Histórico e mapa**: as telas consultam o repositório e recebem objetos `Localizacao`, exibidos pelos widgets.
- **Mapa**: o `mapa_localizacoes` usa o `cache_mapa` para guardar as imagens do mapa em uma pasta privada do app.

Nenhuma tela ou widget executa SQL diretamente.

</details>

<details>
<summary><strong>Estrutura</strong></summary>

<br>

```
assets/
├── icons/
│   ├── localizacoes.png          # ícone original do app
│   └── (ícones internos em PNG)
├── fonts/
│   └── PlusJakartaSans-*.ttf
└── midia/
    └── teste.mp4                 # vídeo de teste
android/app/src/main/
├── AndroidManifest.xml
└── res/
    ├── drawable-nodpi/icone_localizacoes.png
    ├── mipmap-mdpi/ic_localizacoes.png
    ├── mipmap-hdpi/ic_localizacoes.png
    ├── mipmap-xhdpi/ic_localizacoes.png
    ├── mipmap-xxhdpi/ic_localizacoes.png
    ├── mipmap-xxxhdpi/ic_localizacoes.png
    ├── mipmap-anydpi-v26/ic_localizacoes.xml
    └── values/icone_localizacoes.xml
lib/
├── main.dart
├── app.dart
└── features/
    └── localizacoes/
        ├── models/
        │   └── localizacao.dart
        ├── data/
        │   ├── database/
        │   │   └── banco_localizacoes.dart
        │   └── repositories/
        │       └── repositorio_localizacoes.dart
        ├── services/
        │   ├── servico_localizacao.dart
        │   └── cache_mapa.dart
        ├── utils/
        │   └── formatar_localizacao.dart
        └── presentation/
            ├── screens/
            │   ├── tela_coleta.dart
            │   ├── tela_localizacoes.dart
            │   └── tela_mapa.dart
            └── widgets/
                ├── item_localizacao.dart
                └── mapa_localizacoes.dart
```

</details>

<details>
<summary><strong>Como executar</strong></summary>

<br>

Requisitos: Flutter instalado e um celular Android com depuração USB ativada.

No PowerShell, dentro da pasta do projeto:

```powershell
flutter pub get
flutter devices
flutter run
```

Na primeira coleta, aceite a permissão de localização e a de notificações.

</details>

<br>

[Assistir ao vídeo de teste](assets/midia/teste.mp4)