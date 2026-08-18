// ignore_for_file: file_names

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pro_scanner/main.dart';

class Pdfservisi {
  // ignore: non_constant_identifier_names
  Future<String> pdf_kaydet(List<String> resimYollari , Directory path) async {
    final pdf = pw.Document();
    for (var yol in resimYollari) {
      final resimDosyasi = File(yol);
      final resimBytes = await resimDosyasi.readAsBytes();
      final pdfResim = pw.MemoryImage(resimBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Image(pdfResim, fit: pw.BoxFit.contain),
              ),
            );
          },
        ),
      );
    }
    final klasor = path;
    final isi = await Pdfservisi().gettext();
    final String dosyaAdi;
    if (isi != null && isi.isNotEmpty) {
      dosyaAdi = "$isi.pdf";
    } else {
      dosyaAdi = "tarama_${DateTime.now().millisecondsSinceEpoch}.pdf";
    }
    final dosyaYolu = "${klasor.path}/$dosyaAdi";
    final dosya = File(dosyaYolu);

    await dosya.writeAsBytes(await pdf.save());
    return dosyaYolu;
  }

  Future<String?> gettext() async {
    String? isim = await pdfAdi();
    return isim;
  }

  Future<String?> pdfAdi() async {
    final TextEditingController isim = TextEditingController();
    if (navigatorkey.currentContext == null) {
      return null;
    }
    return showDialog<String>(
      context: navigatorkey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter The File Name"),
          content: TextField(
            controller: isim,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Ex: IDs , Ticket , ...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                String metin = isim.text.trim();
                if (metin.isNotEmpty) {
                  Navigator.pop(context, metin);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> pdfTasi(List<String> resimYollari  , Directory newDir) async{
    for(int i = 0 ; i < resimYollari.length ; i++){
      File sourceFile = File(resimYollari[i]);
      String fileName = sourceFile.path.split('/').last;
      String targetPath = "${newDir.path}/$fileName";
      await sourceFile.rename(targetPath);
    }
  }
}

class Jpgservisi {
  // ignore: non_constant_identifier_names
  Future<List<String>> jpg_kaydet(List<String> resimYollari) async {
    final List<String> yollar = [];
    final klasor = await getApplicationDocumentsDirectory();
    for (var i = 0; i < resimYollari.length; i++) {
      final dosya = File(resimYollari[i]);
      final yeniDosyaAdi =
          "tarama_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";
      final yeniYol = "${klasor.path}/$yeniDosyaAdi";
      await dosya.copy(yeniYol);
      yollar.add(yeniYol);
    }
    return yollar;
  }
}

// ignore: camel_case_types
class kartServisi {
  // ignore: non_constant_identifier_names
  Future<File> kart_kaydet(List<String> resimYollari) async {
    final pw.Document pdf = pw.Document();
    List<pw.MemoryImage> pdfresimleri = [];
    for (String yol in resimYollari) {
      final File resimDosya = File(yol);
      final Uint8List byteler = await resimDosya.readAsBytes();
      pdfresimleri.add(pw.MemoryImage(byteler));
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: pdfresimleri.map((imgProvider) {
                return pw.Container(
                  width: 240,
                  height: 150,
                  child: pw.Image(imgProvider, fit: pw.BoxFit.contain),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );
    final klasor = await getApplicationCacheDirectory();
    final isi = await Pdfservisi().gettext();
    final String dosyaAdi;
    if (isi != null && isi.isNotEmpty) {
      // ignore: unnecessary_brace_in_string_interps
      dosyaAdi = "${isi}.pdf";
    } else {
      dosyaAdi = "tarama_${DateTime.now().millisecondsSinceEpoch}.pdf";
    }
    final dosyaYolu = "${klasor.path}/$dosyaAdi";
    final dosya = File(dosyaYolu);
    await dosya.writeAsBytes(await pdf.save());
    return dosya;
  }
}
