# Meraki

Meraki é um player de música para Linux e Android que reúne a biblioteca local
e servidores Subsonic em uma experiência fluida e elegante.

## Download e instalação (Flatpak)

Baixe o arquivo `.flatpak` mais recente na página de
[Releases do Meraki](https://github.com/lindnergui/MERAKI/releases).

### Pela interface gráfica

Em distribuições com suporte a Flatpak, dê dois cliques no arquivo baixado e
confirme a instalação na loja de aplicativos.

### Pelo terminal

Se o comando `flatpak` ainda não estiver disponível, instale-o pela loja de
aplicativos da sua distribuição ou siga o [guia oficial do
Flatpak](https://flatpak.org/setup/).

Na pasta que contém o arquivo baixado, execute:

```bash
flatpak install --user ./meraki.flatpak
```

Depois, abra **Meraki** pelo menu de aplicativos ou execute:

```bash
flatpak run com.github.lindnergui.meraki
```

Para atualizar, baixe a versão mais recente e repita o comando de instalação.
Para remover o aplicativo:

```bash
flatpak uninstall com.github.lindnergui.meraki
```

## Releases automáticas

Ao publicar uma tag iniciada por `v`, o workflow
[`flatpak.yml`](.github/workflows/flatpak.yml) compila o bundle Flatpak x86_64
e o anexa automaticamente à GitHub Release. O workflow também pode ser
executado manualmente para validar o build sem publicar uma Release.

## Desenvolvimento

Para gerar e testar o Flatpak localmente, instale `flatpak` e
`flatpak-builder`, configure o repositório Flathub e execute o script na raiz
do projeto:

```bash
flatpak remote-add --if-not-exists --user flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
scripts/build-flatpak.sh
```

O bundle será criado em `dist/meraki.flatpak`. Para instalá-lo e testá-lo:

```bash
flatpak install --user ./dist/meraki.flatpak
flatpak run com.github.lindnergui.meraki
```

Para executar o projeto Flutter diretamente durante o desenvolvimento:

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
