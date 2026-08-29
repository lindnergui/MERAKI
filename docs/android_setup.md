# Android: configuração nativa

Execute estas alterações depois de `flutter create --platforms=android,linux .`.
Elas seguem o setup do `audio_service` 0.18.19 e acrescentam as permissões do
catálogo local.

Em `android/app/src/main/AndroidManifest.xml`, mantenha os atributos gerados pelo
Flutter e acrescente os elementos relevantes abaixo:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission
        android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />

    <application ...>
        <!-- Substitui o android:name da activity gerada pelo Flutter. -->
        <activity
            android:name="com.ryanheise.audioservice.AudioServiceActivity"
            ...>
            <!-- Preserve os meta-data e intent-filters gerados pelo Flutter. -->
        </activity>

        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:exported="true"
            android:foregroundServiceType="mediaPlayback"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true"
            tools:ignore="Instantiatable">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

Se for necessário manter uma `MainActivity` customizada, ela deve herdar de
`AudioServiceActivity`:

```kotlin
package app.meraki.meraki

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
```

Nesse caso, preserve `android:name=".MainActivity"` no manifesto.

## Scoped storage

`READ_MEDIA_AUDIO` não transforma URIs retornadas pelo Storage Access Framework em
caminhos comuns. A função Rust `scan_local_music` aceita apenas diretórios visíveis
no filesystem do processo. Para uma biblioteca escolhida pelo usuário em Android,
a camada Flutter deverá manter a permissão persistente do URI e oferecer os arquivos
ao Rust via descritores ou por um cache privado. Não tente converter `content://`
para um caminho `/storage/...`.

## Servidor HTTP local

Prefira HTTPS para o Subsonic. Se um servidor de desenvolvimento oferecer somente
HTTP, use uma `network_security_config` restrita ao host de desenvolvimento; não
ative `usesCleartextTraffic="true"` globalmente em produção.

