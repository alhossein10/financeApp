import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/incoming.dart';
import '../models/transfer.dart';
import '../models/expense.dart';
import '../features/exchanges/domain/entities/exchange.dart';
import '../core/config/api_config.dart';
import '../core/services/token_manager.dart';
import '../injection_container.dart' as di;
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PdfExportHelper {
  /// Helper to load Arabic font (Amiri)
  static Future<({pw.Font regular, pw.Font bold})> _loadArabicFonts() async {
    final amiriRegular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final amiriBold = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(amiriRegular);
    final boldFont = pw.Font.ttf(amiriBold);
    
    return (regular: regularFont, bold: boldFont);
  }
  
  /// Get translations - defaults to English locale for PDF exports
  static String _getTranslation(String key, {String locale = 'en'}) {
    final localizations = AppLocalizations(Locale(locale));
    return localizations.translate(key);
  }
  static Future<void> exportCashTransactions({
    required List<TransferRecord> transfers,
    required List<IncomingRecord> incoming,
    required String title,
  }) async {
    final fonts = await _loadArabicFonts();
    final arabicFont = fonts.regular;
    final arabicFontBold = fonts.bold;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              _getTranslation('transfers'),
              style: pw.TextStyle(font: arabicFont, fontSize: 18),
            ),
          ),
          
          // Outgoing Section
          if (transfers.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              _getTranslation('outgoing'),
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
                        child: pw.Text(_getTranslation('recipient_name'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('usd'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('date'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
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
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                '${_getTranslation('sum')}: ${transfers.fold(0.0, (sum, t) => sum + (t.amountUsd - (t.convertedAmountUsd ?? 0.0))).toStringAsFixed(2)} ${_getTranslation('usd')}',
                style: pw.TextStyle(font: arabicFont, fontSize: 12),
              ),
            ),
          ],
          
          // Incoming Section
          if (incoming.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              _getTranslation('incoming'),
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
                        child: pw.Text(_getTranslation('description'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('usd'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('date'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
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
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                '${_getTranslation('sum')}: ${incoming.fold(0.0, (sum, i) => sum + i.amountUsd).toStringAsFixed(2)} ${_getTranslation('usd')}',
                style: pw.TextStyle(font: arabicFont, fontSize: 12),
              ),
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
    final fonts = await _loadArabicFonts();
    final arabicFont = fonts.regular;
    final arabicFontBold = fonts.bold;

    // Filter expenses with invoice images
    // An expense has an invoice if invoiceStatus is invoiceAvailable AND has either:
    // - An expense ID (can download from API), OR
    // - A local file path, OR  
    // - A cloud file ID
    final expensesWithImages = expenses.where((e) {
      if (e.invoiceStatus != InvoiceStatus.invoiceAvailable) return false;
      
      // If expense has an ID, we can try to download from API
      if (e.id != null) return true;
      
      // Otherwise, check for local file or cloud file ID
      return (e.invoiceFilePath != null && e.invoiceFilePath!.isNotEmpty) ||
             (e.invoiceCloudFileId != null && e.invoiceCloudFileId!.isNotEmpty);
    }).toList();

    if (expensesWithImages.isEmpty) {
      throw Exception('No invoice images found');
    }

    final doc = pw.Document();
    int validPages = 0;
    final List<String> errors = [];

    // Get auth token for API requests (if needed)
    final tokenManager = di.sl<TokenManager>();
    final token = await tokenManager.getToken();
    
    // Create Dio instance for downloading images from API
    final dio = Dio();

    for (final expense in expensesWithImages) {
      try {
        pw.MemoryImage? image;
        Uint8List? imageBytes;

        // First, try to load from local file path if available
        if (expense.invoiceFilePath != null && expense.invoiceFilePath!.isNotEmpty) {
          try {
            final localFile = File(expense.invoiceFilePath!);
            if (await localFile.exists()) {
              imageBytes = await localFile.readAsBytes();
              image = pw.MemoryImage(imageBytes);
              print('[PdfExportHelper] ✅ Loaded invoice from local file: ${expense.invoiceFilePath}');
            } else {
              print('[PdfExportHelper] ⚠️ Local file does not exist: ${expense.invoiceFilePath}');
            }
          } catch (e) {
            print('[PdfExportHelper] ❌ Failed to read local file: $e');
          }
        }

        // If local file didn't work and we have an expense ID, try API endpoint
        if (image == null && expense.id != null) {
          if (token == null) {
            errors.add('Expense ${expense.id}: Authentication required to download invoice');
            continue;
          }

          try {
            // Use apiUrl which includes /api/v1 - matches how expense_page.dart loads images
            final imageUrl = '${ApiConfig.apiUrl}/expenses/${expense.id}/invoice';
            print('[PdfExportHelper] 📥 Downloading invoice from API: $imageUrl');
            
            final response = await dio.get(
              imageUrl,
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'image/jpeg,image/png,image/*,application/octet-stream,*/*',
                },
                responseType: ResponseType.bytes,
                followRedirects: true,
                maxRedirects: 5,
                validateStatus: (status) => true, // Accept all status codes so we can see error responses
              ),
            );

            final statusCode = response.statusCode ?? 0;
            final contentType = response.headers.value('content-type') ?? 'unknown';
            final dataLength = response.data != null ? (response.data as List).length : 0;
            
            print('[PdfExportHelper] 📥 Response for expense ${expense.id}:');
            print('  Status: $statusCode');
            print('  Content-Type: $contentType');
            print('  Data length: $dataLength bytes');
            
            if (statusCode == 200 && response.data != null) {
              try {
                final data = response.data;
                Uint8List bytes;
                
                if (data is List<int>) {
                  bytes = Uint8List.fromList(data);
                } else if (data is Uint8List) {
                  bytes = data;
                } else {
                  throw Exception('Unexpected response data type: ${data.runtimeType}');
                }
                
                if (bytes.isNotEmpty) {
                  imageBytes = bytes;
                  image = pw.MemoryImage(bytes);
                  print('[PdfExportHelper] ✅ Successfully downloaded invoice from API for expense ${expense.id} (${bytes.length} bytes)');
                } else {
                  throw Exception('Image data is empty');
                }
              } catch (e) {
                errors.add('Expense ${expense.id}: Failed to process image data: $e');
                print('[PdfExportHelper] ❌ Failed to process image data for expense ${expense.id}: $e');
                continue;
              }
            } else {
              final statusMessage = response.statusMessage ?? 'Unknown';
              String errorDetails = 'Status $statusCode ($statusMessage)';
              
              // Try to extract error message from response
              if (response.data != null) {
                try {
                  if (response.data is List<int>) {
                    final errorStr = String.fromCharCodes(response.data as List<int>);
                    if (errorStr.isNotEmpty) {
                      errorDetails += ' - $errorStr';
                      // Limit error message length
                      if (errorDetails.length > 500) {
                        errorDetails = errorDetails.substring(0, 500) + '...';
                      }
                    }
                  }
                } catch (e) {
                  print('[PdfExportHelper] Could not parse error response: $e');
                }
              }
              
              errors.add('Expense ${expense.id}: $errorDetails');
              print('[PdfExportHelper] ❌ API error for expense ${expense.id}: $errorDetails');
              print('[PdfExportHelper] Full response headers: ${response.headers.map}');
              continue;
            }
          } catch (e, stackTrace) {
            errors.add('Expense ${expense.id}: ${e.toString()}');
            print('[PdfExportHelper] ❌ Failed to download invoice from API for expense ${expense.id}: $e');
            print('[PdfExportHelper] Stack trace: $stackTrace');
            continue;
          }
        }

        // If we still don't have an image, skip this expense
        if (image == null || imageBytes == null) {
          errors.add('Expense ${expense.id ?? 'unknown'}: Could not load invoice image');
          continue;
        }

        // Add page with the image (image is guaranteed to be non-null here due to check above)
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
                  child: pw.Image(image!, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),
        );
        validPages++;
      } catch (e) {
        errors.add('Expense ${expense.id ?? 'unknown'}: ${e.toString()}');
        print('[PdfExportHelper] ❌ Unexpected error processing expense ${expense.id}: $e');
        continue;
      }
    }

    if (validPages == 0) {
      final errorMsg = errors.isNotEmpty 
          ? 'No valid invoice images found. Errors:\n${errors.join('\n')}'
          : 'No valid invoice images found';
      throw Exception(errorMsg);
    }

    // Log any errors but continue if we have at least one valid page
    if (errors.isNotEmpty) {
      print('[PdfExportHelper] ⚠️ Some invoices could not be exported:\n${errors.join('\n')}');
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'invoice_images.pdf'));
    await file.writeAsBytes(await doc.save());
    print('[PdfExportHelper] ✅ Successfully exported $validPages invoice(s) to PDF');
    await OpenFilex.open(file.path);
  }

  /// Export exchanges to PDF
  static Future<void> exportExchanges({
    required List<Exchange> exchanges,
    String? userName,
  }) async {
    final fonts = await _loadArabicFonts();
    final arabicFont = fonts.regular;
    final arabicFontBold = fonts.bold;

    final doc = pw.Document();

    final sypSum = exchanges.fold(0.0, (sum, e) => sum + (e.amountSyp ?? 0.0));
    final usdSum = exchanges.fold(0.0, (sum, e) => sum + e.amountUsd);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              userName != null 
                ? '${_getTranslation('exchange_history')} - $userName' 
                : _getTranslation('exchange_history'),
              style: pw.TextStyle(font: arabicFont, fontSize: 18),
            ),
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
                      child: pw.Text(_getTranslation('usd'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(_getTranslation('syp'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(_getTranslation('rate'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(_getTranslation('date'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(_getTranslation('recipient'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                    ),
                  ],
                ),
                // Data rows
                ...exchanges.map((e) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(e.amountUsd.toStringAsFixed(2), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text((e.amountSyp ?? 0.0).toStringAsFixed(0), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(e.exchangeRate.toStringAsFixed(0), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${e.exchangeDate.day}/${e.exchangeDate.month}/${e.exchangeDate.year}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(e.recipientName ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(_getTranslation('summary'), style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Text('${_getTranslation('total')} ${_getTranslation('usd')}: ${usdSum.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                pw.Text('${_getTranslation('total')} ${_getTranslation('syp')}: ${sypSum.toStringAsFixed(0)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = userName != null ? 'exchanges_$userName.pdf' : 'exchanges.pdf';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(await doc.save());
    await OpenFilex.open(file.path);
  }

  /// Export combined user data (exchanges + expenses) to PDF
  static Future<void> exportUserData({
    required List<Exchange> exchanges,
    required List<ExpenseRecord> expenses,
    required String userName,
  }) async {
    final fonts = await _loadArabicFonts();
    final arabicFont = fonts.regular;
    final arabicFontBold = fonts.bold;

    final doc = pw.Document();

    // Calculate sums
    final exchangeSypSum = exchanges.fold(0.0, (sum, e) => sum + (e.amountSyp ?? 0.0));
    final exchangeUsdSum = exchanges.fold(0.0, (sum, e) => sum + e.amountUsd);
    final expenseUsdSum = expenses.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0));
    final expenseSypSum = expenses.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0));
    final expenseTrySum = expenses.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              '${_getTranslation('export_user_data')} - $userName',
              style: pw.TextStyle(font: arabicFontBold, fontSize: 20),
            ),
          ),
          pw.SizedBox(height: 20),

          // Exchanges Section
          pw.Text(_getTranslation('exchange_history'), style: pw.TextStyle(font: arabicFontBold, fontSize: 16)),
          pw.SizedBox(height: 10),
          if (exchanges.isNotEmpty) ...[
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('usd'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('syp'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('rate'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('date'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                    ],
                  ),
                  ...exchanges.map((e) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.amountUsd.toStringAsFixed(2), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text((e.amountSyp ?? 0.0).toStringAsFixed(0), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.exchangeRate.toStringAsFixed(0), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${e.exchangeDate.day}/${e.exchangeDate.month}/${e.exchangeDate.year}',
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
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${_getTranslation('total')} ${_getTranslation('usd')}: ${exchangeUsdSum.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                  pw.Text('${_getTranslation('total')} ${_getTranslation('syp')}: ${exchangeSypSum.toStringAsFixed(0)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                ],
              ),
            ),
          ] else ...[
            pw.Text(_getTranslation('no_exchanges'), style: pw.TextStyle(font: arabicFont, fontSize: 12)),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Expenses Section
          pw.Text(_getTranslation('expenses'), style: pw.TextStyle(font: arabicFontBold, fontSize: 16)),
          pw.SizedBox(height: 10),
          if (expenses.isNotEmpty) ...[
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('description'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('usd'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('syp'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('try'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getTranslation('date'), style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                      ),
                    ],
                  ),
                  ...expenses.map((e) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.description, style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceUsd?.toStringAsFixed(2) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceSyp?.toStringAsFixed(0) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceTry?.toStringAsFixed(2) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${e.expenseDate.day}/${e.expenseDate.month}/${e.expenseDate.year}',
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
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${_getTranslation('total')} ${_getTranslation('usd')}: ${expenseUsdSum.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                  pw.Text('${_getTranslation('total')} ${_getTranslation('syp')}: ${expenseSypSum.toStringAsFixed(0)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                  pw.Text('${_getTranslation('total')} ${_getTranslation('try')}: ${expenseTrySum.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                ],
              ),
            ),
          ] else ...[
            pw.Text(_getTranslation('no_expenses_yet'), style: pw.TextStyle(font: arabicFont, fontSize: 12)),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'user_report_$userName.pdf'));
    await file.writeAsBytes(await doc.save());
    await OpenFilex.open(file.path);
  }
}
