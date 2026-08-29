import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.libraryController, super.key});

  final LibraryController libraryController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _directoryController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _directoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: AnimatedBuilder(
        animation: widget.libraryController,
        builder: (context, _) {
          final controller = widget.libraryController;
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: <Widget>[
                    Text(
                      'Servidor Subsonic',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As credenciais são usadas somente para sincronizar o catálogo. '
                      'A senha não é enviada ao banco local.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _serverUrlController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'URL do servidor',
                              hintText: 'https://subsonic.exemplo.com',
                              prefixIcon: Icon(Icons.language_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateServerUrl,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuário',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _passwordVisible
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: () {
                                  setState(
                                    () => _passwordVisible = !_passwordVisible,
                                  );
                                },
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _requiredValidator,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: controller.isSyncingSubsonic
                          ? null
                          : _syncSubsonic,
                      icon: controller.isSyncingSubsonic
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        controller.isSyncingSubsonic
                            ? 'Testando e sincronizando…'
                            : 'Testar conexão e sincronizar',
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Músicas locais',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha uma pasta para indexar músicas do dispositivo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _directoryController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Pasta de músicas',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.folder_outlined),
                        suffixIcon: IconButton(
                          tooltip: 'Selecionar pasta',
                          onPressed: controller.isScanningLocal
                              ? null
                              : _pickDirectory,
                          icon: const Icon(Icons.folder_open_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: controller.isScanningLocal
                          ? null
                          : _scanDirectory,
                      icon: const Icon(Icons.library_music_rounded),
                      label: const Text('Varrer músicas locais'),
                    ),
                    if (controller.isScanningLocal) ...<Widget>[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Lendo arquivos e metadados…'),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDirectory() async {
    try {
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Escolha sua pasta de músicas',
      );
      if (directory != null && mounted) {
        _directoryController.text = directory;
      }
    } catch (error) {
      _showError('Não foi possível abrir o seletor de pasta: $error');
    }
  }

  Future<void> _scanDirectory() async {
    final directory = _directoryController.text.trim();
    if (directory.isEmpty) {
      _showError('Escolha uma pasta de músicas antes de iniciar a varredura.');
      return;
    }

    try {
      await widget.libraryController.scanLocalMusic(directory);
      if (mounted) {
        _showMessage('Músicas locais atualizadas com sucesso.');
      }
    } catch (_) {
      _showError(
        widget.libraryController.errorMessage ??
            'Não foi possível ler a pasta.',
      );
    }
  }

  Future<void> _syncSubsonic() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await widget.libraryController.syncSubsonic(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        _showMessage('Conexão validada e catálogo Subsonic sincronizado.');
      }
    } catch (_) {
      _showError(
        widget.libraryController.errorMessage ??
            'Não foi possível conectar ao servidor Subsonic.',
      );
    }
  }

  String? _validateServerUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Informe uma URL válida do servidor.';
    }
    return null;
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Este campo é obrigatório.'
        : null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
