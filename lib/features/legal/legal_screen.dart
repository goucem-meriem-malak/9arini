import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ctx.dart';
import '../../core/theme/tokens.dart';

/// Shows assets/legal/{doc}_{lang}.md with a tiny markdown subset (#, ##, text).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});
  final String doc;

  @override
  Widget build(BuildContext context) {
    final safe = (doc == 'terms' || doc == 'privacy') ? doc : 'terms';
    return Scaffold(
      appBar: AppBar(title: Text(context.t(safe == 'terms' ? 'terms' : 'privacy'))),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/${safe}_${context.lang}.md'),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lines = snap.data!.split('\n');
          return ListView(padding: const EdgeInsets.all(Sp.l), children: [
            for (final l in lines)
              if (l.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: l.startsWith('#') ? Sp.l : 0, bottom: Sp.s),
                  child: l.startsWith('## ')
                      ? Text(l.substring(3), style: context.tx.titleMedium)
                      : l.startsWith('# ')
                          ? Text(l.substring(2), style: context.tx.headlineMedium)
                          : Text(l, style: context.tx.bodyLarge),
                ),
            const SizedBox(height: Sp.xxl),
          ]);
        },
      ),
    );
  }
}
