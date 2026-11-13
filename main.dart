import 'dart:async';
import 'dart:math' as math;
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
        title: 'Zod PDF',
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
    XFile? f;
    try {
      f = await openFile();
    } catch (e) {
      toast(c, 'File chunne me dikkat: $e');
      return;
    }
    if (f == null) return;
    final file = f;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      toast(c, 'Ye PDF file nahi hai, koi .pdf file chuno');
      return;
    }
    showLoading(c);
    Uint8List? data;
    try {
      data = await file.readAsBytes();
    } catch (e) {
      if (c.mounted) {
        Navigator.pop(c);
        toast(c, 'File padh nahi paaye: $e');
      }
      return;
    }
    if (!c.mounted) return;
    Navigator.pop(c);
    final doc = PdfDoc();
    doc.start(data!);
    Navigator.push(c, MaterialPageRoute(
        builder: (_) => Reader(doc: doc, title: file.name)));
  }

  Widget card(IconData icon, String t, String s, VoidCallback f) => Appear(
      delay: t == 'Create PDF' ? 500 : 700,
      child: InkWell(
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
      ));

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
                const AnimatedLogo(),
                const SizedBox(height: 16),
                const Appear(
                    delay: 150,
                    child: Text('Zod PDF',
                        style: TextStyle(
                            color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
                const SizedBox(height: 6),
                const Appear(
                    delay: 300,
                    child: Text('Banao, dekho aur badhao — bilkul offline.',
                        style: TextStyle(color: Colors.white70, fontSize: 15))),
                const Spacer(),
                card(Icons.add_circle_outline, 'Create PDF',
                    'Photo ya type karke naya PDF banao', () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const Editor(initial: [], title: 'New PDF')));
                }),
                const SizedBox(height: 16),
                card(Icons.folder_open_rounded, 'Open PDF',
                    'Kisi bhi PDF ko kitab ki tarah padho', () => openPdf(context)),
                const SizedBox(height: 28),
                const Center(child: Founder(color: Colors.white70)),
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
    if (!mounted) return;
    final r = await Navigator.push<Uint8List>(context,
        MaterialPageRoute(builder: (_) => ImageEditPage(bytes: b, title: 'Photo edit')));
    if (r != null && mounted) setState(() => pages.add(r));
  }

  Future<void> editPage(int i) async {
    final r = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
            builder: (_) => ImageEditPage(bytes: pages[i], title: 'Page ${i + 1} edit')));
    if (r != null && mounted) setState(() => pages[i] = r);
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
                        bottom: 4,
                        child: IconButton.filled(
                          iconSize: 18,
                          tooltip: 'Edit',
                          onPressed: () => editPage(i),
                          icon: const Icon(Icons.edit_rounded),
                        ),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
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
            const Founder(),
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

// ---------- Founder footer ----------
class Founder extends StatelessWidget {
  final Color color;
  const Founder({super.key, this.color = Colors.black45});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('Founder :- Nawal Gurj4r',
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 12, letterSpacing: .6)),
      );
}

// ---------- PDF loader (page by page) ----------
class PdfDoc extends ChangeNotifier {
  final pages = <Uint8List>[];
  bool done = false;
  String? error;

  Future<void> start(Uint8List bytes) async {
    try {
      await for (final r in Printing.raster(bytes, dpi: 160)) {
        pages.add(await r.toPng());
        notifyListeners();
      }
    } catch (e) {
      error = '$e';
    }
    done = true;
    notifyListeners();
  }
}

// ---------- Reader with book page flip ----------
class Reader extends StatefulWidget {
  final PdfDoc doc;
  final String title;
  const Reader({super.key, required this.doc, required this.title});
  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  int idx = 0;
  int dir = 0; // 1 = aage, -1 = peeche
  bool busy = false;
  bool cornerBottom = true;
  final imgs = <int, ui.Image>{};
  final loading = <int>{};
  PdfDoc get doc => widget.doc;

  @override
  void initState() {
    super.initState();
    doc.addListener(prefetch);
    prefetch();
  }

  Future<ui.Image> decodeImg(Uint8List b) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(b, c.complete);
    return c.future;
  }

  Future<void> ensure(int i) async {
    if (i < 0 || i >= doc.pages.length) return;
    if (imgs.containsKey(i) || loading.contains(i)) return;
    loading.add(i);
    try {
      imgs[i] = await decodeImg(doc.pages[i]);
    } catch (_) {}
    loading.remove(i);
    if (mounted) setState(() {});
  }

  void prefetch() {
    for (final i in [idx - 1, idx, idx + 1]) {
      ensure(i);
    }
    final old = imgs.keys.where((k) => (k - idx).abs() > 2).toList();
    for (final k in old) {
      imgs.remove(k)?.dispose();
    }
  }

  @override
  void dispose() {
    doc.removeListener(prefetch);
    ctrl.dispose();
    super.dispose();
  }

  void turnUpdate(double dx, double w) {
    if (busy) return;
    if (dir == 0) {
      if (dx < 0 && idx < doc.pages.length - 1 &&
          imgs[idx] != null && imgs[idx + 1] != null) {
        dir = 1;
      } else if (dx > 0 && idx > 0 &&
          imgs[idx - 1] != null && imgs[idx] != null) {
        dir = -1;
      } else {
        return;
      }
      ctrl.value = 0;
    }
    final change = (dir == 1 ? -dx : dx) / w;
    ctrl.value = (ctrl.value + change).clamp(0.0, 1.0).toDouble();
    setState(() {});
  }

  void turnEnd(double v) {
    if (busy || dir == 0) return;
    final go = ctrl.value > .5 || (dir == 1 ? v < -600 : v > 600);
    finish(go);
  }

  // ---- zoom (2 ungli) ----
  double zoom = 1, baseZoom = 1;
  Offset pan = Offset.zero, basePan = Offset.zero, startFocal = Offset.zero;
  Size boxSize = Size.zero;
  bool pinching = false;

  void clampPan() {
    final mx = (zoom - 1) * boxSize.width / 2;
    final my = (zoom - 1) * boxSize.height / 2;
    pan = Offset(pan.dx.clamp(-mx, mx).toDouble(), pan.dy.clamp(-my, my).toDouble());
  }

  void resetZoom() {
    zoom = 1;
    pan = Offset.zero;
  }

  void scaleStart(ScaleStartDetails d) {
    baseZoom = zoom;
    basePan = pan;
    startFocal = d.localFocalPoint;
    pinching = false;
    cornerBottom = d.localFocalPoint.dy > boxSize.height / 2;
  }

  void scaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 && dir == 0 && !busy) {
      pinching = true;
      setState(() {
        zoom = (baseZoom * d.scale).clamp(1.0, 4.0).toDouble();
        pan = basePan + (d.localFocalPoint - startFocal);
        if (zoom <= 1.01) {
          resetZoom();
        } else {
          clampPan();
        }
      });
      return;
    }
    if (zoom > 1.01) {
      setState(() {
        pan += d.focalPointDelta;
        clampPan();
      });
      return;
    }
    if (pinching) return;
    turnUpdate(d.focalPointDelta.dx, boxSize.width);
  }

  void scaleEnd(ScaleEndDetails d) {
    turnEnd(d.velocity.pixelsPerSecond.dx);
  }

  void doubleTap() {
    if (busy || dir != 0) return;
    setState(() {
      if (zoom > 1.01) {
        resetZoom();
      } else {
        zoom = 2.2;
        clampPan();
      }
    });
  }

  Future<void> finish(bool go) async {
    busy = true;
    await ctrl.animateTo(go ? 1.0 : 0.0, curve: Curves.easeOutCubic);
    if (!mounted) return;
    setState(() {
      if (go) idx += dir;
      dir = 0;
      ctrl.value = 0;
      busy = false;
    });
    prefetch();
  }

  Future<void> turn(int d) async {
    if (busy || dir != 0) return;
    if (zoom > 1.01) setState(resetZoom);
    if (d == 1 && idx >= doc.pages.length - 1) return;
    if (d == -1 && idx <= 0) return;
    if (imgs[d == 1 ? idx : idx - 1] == null ||
        imgs[d == 1 ? idx + 1 : idx] == null) return;
    setState(() {
      dir = d;
      ctrl.value = 0;
    });
    await finish(true);
  }

  Widget flat(int i) {
    final im = imgs[i];
    return Container(
      color: Colors.white,
      child: im == null ? null : RawImage(image: im, fit: BoxFit.contain),
    );
  }

  Widget book() {
    if (dir == 0) return flat(idx);
    final topI = dir == 1 ? idx : idx - 1;
    final underI = dir == 1 ? idx + 1 : idx;
    if (topI < 0 || underI >= doc.pages.length) return flat(idx);
    final ti = imgs[topI];
    final ui2 = imgs[underI];
    if (ti == null || ui2 == null) return flat(idx);
    final p = ctrl.value;
    return CustomPaint(
      size: Size.infinite,
      painter: CurlPainter(ti, ui2, dir == 1 ? p : 1 - p, cornerBottom),
    );
  }

  void edit() {
    if (!doc.done) {
      toast(context, 'PDF abhi load ho rahi hai, thoda ruko');
      return;
    }
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => Editor(initial: List.of(doc.pages), title: widget.title)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF14102B),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(widget.title, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
                tooltip: 'Pages jodo / Save',
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: edit),
          ],
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([ctrl, doc]),
          builder: (context, _) {
            if (doc.pages.isEmpty) {
              return Center(
                child: doc.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('PDF open nahi hui:\n${doc.error}',
                            style: const TextStyle(color: Colors.white)))
                    : doc.done
                        ? const Text('PDF me koi page nahi mila',
                            style: TextStyle(color: Colors.white))
                        : const CircularProgressIndicator(),
              );
            }
            final n = doc.pages.length;
            return Column(children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    boxSize = Size(box.maxWidth, box.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: scaleStart,
                      onScaleUpdate: scaleUpdate,
                      onScaleEnd: scaleEnd,
                      onDoubleTap: doubleTap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: ClipRect(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.translationValues(pan.dx, pan.dy, 0)
                              ..scale(zoom, zoom, 1.0),
                            child: book(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    color: Colors.white,
                    onPressed: () => turn(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 32)),
                Text('${idx + 1} / $n${doc.done ? '' : '+'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                IconButton(
                    color: Colors.white,
                    onPressed: () => turn(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 32)),
              ]),
              const SafeArea(top: false, child: Founder(color: Colors.white54)),
            ]);
          },
        ),
      );
}

// ---------- Page curl painter ----------
class CurlPainter extends CustomPainter {
  final ui.Image top;
  final ui.Image under;
  final double t; // 0 = page seedha, 1 = page palat chuka
  final bool bottom;
  CurlPainter(this.top, this.under, this.t, this.bottom);

  void page(Canvas c, Rect r, ui.Image img) {
    c.drawRect(r, Paint()..color = Colors.white);
    paintImage(canvas: c, rect: r, image: img, fit: BoxFit.contain);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final w = size.width, h = size.height;
    if (t <= 0.003) {
      page(canvas, r, top);
      return;
    }
    if (t >= 0.997) {
      page(canvas, r, under);
      return;
    }
    page(canvas, r, under);

    final cy = bottom ? h : 0.0;
    final c0 = Offset(w, cy);
    final f = Offset(w - 2 * w * t,
        cy + (bottom ? -1 : 1) * 0.28 * h * math.sin(math.pi * t));
    final m = (c0 + f) / 2;
    var n = c0 - f;
    n = n / n.distance;
    final d = Offset(-n.dy, n.dx);
    final big = 3 * (w + h);

    final flatSide = Path()
      ..moveTo(m.dx + d.dx * big, m.dy + d.dy * big)
      ..lineTo(m.dx - d.dx * big, m.dy - d.dy * big)
      ..lineTo(m.dx - d.dx * big - n.dx * big, m.dy - d.dy * big - n.dy * big)
      ..lineTo(m.dx + d.dx * big - n.dx * big, m.dy + d.dy * big - n.dy * big)
      ..close();
    final huge = Rect.fromCenter(center: m, width: big * 2, height: big * 2);

    // reflection matrix about the fold line
    final a = 1 - 2 * n.dx * n.dx;
    final b = -2 * n.dx * n.dy;
    final dd = 1 - 2 * n.dy * n.dy;
    final k = 2 * (m.dx * n.dx + m.dy * n.dy);
    final mat = Matrix4(a, b, 0, 0, b, dd, 0, 0, 0, 0, 1, 0, k * n.dx, k * n.dy, 0, 1);
    final flapShape = (Path()..addRect(r)).transform(mat.storage);

    // 1) seedha reh gaya hissa
    canvas.save();
    canvas.clipRect(r);
    canvas.clipPath(flatSide);
    page(canvas, r, top);
    canvas.drawRect(
        huge,
        Paint()
          ..shader = ui.Gradient.linear(m, m - n * 30,
              [Colors.black.withValues(alpha: .30), Colors.transparent]));
    canvas.drawShadow(flapShape, Colors.black, 6, true);
    canvas.restore();

    // 2) mudaa hua hissa (page ka peeche wala side)
    canvas.save();
    canvas.clipRect(r);
    canvas.clipPath(flatSide);
    canvas.clipPath(flapShape);
    canvas.save();
    canvas.transform(mat.storage);
    page(canvas, r, top);
    canvas.restore();
    canvas.drawRect(huge, Paint()..color = Colors.white.withValues(alpha: .30));
    canvas.drawRect(
        huge,
        Paint()
          ..shader = ui.Gradient.linear(m, m - n * 40,
              [Colors.black.withValues(alpha: .38), Colors.transparent]));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CurlPainter o) =>
      o.t != t || o.top != top || o.under != under || o.bottom != bottom;
}

// ---------- Home animations ----------
class Appear extends StatelessWidget {
  final int delay;
  final Widget child;
  const Appear({super.key, required this.delay, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1400),
        curve: Interval(delay / 1400.0, 1.0, curve: Curves.easeOutCubic),
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(offset: Offset(0, 36 * (1 - v)), child: c),
        ),
        child: child,
      );
}

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});
  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(c.value);
          return SizedBox(
            width: 120,
            height: 120,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 92 + 10 * v,
                height: 92 + 10 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: .12 + .18 * v),
                        blurRadius: 24 + 22 * v)
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(0, -8 * v),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 58),
              ),
              Positioned(
                top: 6 - 4 * v,
                left: 22,
                child: Transform.rotate(
                  angle: -0.35 + 0.2 * v,
                  child: const Text('👑', style: TextStyle(fontSize: 26)),
                ),
              ),
              Positioned(
                top: 14,
                right: 12,
                child: Opacity(
                  opacity: v,
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFFFFE08A), size: 20),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 10,
                child: Opacity(
                  opacity: 1 - v,
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFFFFE08A), size: 15),
                ),
              ),
            ]),
          );
        },
      );
}


// ---------- Image edit page (crop / draw / text) ----------
const kInk = <Color>[
  Colors.black, Colors.white, Colors.red, Colors.pink, Colors.purple,
  Colors.indigo, Colors.blue, Colors.teal, Colors.green,
  Color(0xFFFFD600), Colors.orange, Colors.brown,
];

const kFonts = [
  'Poppins', 'Playfair Display', 'Caveat', 'Lobster',
  'Pacifico', 'Roboto Mono', 'Noto Sans Devanagari',
];

enum _EM { crop, draw, text }

enum _CH { none, tl, tr, bl, br, le, ri, to, bo, move }

class _Stroke {
  final List<Offset> pts; // 0..1 (image ke hisaab se)
  final Color color;
  final double width; // canvas width ka hissa
  _Stroke(this.pts, this.color, this.width);
}

class _TextItem {
  String text;
  Offset pos; // top-left, 0..1
  Color color;
  double size; // canvas width ka hissa
  String font;
  _TextItem(this.text, this.pos, this.color, this.size, this.font);
}

class _StrokePainter extends CustomPainter {
  final List<_Stroke> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size s) {
    for (final st in strokes) {
      Offset pt(int i) => Offset(st.pts[i].dx * s.width, st.pts[i].dy * s.height);
      final w = st.width * s.width;
      if (st.pts.length == 1) {
        canvas.drawCircle(pt(0), w / 2, Paint()..color = st.color);
        continue;
      }
      final path = Path()..moveTo(pt(0).dx, pt(0).dy);
      for (var i = 1; i < st.pts.length - 1; i++) {
        final a = pt(i), b = pt(i + 1);
        path.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      }
      final last = pt(st.pts.length - 1);
      path.lineTo(last.dx, last.dy);
      canvas.drawPath(
          path,
          Paint()
            ..color = st.color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = w);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

class _CropPainter extends CustomPainter {
  final Rect c; // 0..1
  _CropPainter(this.c);

  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTRB(
        c.left * s.width, c.top * s.height, c.right * s.width, c.bottom * s.height);
    final dim = Path()
      ..addRect(Offset.zero & s)
      ..addRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black54);
    canvas.drawRect(
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    final thin = Paint()
      ..color = Colors.white54
      ..strokeWidth = .8;
    for (var i = 1; i < 3; i++) {
      final x = r.left + r.width * i / 3, y = r.top + r.height * i / 3;
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), thin);
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), thin);
    }
    final pts = <Offset>[
      r.topLeft, r.topRight, r.bottomLeft, r.bottomRight,
      r.centerLeft, r.centerRight, r.topCenter, r.bottomCenter,
    ];
    for (final o in pts) {
      canvas.drawCircle(o, 9, Paint()..color = Colors.white);
      canvas.drawCircle(o, 6, Paint()..color = kPurple);
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.c != c;
}

class ImageEditPage extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  const ImageEditPage({super.key, required this.bytes, required this.title});
  @override
  State<ImageEditPage> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends State<ImageEditPage> {
  static const _full = Rect.fromLTWH(0, 0, 1, 1);

  late Uint8List bytes, original;
  Size? imgSize;
  Rect crop = _full;
  _EM mode = _EM.crop;
  _CH _ch = _CH.none;
  final strokes = <_Stroke>[];
  final texts = <_TextItem>[];
  _TextItem? sel;
  Color drawColor = Colors.red;
  double drawW = .01;
  Color textColor = Colors.black;
  double textSize = .06;
  String textFont = 'Poppins';
  bool exporting = false, busy = false;
  final boundaryKey = GlobalKey();

  bool get fullCrop =>
      crop.left < .001 && crop.top < .001 && crop.right > .999 && crop.bottom > .999;

  bool get dirty =>
      !identical(bytes, original) || strokes.isNotEmpty || texts.isNotEmpty;

  @override
  void initState() {
    super.initState();
    bytes = widget.bytes;
    original = widget.bytes;
    _load();
  }

  Future<void> _load() async {
    try {
      final im = await decodeImageFromList(bytes);
      if (!mounted) return;
      setState(() {
        imgSize = Size(im.width.toDouble(), im.height.toDouble());
        crop = _full;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, 'Image khul nahi paayi: $e');
      Navigator.pop(context);
    }
  }

  Offset _n(Offset p, double w, double h) =>
      Offset((p.dx / w).clamp(0.0, 1.0).toDouble(), (p.dy / h).clamp(0.0, 1.0).toDouble());

  // Poora canvas (photo + likha hua + text) ek image me
  Future<ui.Image> _capture() async {
    setState(() => exporting = true);
    await WidgetsBinding.instance.endOfFrame;
    final b = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var ratio = imgSize!.width / b.size.width;
    final longest = math.max(b.size.width, b.size.height) * ratio;
    if (longest > 2400) ratio *= 2400 / longest;
    final img = await b.toImage(pixelRatio: ratio);
    if (mounted) setState(() => exporting = false);
    return img;
  }

  Future<void> applyCrop() async {
    if (busy || fullCrop) return;
    busy = true;
    try {
      final full = await _capture();
      final src = Rect.fromLTRB(crop.left * full.width, crop.top * full.height,
          crop.right * full.width, crop.bottom * full.height);
      final w = math.max(1, src.width.round());
      final h = math.max(1, src.height.round());
      final rec = ui.PictureRecorder();
      Canvas(rec).drawImageRect(full, src,
          Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          Paint()..filterQuality = FilterQuality.high);
      final out = await rec.endRecording().toImage(w, h);
      final d = await out.toByteData(format: ui.ImageByteFormat.png);
      final nb = d!.buffer.asUint8List();
      final im = await decodeImageFromList(nb);
      if (!mounted) return;
      setState(() {
        bytes = nb;
        imgSize = Size(im.width.toDouble(), im.height.toDouble());
        strokes.clear();
        texts.clear();
        sel = null;
        crop = _full;
      });
    } catch (e) {
      if (mounted) toast(context, 'Crop nahi hua: $e');
    } finally {
      busy = false;
    }
  }

  Future<void> done() async {
    if (busy) return;
    if (mode == _EM.crop && !fullCrop) await applyCrop();
    if (!mounted) return;
    if (!dirty) {
      Navigator.pop(context, original);
      return;
    }
    busy = true;
    showLoading(context);
    try {
      final img = await _capture();
      final d = await img.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.pop(context); // loading
      Navigator.pop(context, d!.buffer.asUint8List());
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Save nahi hua: $e');
      }
    } finally {
      busy = false;
    }
  }

  void resetAll() {
    setState(() {
      bytes = original;
      strokes.clear();
      texts.clear();
      sel = null;
      crop = _full;
    });
    _load();
  }

  void _dragCrop(Offset d) {
    const m = .08;
    double l = crop.left, t = crop.top, r = crop.right, b = crop.bottom;
    if (_ch == _CH.none) return;
    if (_ch == _CH.move) {
      final w = r - l, h = b - t;
      l = (l + d.dx).clamp(0.0, 1 - w).toDouble();
      t = (t + d.dy).clamp(0.0, 1 - h).toDouble();
      r = l + w;
      b = t + h;
    } else {
      final mL = const {_CH.tl, _CH.bl, _CH.le}.contains(_ch);
      final mR = const {_CH.tr, _CH.br, _CH.ri}.contains(_ch);
      final mT = const {_CH.tl, _CH.tr, _CH.to}.contains(_ch);
      final mB = const {_CH.bl, _CH.br, _CH.bo}.contains(_ch);
      if (mL) l = (l + d.dx).clamp(0.0, r - m).toDouble();
      if (mR) r = (r + d.dx).clamp(l + m, 1.0).toDouble();
      if (mT) t = (t + d.dy).clamp(0.0, b - m).toDouble();
      if (mB) b = (b + d.dy).clamp(t + m, 1.0).toDouble();
    }
    crop = Rect.fromLTRB(l, t, r, b);
  }

  Widget cropLayer(double w, double h) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final p = d.localPosition;
          final r = Rect.fromLTRB(
              crop.left * w, crop.top * h, crop.right * w, crop.bottom * h);
          const t = 28.0;
          bool nx(double x) => (p.dx - x).abs() < t;
          bool ny(double y) => (p.dy - y).abs() < t;
          final inX = p.dx > r.left - t && p.dx < r.right + t;
          final inY = p.dy > r.top - t && p.dy < r.bottom + t;
          if (nx(r.left) && ny(r.top)) {
            _ch = _CH.tl;
          } else if (nx(r.right) && ny(r.top)) {
            _ch = _CH.tr;
          } else if (nx(r.left) && ny(r.bottom)) {
            _ch = _CH.bl;
          } else if (nx(r.right) && ny(r.bottom)) {
            _ch = _CH.br;
          } else if (nx(r.left) && inY) {
            _ch = _CH.le;
          } else if (nx(r.right) && inY) {
            _ch = _CH.ri;
          } else if (ny(r.top) && inX) {
            _ch = _CH.to;
          } else if (ny(r.bottom) && inX) {
            _ch = _CH.bo;
          } else if (r.contains(p)) {
            _ch = _CH.move;
          } else {
            _ch = _CH.none;
          }
        },
        onPanUpdate: (d) {
          if (_ch == _CH.none) return;
          setState(() => _dragCrop(Offset(d.delta.dx / w, d.delta.dy / h)));
        },
        onPanEnd: (_) => _ch = _CH.none,
        child: CustomPaint(painter: _CropPainter(crop), size: Size.infinite),
      );

  Widget drawLayer(double w, double h) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => setState(
            () => strokes.add(_Stroke([_n(d.localPosition, w, h)], drawColor, drawW))),
        onPanStart: (d) => setState(
            () => strokes.add(_Stroke([_n(d.localPosition, w, h)], drawColor, drawW))),
        onPanUpdate: (d) {
          if (strokes.isEmpty) return;
          setState(() => strokes.last.pts.add(_n(d.localPosition, w, h)));
        },
      );

  Future<void> textDialog({_TextItem? t}) async {
    final c = TextEditingController(text: t?.text ?? '');
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(t == null ? 'Text likho' : 'Text badlo'),
        content: TextField(
          controller: c,
          autofocus: true,
          minLines: 1,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Yahan likho...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
    if (r == null || r.isEmpty || !mounted) return;
    setState(() {
      if (t != null) {
        t.text = r;
      } else {
        final n = _TextItem(r, const Offset(.12, .4), textColor, textSize, textFont);
        texts.add(n);
        sel = n;
      }
    });
  }

  Widget canvasContent(double w, double h) => Stack(fit: StackFit.expand, children: [
        Image.memory(bytes,
            fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.high),
        CustomPaint(painter: _StrokePainter(strokes)),
        if (mode == _EM.text)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => sel = null),
            ),
          ),
        for (final t in texts)
          Positioned(
            left: t.pos.dx * w,
            top: t.pos.dy * h,
            child: IgnorePointer(
              ignoring: mode != _EM.text,
              child: GestureDetector(
                onTap: () => setState(() => sel = t),
                onDoubleTap: () => textDialog(t: t),
                onPanStart: (_) => setState(() => sel = t),
                onPanUpdate: (d) => setState(() {
                  t.pos = Offset(
                    (t.pos.dx + d.delta.dx / w).clamp(-.1, .95).toDouble(),
                    (t.pos.dy + d.delta.dy / h).clamp(-.05, .95).toDouble(),
                  );
                }),
                child: Container(
                  constraints: BoxConstraints(maxWidth: w * .9),
                  padding: const EdgeInsets.all(4),
                  decoration: (sel == t && !exporting)
                      ? BoxDecoration(
                          border: Border.all(color: kPurple, width: 1.5),
                          borderRadius: BorderRadius.circular(4))
                      : null,
                  child: Text(t.text,
                      style: GoogleFonts.getFont(t.font,
                          fontSize: t.size * w, color: t.color)),
                ),
              ),
            ),
          ),
      ]);

  Widget colorRow(Color cur, ValueChanged<Color> on) => SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in kInk)
            GestureDetector(
              onTap: () => on(c),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: cur == c ? kPurple : Colors.black26,
                      width: cur == c ? 3 : 1.5),
                ),
              ),
            ),
        ]),
      );

  Widget modePanel() {
    switch (mode) {
      case _EM.crop:
        return Column(children: [
          const Text('Kone ya kinare kheench kar kisi bhi size me crop karo',
              style: TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: fullCrop ? null : () => setState(() => crop = _full),
                  child: const Text('Reset')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                  onPressed: fullCrop ? null : applyCrop,
                  icon: const Icon(Icons.crop_rounded),
                  label: const Text('Crop lagao')),
            ),
          ]),
        ]);
      case _EM.draw:
        return Column(children: [
          colorRow(drawColor, (c) => setState(() => drawColor = c)),
          Row(children: [
            const Icon(Icons.brush_rounded, size: 20),
            Expanded(
              child: Slider(
                  min: .004,
                  max: .04,
                  value: drawW,
                  onChanged: (v) => setState(() => drawW = v)),
            ),
            IconButton(
                tooltip: 'Undo',
                onPressed: strokes.isEmpty
                    ? null
                    : () => setState(() => strokes.removeLast()),
                icon: const Icon(Icons.undo_rounded)),
            IconButton(
                tooltip: 'Sab mitao',
                onPressed:
                    strokes.isEmpty ? null : () => setState(() => strokes.clear()),
                icon: const Icon(Icons.delete_sweep_rounded)),
          ]),
        ]);
      case _EM.text:
        final cur = sel;
        return Column(children: [
          Row(children: [
            Expanded(
              child: FilledButton.tonalIcon(
                  onPressed: () => textDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Text jodo')),
            ),
            if (cur != null) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  tooltip: 'Text badlo',
                  onPressed: () => textDialog(t: cur),
                  icon: const Icon(Icons.edit_rounded)),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  tooltip: 'Delete',
                  onPressed: () => setState(() {
                        texts.remove(cur);
                        sel = null;
                      }),
                  icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ]),
          colorRow(cur?.color ?? textColor, (c) => setState(() {
                textColor = c;
                cur?.color = c;
              })),
          Row(children: [
            const Icon(Icons.format_size_rounded, size: 20),
            Expanded(
              child: Slider(
                  min: .02,
                  max: .15,
                  value: cur?.size ?? textSize,
                  onChanged: (v) => setState(() {
                        textSize = v;
                        cur?.size = v;
                      })),
            ),
          ]),
          SizedBox(
            height: 42,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final f in kFonts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: GoogleFonts.getFont(f)),
                    selected: (cur?.font ?? textFont) == f,
                    onSelected: (_) => setState(() {
                      textFont = f;
                      cur?.font = f;
                    }),
                  ),
                ),
            ]),
          ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = imgSize;
    if (size == null) {
      return const Scaffold(
          backgroundColor: Color(0xFF14121F),
          body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Changes hata dein?'),
            content: const Text('Jo edit kiya hai wo save nahi hoga.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(d, false), child: const Text('Nahi')),
              FilledButton(
                  onPressed: () => Navigator.pop(d, true),
                  child: const Text('Haan, hatao')),
            ],
          ),
        );
        if (ok == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF14121F),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(widget.title, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
                tooltip: 'Sab reset',
                onPressed: dirty ? resetAll : null,
                icon: const Icon(Icons.restart_alt_rounded)),
            TextButton.icon(
                onPressed: done,
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: const Text('Done', style: TextStyle(color: Colors.white))),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: LayoutBuilder(builder: (_, cs) {
              final aw = math.max(50.0, cs.maxWidth - 32);
              final ah = math.max(50.0, cs.maxHeight - 32);
              final sc = math.min(aw / size.width, ah / size.height);
              final w = size.width * sc, h = size.height * sc;
              return Center(
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(clipBehavior: Clip.none, children: [
                    RepaintBoundary(key: boundaryKey, child: canvasContent(w, h)),
                    if (mode == _EM.crop) Positioned.fill(child: cropLayer(w, h)),
                    if (mode == _EM.draw) Positioned.fill(child: drawLayer(w, h)),
                  ]),
                ),
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SegmentedButton<_EM>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: _EM.crop,
                        icon: Icon(Icons.crop_rounded),
                        label: Text('Crop')),
                    ButtonSegment(
                        value: _EM.draw,
                        icon: Icon(Icons.brush_rounded),
                        label: Text('Draw')),
                    ButtonSegment(
                        value: _EM.text,
                        icon: Icon(Icons.text_fields_rounded),
                        label: Text('Text')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) async {
                    if (mode == _EM.crop && !fullCrop) await applyCrop();
                    if (!mounted) return;
                    setState(() {
                      mode = s.first;
                      sel = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                modePanel(),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
