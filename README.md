# Meraki

Base arquitetural de um player de música para **Android e Linux**, com Flutter na
UI/reprodução, Rust no catálogo e `flutter_rust_bridge` v2 na ponte FFI.

As imagens anexadas à conversa são referências visuais para uma etapa futura. A
base atual usa apenas a direção de cor roxa e não tenta reproduzir ainda as telas.

## Parte 1 — Estrutura de pastas e setup

### Pré-requisitos

- Flutter com suporte a Android e Linux;
- Android SDK + NDK configurados pelo Flutter;
- Rust via `rustup`;
- dependências de desktop do Flutter para Linux.

O projeto fixa Rust 1.98.0 em `rust-toolchain.toml`. O fluxo atual recomendado
pela documentação do FRB v2 é instalar o codegen, executar `integrate` em um app
Flutter existente e executar `generate` após mudanças na API Rust.

### Inicialização equivalente, partindo de um diretório vazio

```bash
mkdir meraki
cd meraki

flutter create \
  --platforms=android,linux \
  --org app.meraki \
  --project-name meraki \
  .

cargo new rust_core --lib --name meraki_rust_core
cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked

flutter_rust_bridge_codegen integrate --rust-crate-dir rust_core
flutter_rust_bridge_codegen generate
```

As dependências principais poderiam ser adicionadas por CLI assim:

```bash
cargo add --manifest-path rust_core/Cargo.toml tokio --features macros,rt-multi-thread,sync
cargo add --manifest-path rust_core/Cargo.toml reqwest --no-default-features --features json,query,rustls
cargo add --manifest-path rust_core/Cargo.toml lofty
cargo add --manifest-path rust_core/Cargo.toml rusqlite --features bundled
cargo add --manifest-path rust_core/Cargo.toml flutter_rust_bridge@=2.13.0

flutter pub add flutter_rust_bridge just_audio audio_service audio_session path_provider path
flutter pub add just_audio_media_kit media_kit_libs_linux audio_service_mpris
```

`rusqlite/bundled` é intencional: compila uma versão conhecida do SQLite junto
ao core e reduz diferenças entre Android e distribuições Linux. `reqwest` usa
Rustls para não depender do OpenSSL do sistema.

### Concluir este workspace preparado

Este repositório já contém `pubspec.yaml`, código Dart e o crate `rust_core`. Como
o host em que a base foi criada não tinha Flutter/Rust instalados, gere somente o
boilerplate dependente dos toolchains:

```bash
flutter create \
  --platforms=android,linux \
  --org app.meraki \
  --project-name meraki \
  .

cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked
flutter_rust_bridge_codegen integrate --rust-crate-dir rust_core
flutter_rust_bridge_codegen generate
flutter pub get
```

Durante desenvolvimento da API Rust:

```bash
flutter_rust_bridge_codegen generate --watch
```

### Árvore final

Itens marcados como “gerado” aparecem depois dos comandos acima.

```text
meraki/
├── android/                         # gerado por flutter create
├── linux/                           # gerado por flutter create
├── lib/
│   ├── main.dart                    # RustLib.init + AudioService.init
│   └── src/
│       ├── app.dart                 # shell mínimo da aplicação
│       ├── audio/
│       │   └── meraki_audio_handler.dart
│       ├── data/
│       │   └── music_repository.dart
│       └── rust/                    # bindings Dart gerados pelo FRB
│           ├── api/music.dart
│           ├── models/song.dart
│           └── frb_generated.dart
├── rust_builder/                    # integração Cargokit gerada pelo FRB
├── rust_core/
│   ├── Cargo.toml
│   └── src/
│       ├── api/
│       │   ├── mod.rs
│       │   └── music.rs             # superfície exportada para Flutter
│       ├── models/
│       │   ├── mod.rs
│       │   └── song.rs
│       ├── database.rs              # SQLite e transações
│       ├── error.rs
│       ├── scanner.rs               # walkdir + lofty
│       ├── subsonic.rs              # HTTP, token auth e parsing JSON
│       └── lib.rs
├── Cargo.toml                        # workspace Rust
├── flutter_rust_bridge.yaml
├── pubspec.yaml
└── rust-toolchain.toml
```

## Parte 2 — Modelagem de dados no Rust

O modelo exportado está em `rust_core/src/models/song.rs`:

```rust
pub enum SongSource {
    Local,
    Subsonic,
}

pub struct Song {
    pub id: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub cover_art_url_or_path: Option<String>,
    pub stream_url_or_file_path: String,
    pub duration_seconds: Option<u32>,
    pub source: SongSource,
}
```

IDs locais são UUID v5 determinísticos a partir do caminho canônico. IDs remotos
incluem um hash curto do servidor, evitando colisões quando mais de um Subsonic
for adicionado no futuro.

## Parte 3 — Contratos da API Rust

A superfície FFI está em `rust_core/src/api/music.rs`:

```rust
pub async fn init_db(database_path: String) -> Result<(), String>;
pub async fn scan_local_music(path: String) -> Result<Vec<Song>, String>;
pub async fn fetch_subsonic_songs(
    server_url: String,
    username: String,
    password: String,
) -> Result<Vec<Song>, String>;
pub async fn get_all_songs() -> Result<Vec<Song>, String>;
```

`init_db` recebe um caminho porque o Flutter conhece o diretório correto do
sandbox; no Dart, `MusicRepository.initialize()` preserva a API sem argumento.

Já existe uma implementação-base funcional:

- cria o schema SQLite, ativa WAL e substitui cada fonte em uma transação;
- varre recursivamente formatos suportados pelo `lofty`, sem bloquear o executor
  assíncrono;
- autentica no Subsonic com `t=md5(password + salt)`, pagina os álbuns por
  `getAlbumList2`, busca detalhes por `getAlbum` com concorrência limitada e
  normaliza cada faixa para `Song`;
- mantém a senha em texto puro somente durante a chamada. O cache guarda URLs
  tokenizadas de stream/capa no banco privado do app; antes de suportar múltiplos
  perfis, a próxima evolução de segurança é guardar segredos no keystore/keyring e
  assinar URLs sob demanda.

O próximo incremento do core deve extrair capas embutidas para um diretório de
cache. Não se deve atravessar a FFI com blobs grandes durante a varredura.

## Parte 4 — Integração Flutter

`lib/main.dart` inicializa na ordem correta:

```dart
WidgetsFlutterBinding.ensureInitialized();
if (Platform.isLinux) {
  JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
}
await RustLib.init();

final repository = MusicRepository();
await repository.initialize();
```

`MusicRepository` é a fronteira única para os bindings gerados. A reprodução fica
em `MerakiAudioHandler`, que conecta `just_audio` a `audio_service`; Android recebe
MediaSession/notificação, e Linux usa o backend `just_audio_media_kit`.

### Configuração Android obrigatória

Depois de `flutter create`, aplique o passo a passo em
[`docs/android_setup.md`](docs/android_setup.md), que inclui a activity, o service,
o media-button receiver e as permissões atuais. Não copie caminhos de
armazenamento externo esperando que funcionem em todas as versões: no Android com
scoped storage, uma biblioteca arbitrária deve ser escolhida via Storage Access
Framework. O scanner atual aceita caminhos de filesystem acessíveis ao processo;
uma futura camada Flutter deverá resolver URIs do SAF para arquivos/descritores
legíveis pelo Rust.

## Verificação

```bash
flutter_rust_bridge_codegen generate
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
flutter analyze
flutter test
flutter run -d linux
```

Para Android, liste os devices e execute:

```bash
flutter devices
flutter run -d <android-device-id>
```

## Referências técnicas

- [Quickstart oficial do flutter_rust_bridge v2](https://cjycode.com/flutter_rust_bridge/quickstart)
- [Configuração do codegen FRB](https://cjycode.com/flutter_rust_bridge/guides/custom/codegen/inputs)
- [just_audio no Linux](https://pub.dev/packages/just_audio)
- [audio_service](https://pub.dev/packages/audio_service)
- [lofty](https://docs.rs/lofty/latest/lofty/)
