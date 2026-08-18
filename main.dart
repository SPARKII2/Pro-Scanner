import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_scanner/Save.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorkey,
      title: 'Pro Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<String> secilenresimler = [];
  bool secimModu = false;
  bool pdfMode = false;
  bool photoMode = false;
  bool fileMode = false;
  late DocumentScanner _documentScanner;

  List<FileSystemEntity> _pdfkayit = [];
  // ignore: prefer_final_fields
  List<Directory> _dir = [];
  Future<void> pdfKayit(Directory dir) async {
    Directory mainDir = await getApplicationCacheDirectory();
    if(_dir.isEmpty){
      _dir.add(mainDir);
    }
    var content = mainDir.listSync();
    if (mainDir.path != dir.path) {
      _dir.add(dir);
      setState(() {
        content = dir.listSync();
        _pdfkayit = content
            .where((file) => file.path.endsWith(".pdf"))
            .map((file) => File(file.path))
            .toList();
      });
    } else {
        Directory path = Directory("${mainDir.path}/pdf");
        if(! await path.exists()){
          await path.create(recursive: true);
        }
        final content2 = path.listSync();
        _pdfkayit = content2;
      setState(() {
        _pdfkayit += content.where((file) => file.path.endsWith(".pdf")).toList();
      });
    }
  }

  Future<void> back() async{
    if(_dir.length > 1){
      _dir.removeLast();
      final pervFolder = _dir.last;
      await pdfKayit(pervFolder);
    }
    else{
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          title: const Text("Do you want to close the app!!" ,style: TextStyle(color: Colors.black),),
          actions: [TextButton(onPressed: (){Navigator.pop(context,null);}, child: const Text("Cancel",style: TextStyle(color: Colors.greenAccent),)),
          TextButton(onPressed: (){SystemNavigator.pop();}, child: const Text("Yes" , style: TextStyle(color: Colors.red),))],
        );
      });
    }
  }
  List<File> _photokayit = [];
  Future<void> photokayit() async {
    final klasor = await getApplicationDocumentsDirectory();
    final dosyalar = klasor.listSync();
    setState(() {
      _photokayit = dosyalar
          .where(
            (dosya) =>
                dosya.path.toLowerCase().endsWith(".jpg") ||
                dosya.path.toLowerCase().endsWith("jpeg"),
          )
          .map((dosya) => File(dosya.path))
          .toList();
    });
  }

  Future<Directory> getDir() async {
    // ignore: no_leading_underscores_for_local_identifiers
    Directory _dir = await getApplicationCacheDirectory();
    return _dir;
  }

  @override
  void initState() {
    super.initState();
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: 1000,
      ),
    );
    photokayit();
    // ignore: no_leading_underscores_for_local_identifiers
    getDir().then((Directory _dir) {
      pdfKayit(_dir);
    });
  }

  @override
  void dispose() {
    _documentScanner.close();
    super.dispose();
  }

  Future<void> belgeTara() async {
    try {
      final result = await _documentScanner.scanDocument();
      if (result.images != null && result.images!.isNotEmpty) {
        await Jpgservisi().jpg_kaydet(result.images!);
        setState(() {
          //_resimYolu.addAll(result.images!);
        });
        await photokayit();
      }
    } catch (e) {
      debugPrint("Tarama Hatasi: $e");
    }
    pdfKayit(await getApplicationCacheDirectory());
    photokayit();
  }

  Future<void> karTara() async {
    try {
      final result = await _documentScanner.scanDocument();
      if (result.images != null && result.images!.isNotEmpty) {
        await kartServisi().kart_kaydet(result.images!);
        setState(() {});
      }
    } catch (e) {
      debugPrint("Tarama Hatasi: $e");
    }
    photokayit();
    pdfKayit(await getApplicationCacheDirectory());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child:PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop , result)async{
        if (didPop) return;
        if(secimModu){
          secimModu = false;
          secilenresimler = [];
          pdfMode = false;
          photoMode = false;
        }
        else{
        await back();}
        setState(() {
          
        });
      },
      child: 
       Scaffold(
        appBar: AppBar(
          title: const Text("Pro Scanner"),
          centerTitle: true,
          backgroundColor: Colors.greenAccent,
          leading: secimModu
              ? IconButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext dialolgcontext) {
                        return AlertDialog(
                          title: const Text("Delete File"),
                          content: const Text(
                            "Are You Sure You Want To DELETE This File?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialolgcontext);
                              },
                              child: const Text(
                                "No",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                for (
                                  int i = 0;
                                  i < secilenresimler.length;
                                  i++
                                ) {
                                  
                                  final dosya = File(secilenresimler[i]);
                                  if(dosya.path.endsWith('.pdf') || dosya.path.endsWith(".jpg") || dosya.path.endsWith(".jpeg")){
                                  if (await dosya.exists()) {
                                    await dosya.delete();
                                  }}
                                  else{
                                   final path = Directory(dosya.path);
                                   if(await path.exists()){
                                    await path.delete(recursive: true);
                                   }
                                  }
                                }
                                await pdfKayit(
                                  await getApplicationCacheDirectory(),
                                );
                                await photokayit();
                                // ignore: use_build_context_synchronously
                                Navigator.pop(dialolgcontext);
                              },
                              child: const Text(
                                "Yes",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    setState(() {
                      secimModu = false;
                      secilenresimler.clear();
                      photoMode = false;
                      pdfMode = false;
                      fileMode = false;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                )
              : null,
          actions: [
            if (secimModu && secilenresimler.isNotEmpty && !fileMode)
              IconButton(
                onPressed: () async {
                  List<XFile> paylas = secilenresimler
                      .map((path) => XFile(path))
                      .toList();
                  final params = ShareParams(files: paylas);
                  SharePlus.instance.share(params);
                  setState(() {
                    secimModu = false;
                    secilenresimler.clear();
                    photoMode = false;
                    fileMode = false;
                    pdfMode = false;
                  });
                },
                icon: const Icon(Icons.share, color: Colors.black),
              ),
              if(secimModu && secilenresimler.isNotEmpty && photoMode)
              IconButton(onPressed: () async{
                await Pdfservisi().pdf_kaydet(secilenresimler, await getApplicationCacheDirectory());
                secilenresimler = [];
                secimModu =false;
                photoMode = false;
                setState(() async{
                  await photokayit();
                  await pdfKayit(await getApplicationCacheDirectory());
                  fileMode = false;
                  pdfMode = false;
                });
              }, icon: Icon(Icons.save)),
            if (secimModu && secilenresimler.isNotEmpty && pdfMode)
              IconButton(
                onPressed: () async {
                  if (pdfMode) {
                    final fullPath = await getApplicationCacheDirectory();
                    final pdfDir = Directory("${fullPath.path}/pdf");
                    if (!pdfDir.existsSync()) {
                      pdfDir.createSync(recursive: true);
                    }

                    final List<FileSystemEntity> entities = pdfDir.listSync();
                    List<File> yollar = entities
                        .map((dosya) => File(dosya.path))
                        .toList();

                    // Show a popup dialog containing the folder list
                    showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text("Select or Create Folder"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: yollar.isEmpty ? 1 : yollar.length,
                              itemBuilder: (context, index) {
                                // Handle empty list case gracefully inside the dialog
                                if (yollar.isEmpty) {
                                  return ListTile(
                                    title: const Text(
                                      "No folders found. Create one below.",
                                    ),
                                  );
                                }

                                final dosya = yollar[index];
                                return ListTile(
                                  leading: const Icon(Icons.folder),
                                  title: Text(dosya.path.split('/').last),
                                  onTap: () async {
                                    for(int i = 0 ; i > yollar.length;i++){
                                      final file = File(dosya.path);
                                      if(await file.exists()){
                                        await file.delete();
                                      }
                                    }
                                    await Pdfservisi().pdfTasi(
                                      secilenresimler,
                                      Directory(dosya.path),
                                    );
                                    await pdfKayit(await getApplicationCacheDirectory());

                                    setState(() {
                                      secilenresimler = [];
                                      secimModu = false;
                                      pdfMode = false;
                                    });
                                    Navigator.pop(
                                      // ignore: use_build_context_synchronously
                                      dialogContext,
                                    ); // Close dialog
                                  },
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                String? yeniDosyaAdi = await Pdfservisi()
                                    .pdfAdi();
                                if (yeniDosyaAdi != null &&
                                    yeniDosyaAdi.isNotEmpty) {
                                  final newDir = Directory(
                                    "${pdfDir.path}/$yeniDosyaAdi",
                                  );
                                  newDir.createSync(recursive: true);
                                  Pdfservisi().pdfTasi(secilenresimler,newDir);
                                  await pdfKayit(newDir);

                                  setState(() {
                                    secilenresimler = [];
                                    secimModu = false;
                                    pdfMode = false;
                                    photoMode = false;
                                    fileMode = false;
                                  });
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(dialogContext); // Close dialog
                                }
                              },
                              child: const Text(
                                "Create Folder",
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (photoMode) {
                    //maybe im gonna add this later(photo foldering)-------------------------------------------------------------------
                  }
                },
                icon: const Icon(Icons.folder),
              ),
          ],

          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.picture_as_pdf), text: "PDF"),
              Tab(icon: Icon(Icons.image), text: "Pictures"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              itemCount: _pdfkayit.length,
              itemBuilder: (context, index) {
                final dosya = _pdfkayit[index];
                final bool secilMI = secilenresimler.contains(dosya.path);
                String dosyaAdi = _pdfkayit[index].path.split('/').last;
                IconData resim = Icons.folder;
                if (dosyaAdi.endsWith("pdf")) {
                  resim = Icons.picture_as_pdf;
                }
                return InkWell(
                  onLongPress: () {
                    setState(() {
                      if (!photoMode) {
                        secimModu = true;
                        secilenresimler.add(dosya.path);
                        pdfMode = true;
                        if(!dosya.path.endsWith(".pdf")){
                            fileMode = true;
                          }
                      }
                    });
                  },
                  onTap: () async {
                    if (secimModu && pdfMode) {
                      setState(() {
                        if (secilenresimler.contains(dosya.path)) {
                          secilenresimler.remove(dosya.path);
                          if (secilenresimler.isEmpty) {
                            secimModu = false;
                            pdfMode = false;
                            fileMode = false;
                          }
                        } else {
                          secilenresimler.add(dosya.path);
                          if(!dosya.path.endsWith(".pdf")){
                            fileMode = true;
                          }
                        }
                      });
                    } else {
                      if(dosya.path.endsWith("pdf")){
                      await OpenFilex.open(dosya.path);}
                      else{
                        await pdfKayit(Directory(dosya.path));
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      ListTile(leading: Icon(resim), title: Text(dosyaAdi)),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (secilMI)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (secimModu && pdfMode)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              secilMI
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: secilMI ? Colors.green : Colors.grey,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            //photos section
            GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: _photokayit.length,
              itemBuilder: (context, index) {
                final dosya = _photokayit[index];
                final bool secilMI = secilenresimler.contains(dosya.path);
                return InkWell(
                  onLongPress: () {
                    setState(() {
                      if (!pdfMode) {
                        secimModu = true;
                        secilenresimler.add(dosya.path);
                        photoMode = true;
                      }
                    });
                  },
                  onTapUp: (details) {
                    if (secimModu && photoMode) {
                      setState(() {
                        if (secilMI) {
                          secilenresimler.remove(dosya.path);
                          if (secilenresimler.isEmpty) {
                            secimModu = false;
                            photoMode = false;
                          }
                        } else {
                          secilenresimler.add(dosya.path);
                        }
                      });
                    } else {
                      OpenFilex.open(dosya.path);
                    }
                  },
                  // ignore: sort_child_properties_last
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              dosya,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (secilMI)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (secimModu && photoMode)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              secilMI
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: secilMI ? Colors.green : Colors.grey,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.camera,
          activeIcon: Icons.camera,
          backgroundColor: Colors.transparent,
          spacing: 3,
          children: [
            SpeedDialChild(
              child: Icon(Icons.camera),
              label: "Full Mode",
              onTap: belgeTara,
            ),
            SpeedDialChild(
              child: Icon(Icons.credit_card),
              label: "Card Mode",
              onTap: karTara,
            ),
          ],
        ),
      ),
    ));
  }
}


///data/user/0/com.example.proje_2/cache
///data/user/0/com.example.proje_2/cache/ugjbm.pdf
///