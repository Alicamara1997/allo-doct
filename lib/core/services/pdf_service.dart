import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import '../models/prescription_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class PrescriptionPDFService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> generateAndUploadPDF(PrescriptionModel prescription, Uint8List signatureBytes) async {
    final pdf = pw.Document();

    // Barcode generation for PDF
    final bc = Barcode.code128();
    final svgBarcode = bc.toSvg(prescription.secureCode, width: 200, height: 80);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Dr. ${prescription.practitionerName}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.Text(prescription.practitionerSpecialty, style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                    pw.Text(DateFormat('dd/MM/yyyy').format(prescription.date)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // Patient
                pw.Text('Ordonnance pour :', style: const pw.TextStyle(fontSize: 12)),
                pw.Text(prescription.patientName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 40),

                // Medications
                ...prescription.medications.map((med) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ${med.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${med.dosage} - ${med.duration}', style: const pw.TextStyle(fontSize: 14)),
                      if (med.instructions.isNotEmpty)
                        pw.Text(med.instructions, style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                )),

                pw.Spacer(),

                // Bottom: Barcode and Signature
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.SvgImage(svg: svgBarcode, width: 150),
                        pw.SizedBox(height: 5),
                        pw.Text(prescription.secureCode, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Signature du Praticien', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          width: 120,
                          height: 60,
                          child: pw.Image(pw.MemoryImage(signatureBytes)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final bytes = await pdf.save();
      final ref = _storage.ref().child('prescriptions/${prescription.secureCode}.pdf');
      await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur PDF Upload: $e');
      return null;
    }
  }

  Future<String?> uploadSignature(Uint8List bytes, String practitionerId) async {
    try {
      final ref = _storage.ref().child('signatures/$practitionerId.png');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      return await ref.getDownloadURL();
    } catch (e) {
       print('Erreur Signature Upload: $e');
      return null;
    }
  }
}
