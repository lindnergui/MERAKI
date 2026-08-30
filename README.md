# Meraki

**Meraki** é um player de música para Linux e Android, feito para reunir sua
biblioteca local e seu servidor Subsonic em uma experiência rápida e elegante.

## Download e instalação

Baixe a versão mais recente na página de
[Releases do Meraki](https://github.com/lindnergui/meraki/releases).

| Distribuição | Pacote |
| --- | --- |
| Ubuntu / Debian | Baixe o arquivo `.deb` |
| Fedora | Baixe o arquivo `.rpm` |

### Ubuntu e Debian

Depois de baixar o pacote, abra um terminal na pasta do arquivo e execute:

```bash
sudo dpkg -i ./meraki-versao_amd64.deb
```

Se o sistema informar dependências pendentes, corrija-as com:

```bash
sudo apt --fix-broken install
```

### Fedora

Depois de baixar o pacote, abra um terminal na pasta do arquivo e execute:

```bash
sudo dnf install ./meraki-versao.rpm
```

Após a instalação, procure por **Meraki** no menu de aplicativos do GNOME,
KDE ou outro ambiente desktop. Também é possível iniciar pelo terminal:

```bash
meraki
```

## Recursos

- Biblioteca de músicas local, com leitura de metadados de áudio;
- Integração com servidores Subsonic;
- Reprodução de arquivos locais e streams remotos;
- Controles de fila, volume, aleatório, repetição e mídia em segundo plano;
- Favoritas persistentes e interface responsiva;
- Interface dark com alto contraste e detalhes em verde sálvia;
- Controles de sistema no Linux e MediaSession no Android.

## Primeiros passos

Na primeira abertura, informe apenas o nome que deseja usar no aplicativo.
Depois, em **Configurações**, conecte seu servidor Subsonic ou selecione uma
pasta local para criar a biblioteca. O Meraki guarda o catálogo em cache local
para tornar a navegação mais rápida.

## Para quem compila o Meraki

O aplicativo usa Flutter para a interface e Rust através de
`flutter_rust_bridge` para catálogo, metadados e banco de dados. O Rust é
compilado e incluído automaticamente no bundle Linux pelo script de
empacotamento.

### Pré-requisitos para criar pacotes Linux

- Flutter com suporte a Linux;
- Rust estável e Cargo;
- Ferramentas de build do Flutter Linux (`clang`, `cmake`, `ninja`, `pkg-config`
  e `libgtk-3-dev` ou equivalentes);
- `rpmbuild` para gerar `.rpm`;
- `dpkg-deb` para gerar `.deb`.

Em Fedora, instale as ferramentas de pacote com:

```bash
sudo dnf install rpm-build dpkg
```

Em Ubuntu/Debian:

```bash
sudo apt install rpm dpkg-dev
```

### Gerar os pacotes localmente

Na raiz do repositório:

```bash
scripts/package-linux.sh --format all
```

O script executa, nesta ordem:

1. `cargo build --release` em `rust_core`;
2. `flutter build linux --release`;
3. cópia explícita de `librust_lib_meraki.so` para
   `build/linux/x64/release/bundle/lib/`;
4. criação do lançador, arquivo `.desktop` e ícone do sistema;
5. geração dos arquivos em `dist/linux/`.

Para criar somente um formato:

```bash
scripts/package-linux.sh --format rpm
scripts/package-linux.sh --format deb
```

Para reaproveitar um bundle release já criado, por exemplo em CI:

```bash
scripts/package-linux.sh --format rpm --skip-build
```

## Releases automáticas

Ao publicar uma tag que começa com `v`, o workflow em
[`.github/workflows/release.yml`](.github/workflows/release.yml) compila o
bundle release com Rust, gera os pacotes Debian e Fedora e os anexa a uma GitHub
Release. Atualize `SEU-USUARIO` nos links e nos metadados de empacotamento antes
da primeira publicação pública.

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d linux
```

Quando a API Rust mudar, regenere os bindings:

```bash
flutter_rust_bridge_codegen generate
```
