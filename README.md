# Meraki

<<<<<<< HEAD
**Meraki** é um player de música para Linux e Android que une sua biblioteca
local e seu servidor Subsonic em uma experiência rápida, elegante e dark.

## Download e instalação

Baixe o arquivo `.flatpak` mais recente na página de
[Releases do Meraki](https://github.com/lindnergui/MERAKI/releases).

### Instalação por interface gráfica

Em ambientes Linux com suporte a Flatpak, normalmente basta dar dois cliques no
arquivo `.flatpak` baixado e confirmar a instalação na loja de aplicativos.

### Instalação pelo terminal

Caso o comando `flatpak` ainda não exista, instale-o pela loja de aplicativos
da sua distribuição ou siga o [guia oficial de instalação do
Flatpak](https://flatpak.org/setup/).

Em seguida, na pasta que contém o arquivo baixado:

```bash
flatpak install --user ./meraki-v0.1.0-x86_64.flatpak
```

Abra **Meraki** pelo menu de aplicativos ou execute:

```bash
flatpak run com.github.lindnergui.meraki
```

Para atualizar, baixe o novo arquivo `.flatpak` e repita o comando de
instalação. Para remover o aplicativo:

```bash
flatpak uninstall com.github.lindnergui.meraki
=======
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
>>>>>>> 0f84d45483f4c0282b27b5b559ffade94ca85cd7
```

## Recursos

<<<<<<< HEAD
- Biblioteca de músicas local com extração de metadados;
=======
- Biblioteca de músicas local, com leitura de metadados de áudio;
>>>>>>> 0f84d45483f4c0282b27b5b559ffade94ca85cd7
- Integração com servidores Subsonic;
- Reprodução de arquivos locais e streams remotos;
- Controles de fila, volume, aleatório, repetição e mídia em segundo plano;
- Favoritas persistentes e interface responsiva;
<<<<<<< HEAD
- Interface dark com alto contraste;
- Controles de sistema no Linux e MediaSession no Android.

## Primeiro uso

Na primeira abertura, informe o nome que deseja usar. Depois, em
**Configurações**, conecte seu servidor Subsonic ou selecione uma pasta de
músicas. A versão Flatpak lê a biblioteca local sem poder alterar seus arquivos.

## Compilar o Flatpak localmente

Instale `flatpak` e `flatpak-builder` pela sua distribuição e adicione o Flathub
ao perfil do usuário, se necessário:

```bash
flatpak remote-add --if-not-exists --user flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
```

Na raiz do repositório, execute:

```bash
scripts/build-flatpak.sh
```

O comando usa o manifesto em
[`flatpak/com.github.lindnergui.meraki.yml`](flatpak/com.github.lindnergui.meraki.yml),
baixa o runtime GNOME necessário, compila Flutter e o core Rust e produz
`dist/meraki.flatpak`. Para testar o resultado:

```bash
flatpak install --user ./dist/meraki.flatpak
flatpak run com.github.lindnergui.meraki
=======
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
>>>>>>> 0f84d45483f4c0282b27b5b559ffade94ca85cd7
```

## Releases automáticas

<<<<<<< HEAD
Ao publicar uma tag iniciada por `v`, o workflow
[`flatpak.yml`](.github/workflows/flatpak.yml) compila o bundle Flatpak x86_64 e
o anexa automaticamente à GitHub Release. O workflow também pode ser disparado
manualmente para validar o build, sem publicar uma Release.
=======
Ao publicar uma tag que começa com `v`, o workflow em
[`.github/workflows/release.yml`](.github/workflows/release.yml) compila o
bundle release com Rust, gera os pacotes Debian e Fedora e os anexa a uma GitHub
Release. Atualize `SEU-USUARIO` nos links e nos metadados de empacotamento antes
da primeira publicação pública.
>>>>>>> 0f84d45483f4c0282b27b5b559ffade94ca85cd7

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
