# Meraki

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
```

## Recursos

- Biblioteca de músicas local com extração de metadados;
- Integração com servidores Subsonic;
- Reprodução de arquivos locais e streams remotos;
- Controles de fila, volume, aleatório, repetição e mídia em segundo plano;
- Favoritas persistentes e interface responsiva;
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
```

## Releases automáticas

Ao publicar uma tag iniciada por `v`, o workflow
[`flatpak.yml`](.github/workflows/flatpak.yml) compila o bundle Flatpak x86_64 e
o anexa automaticamente à GitHub Release. O workflow também pode ser disparado
manualmente para validar o build, sem publicar uma Release.

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
