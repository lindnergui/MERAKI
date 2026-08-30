import 'package:flutter/material.dart';
import 'package:meraki/src/data/user_preferences.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// First-run screen that stores a display name locally, without an account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.userPreferences,
    required this.onCompleted,
    super.key,
  });

  final UserPreferences userPreferences;
  final ValueChanged<String> onCompleted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  var _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await widget.userPreferences.saveUserName(name);
      if (mounted) widget.onCompleted(name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar seu nome. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            final form = _WelcomeForm(
              nameController: _nameController,
              isSaving: _isSaving,
              onSubmitted: (_) => _continue(),
              onContinue: _continue,
            );

            return Padding(
              padding: EdgeInsets.all(desktop ? 28 : 20),
              child: desktop
                  ? Row(
                      children: <Widget>[
                        Expanded(child: Center(child: form)),
                        const SizedBox(width: 28),
                        const Expanded(flex: 6, child: _WelcomeArtwork()),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        const Expanded(flex: 4, child: _WelcomeArtwork()),
                        const SizedBox(height: 28),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(child: form),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeForm extends StatelessWidget {
  const _WelcomeForm({
    required this.nameController,
    required this.isSaving,
    required this.onSubmitted,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final bool isSaving;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIconsFill.musicNotes,
                    color: MerakiColors.deepPurple,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'MERAKI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),
          Text(
            'Escolha a trilha sonora da sua vida',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.04,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Como podemos chamar você?',
            style: TextStyle(color: MerakiColors.softText, fontSize: 16),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'Seu nome',
              prefixIcon: Icon(PhosphorIconsRegular.user),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isSaving ? null : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: MerakiColors.deepPurple,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MerakiColors.deepPurple,
                      ),
                    )
                  : const Text('Continuar'),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Seu nome fica salvo apenas neste dispositivo.',
            style: TextStyle(color: MerakiColors.softText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                MerakiColors.deepPurple,
                accent.withValues(alpha: 0.26),
                const Color(0xFF160D1B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                top: -120,
                right: -100,
                child: _Orb(size: 470, color: accent.withValues(alpha: 0.30)),
              ),
              Positioned(
                right: -185,
                bottom: -195,
                child: _Orb(
                  size: 520,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _OrbitPainter(color: accent)),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(34),
                  child: Text(
                    'Sua música.\nSeu momento.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height * 0.42),
        width: size.width * 1.08,
        height: size.width * 1.08,
      ),
      1.75,
      2.8,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, 0),
      Offset(size.width * 0.50, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
