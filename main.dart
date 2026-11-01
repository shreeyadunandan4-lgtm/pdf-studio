import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const PdfStudio());

const kPurple = Color(0xFF6C3CE9);
const kNavy = Color(0xFF1B1464);

class PdfStudio extends StatelessWidget {
  const PdfStudio({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PDF Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kPurple,
        ),
        home: const Home(),
      );
}

// ---------- PDF helpers ----------
Future<Uint8List> buildPdf(List<Uint8List> pages) async {
  final doc = pw.Document();
  for (final p in pages) {
    final img = pw.MemoryImage(p);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
    ));
  }
  return doc.save();
}

Future<List<Uint8List>> rasterPdf(Uint8List bytes) async {
  final out = <Uint8List>[];
  await for (final r in Printing.raster(bytes, dpi: 130)) {
    out.add(await r.toPng());
  }
  return out;
}

void showLoading(BuildContext c) => showDialog(
      context: c,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
    .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

void optionSheet(BuildContext c, String title,
    List<(IconData, String, VoidCallback)> items) {
  showModalBottomSheet<void>(
    context: c,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final it in items)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pop(c);
                        it.$3();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: kPurple.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(children: [
                          Icon(it.$1, size: 36, color: kPurple),
                          const SizedBox(height: 8),
                          Text(it.$2,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]),
      ),
    ),
  );
}

// ---------- Home ----------
class Home extends StatelessWidget {
  const Home({super.key});

  Future<void> openPdf(BuildContext c) async {
    const group = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf']);
    final f = await openFile(acceptedTypeGroups: [group]);
    if (f == null) return;
    final data = await f.readAsBytes();
    showLoading(c);
    try {
      final pages = await rasterPdf(data);
      if (!c.mounted) return;
      Navigator.pop(c);
      Navigator.push(c, MaterialPageRoute(
          builder: (_) => Editor(initial: pages, title: f.name)));
    } catch (e) {
      if (c.mounted) {
        Navigator.pop(c);
        toast(c, 'PDF open nahi ho paayi');
      }
    }
  }

  Widget card(IconData icon, String t, String s, VoidCallback f) => InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: f,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kNavy, kPurple, Color(0xFFB57BFF)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Spacer(),
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text('PDF Studio',
                    style: TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Banao, dekho aur badhao — bilkul offline.',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
                const Spacer(),
                card(Icons.add_circle_outline, 'Create PDF',
                    'Photo ya type karke naya PDF banao', () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const Editor(initial: [], title: 'New PDF')));
                }),
                const SizedBox(height: 16),
                card(Icons.folder_open_rounded, 'Open PDF',
                    'PDF kholo aur usme aur pages jodo', () => openPdf(context)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      );
}

// ---------- Editor ----------
class Editor extends StatefulWidget {
  final List<Uint8List> initial;
  final String title;
  const Editor({super.key, required this.initial, required this.title});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final List<Uint8List> pages = List.of(widget.initial);
  final picker = ImagePicker();

  Future<void> addImage(ImageSource s) async {
    final f = await picker.pickImage(source: s, imageQuality: 85, maxWidth: 2000);
    if (f == null) return;
    final b = await f.readAsBytes();
    setState(() => pages.add(b));
  }

  Future<void> addType() async {
    final r = await Navigator.push<Uint8List>(
        context, MaterialPageRoute(builder: (_) => const TypePage()));
    if (r != null) setState(() => pages.add(r));
  }

  void chooseType() => optionSheet(context, 'Page kaise banana hai?', [
        (Icons.image_rounded, 'Image', () => optionSheet(context, 'Image kahan se?', [
              (Icons.photo_library_rounded, 'Gallery', () => addImage(ImageSource.gallery)),
              (Icons.photo_camera_rounded, 'Camera', () => addImage(ImageSource.camera)),
            ])),
        (Icons.text_fields_rounded, 'Type', addType),
      ]);

  Future<void> submit({bool share = false}) async {
    if (pages.isEmpty) {
      toast(context, 'Pehle kam se kam ek page banao');
      return;
    }
    showLoading(context);
    try {
      final bytes = await buildPdf(pages);
      final name = 'PDF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      if (!mounted) return;
      Navigator.pop(context);
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: name);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Kuch gadbad hui: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = pages.length + 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_rounded),
              onPressed: () => submit(share: true)),
        ],
      ),
      body: pages.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.note_add_rounded, size: 80, color: kPurple.withValues(alpha: .4)),
                const SizedBox(height: 12),
                const Text('Abhi koi page nahi hai',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
              ]),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1 / 1.4142),
              itemCount: pages.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => FullView(pages: pages, start: i))),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: kPurple.withValues(alpha: .15),
                          blurRadius: 14,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.memory(pages[i], fit: BoxFit.contain),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: CircleAvatar(
                            radius: 13,
                            backgroundColor: kPurple,
                            child: Text('${i + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12))),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton.filledTonal(
                          iconSize: 18,
                          onPressed: () => setState(() => pages.removeAt(i)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: chooseType,
                icon: const Icon(Icons.add_rounded),
                label: Text(pages.isEmpty ? 'Create 1st page' : 'Create page $n'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: () => submit(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Submit'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class FullView extends StatelessWidget {
  final List<Uint8List> pages;
  final int start;
  const FullView({super.key, required this.pages, required this.start});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PageView.builder(
          controller: PageController(initialPage: start),
          itemCount: pages.length,
          itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 5, child: Center(child: Image.memory(pages[i]))),
        ),
      );
}

// ---------- Type page ----------
class TypePage extends StatefulWidget {
  const TypePage({super.key});
  @override
  State<TypePage> createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  final key = GlobalKey();
  final ctrl = TextEditingController();
  Color bg = const Color(0xFFFFF8E7), fg = const Color(0xFF222222);
  String font = 'Poppins';
  double size = 22;
  static const fonts = [
    'Poppins', 'Playfair Display', 'Caveat', 'Lobster',
    'Pacifico', 'Roboto Mono', 'Noto Sans Devanagari',
  ];

  static const palette = <Color>[
    Colors.white, Color(0xFFFFF8E7), Color(0xFFFFE0E9), Color(0xFFE0F2FF),
    Color(0xFFE3F9E5), Color(0xFFEDE1FF), Color(0xFFFFE9B3), Color(0xFF222222),
    Colors.black, Colors.red, Colors.pink, Colors.purple, Colors.indigo,
    Colors.blue, Colors.teal, Colors.green, Colors.orange, Colors.brown,
    Colors.grey, Color(0xFF1B1464),
  ];

  Future<void> pick(Color cur, ValueChanged<Color> on) => showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in palette)
                GestureDetector(
                  onTap: () {
                    setState(() => on(c));
                    Navigator.pop(d);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Future<void> done() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200));
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 4);
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    if (mounted) Navigator.pop(context, d!.buffer.asUint8List());
  }

  Widget colorBtn(String label, Color c, VoidCallback f) => Expanded(
        child: OutlinedButton.icon(
          onPressed: f,
          icon: CircleAvatar(
              radius: 10,
              backgroundColor: c,
              child: const SizedBox()),
          label: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F2FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Type page'),
          actions: [
            TextButton.icon(
                onPressed: done,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done')),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 360,
                  height: 360 * 1.4142,
                  child: RepaintBoundary(
                    key: key,
                    child: Container(
                      color: bg,
                      padding: const EdgeInsets.all(24),
                      child: TextField(
                        controller: ctrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.getFont(font, fontSize: size, color: fg),
                        cursorColor: fg,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Yahan likho...',
                          hintStyle: GoogleFonts.getFont(font,
                              fontSize: size, color: fg.withValues(alpha: .35)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  colorBtn('Page color', bg, () => pick(bg, (c) => bg = c)),
                  const SizedBox(width: 10),
                  colorBtn('Text color', fg, () => pick(fg, (c) => fg = c)),
                ]),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in fonts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 6),
                          child: ChoiceChip(
                            label: Text(f, style: GoogleFonts.getFont(f)),
                            selected: font == f,
                            onSelected: (_) => setState(() => font = f),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(children: [
                  const Icon(Icons.format_size_rounded, size: 20),
                  Expanded(
                    child: Slider(
                      min: 12,
                      max: 60,
                      value: size,
                      onChanged: (v) => setState(() => size = v),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      );
}
