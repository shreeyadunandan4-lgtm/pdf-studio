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
                const Text('Zod PDF',
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
      if (dx < 0 && idx < doc.pages.length - 1) {
        dir = 1;
      } else if (dx > 0 && idx > 0) {
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
    setState(() {
      dir = d;
      ctrl.value = 0;
    });
    await finish(true);
  }

  Widget flat(int i) => Container(
        color: Colors.white,
        child: Image.memory(doc.pages[i], fit: BoxFit.contain, gaplessPlayback: true),
      );

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
