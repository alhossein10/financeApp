import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/incoming.dart';
import '../models/transfer.dart';
import '../models/expense.dart';

class PdfExportHelper {
  static Future<void> exportCashTransactions({
    required List<TransferRecord> transfers,
    required List<IncomingRecord> incoming,
    required String title,
  }) async {
    final regularFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final arabicFont = pw.Font.ttf(regularFontData);
    final arabicFontBold = pw.Font.ttf(boldFontData);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Transfers',
              style: pw.TextStyle(font: arabicFont, fontSize: 18),
            ),
          ),
          
          // Outgoing Section
          if (transfers.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Outgoing',
              style: pw.TextStyle(font: arabicFont, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Reciever', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('USD', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...transfers.map((t) {
                    final actualUsd = t.amountUsd - (t.convertedAmountUsd ?? 0.0);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(t.recipientName, style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(actualUsd.toStringAsFixed(2), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'SUM: ${transfers.fold(0.0, (sum, t) => sum + (t.amountUsd - (t.convertedAmountUsd ?? 0.0))).toStringAsFixed(2)} USD',
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
          ],
          
          // Incoming Section
          if (incoming.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Incoming',
              style: pw.TextStyle(font: arabicFont, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('description', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('USD', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...incoming.map((i) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(i.description, style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(i.amountUsd.toStringAsFixed(2), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${i.transactionDate.day}/${i.transactionDate.month}/${i.transactionDate.year}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'SUM: ${incoming.fold(0.0, (sum, i) => sum + i.amountUsd).toStringAsFixed(2)} USD',
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'cash_transactions.pdf'));
    await file.writeAsBytes(await doc.save());
    await OpenFilex.open(file.path);
  }

  static Future<void> exportInvoiceImages(List<ExpenseRecord> expenses) async {
    final regularFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final arabicFont = pw.Font.ttf(regularFontData);
    final arabicFontBold = pw.Font.ttf(boldFontData);

    // Filter expenses with invoice images
    final expensesWithImages = expenses.where((e) => 
      e.invoiceFilePath != null && 
      e.invoiceFilePath!.isNotEmpty &&
      File(e.invoiceFilePath!).existsSync()
    ).toList();

    if (expensesWithImages.isEmpty) {
      throw Exception('No invoice images found');
    }

    final doc = pw.Document();
    int validPages = 0;

    for (final expense in expensesWithImages) {
      try {
        final imageFile = File(expense.invoiceFilePath!);
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  expense.description,
                  style: pw.TextStyle(font: arabicFont, fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),
        );
        validPages++;
      } catch (e) {
        // Skip images that can't be loaded
        continue;
      }
    }

    if (validPages == 0) {
      throw Exception('No valid invoice images found');
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'invoice_images.pdf'));
    await file.writeAsBytes(await doc.save());
    await OpenFilex.open(file.path);
  }
}
