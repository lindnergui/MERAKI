# Meraki

**Meraki** é um player de música para **Linux** e **Android**. Ele reúne a
biblioteca local e servidores Subsonic em uma interface elegante, com reprodução em
segundo plano e controles integrados ao sistema.

## Recursos

- Biblioteca local e streaming por Subsonic.
- Reprodução em segundo plano, controles na notificação e tela bloqueada.
- Compatibilidade com Android Auto, incluindo catálogo, capas e controles de
  reprodução no veículo.
- Interface responsiva para desktop Linux e celulares Android.
- Tema escuro e identidade visual Meraki.

## Download e instalação

As versões disponíveis ficam na página de
[Releases do Meraki](https://github.com/lindnergui/MERAKI/releases).

### Linux — Flatpak

Baixe o arquivo `.flatpak` mais recente para Linux x86_64.

Pela interface gráfica, dê dois cliques no arquivo e confirme a instalação.
Pelo terminal, execute na pasta do download:

```bash
flatpak install --user ./meraki-versao-x86_64.flatpak
flatpak run com.github.lindnergui.meraki
```

Caso o Flatpak ainda não esteja instalado, siga o [guia oficial de
configuração](https://flatpak.org/setup/). Para atualizar, instale o bundle
mais recente novamente. Para remover o Meraki:

```bash
flatpak uninstall com.github.lindnergui.meraki
```

### Android — APK

Quando um APK estiver disponível na Release, baixe o arquivo `.apk` no celular,
abra-o e confirme a instalação. O Android pode solicitar autorização para
instalar aplicativos dessa origem.

Para instalar a partir de um computador com ADB configurado:

```bash
adb install -r meraki-versao.apk
```

Após instalar, abra o Meraki, permita as notificações e sincronize ou escaneie
sua biblioteca. Em veículos compatíveis, o Meraki aparecerá como um app de
mídia no Android Auto.

## Releases automáticas

Ao publicar uma tag iniciada por `v`, o workflow
[`release.yml`](.github/workflows/release.yml) gera e anexa automaticamente à
GitHub Release:

- `meraki-android.apk` para Android;
- `meraki.flatpak` para Linux x86_64.

## Desenvolvimento

Pré-requisitos: Flutter, Rust e o SDK Android para builds Android. Para Linux,
instale também os requisitos de desenvolvimento do Flutter para GTK.

```bash
flutter pub get
flutter analyze
flutter test
```

### Executar no Linux

```bash
flutter run -d linux
```

### Gerar um APK Android de teste

```bash
flutter build apk --debug
```

O arquivo será criado em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### Testar ou gerar o Flatpak localmente

Instale `flatpak` e `flatpak-builder`, configure o repositório Flathub e rode:

```bash
flatpak remote-add --if-not-exists --user flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
scripts/build-flatpak.sh
```

O bundle será criado em `dist/meraki.flatpak` e pode ser testado assim:

```bash
flatpak install --user ./dist/meraki.flatpak
flatpak run com.github.lindnergui.meraki
```

Quando a API Rust mudar, regenere os bindings:

```bash
flutter_rust_bridge_codegen generate
```
