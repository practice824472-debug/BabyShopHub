import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Models/order_model.dart';

/// Generates a PDF invoice for a completed order and lets the user share
/// or print it via the platform share sheet / print dialog.
class InvoiceService {
  InvoiceService._();

  static Future<Uint8List> _buildInvoice(OrderModel order) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'BabyShopHub',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:',
                          style:
                              pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.address.fullName),
                      pw.Text(order.address.phone),
                      pw.Text(order.address.addressLine),
                      pw.Text(
                          '${order.address.city} ${order.address.postalCode}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Order #: ${order.orderId.substring(0, 8).toUpperCase()}'),
                      pw.Text('Date: ${_formatDate(order.createdAt)}'),
                      pw.Text('Payment: ${order.paymentMethod}'),
                      pw.Text('Status: ${order.status.label}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Item', bold: true),
                      _cell('Qty', bold: true),
                      _cell('Price', bold: true),
                      _cell('Subtotal', bold: true),
                    ],
                  ),
                  ...order.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _cell(item.name),
                        _cell('${item.quantity}'),
                        _cell('\$${item.price.toStringAsFixed(2)}'),
                        _cell('\$${item.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Paid: \$${order.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with BabyShopHub!',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// Opens the platform print/share sheet with the rendered invoice PDF.
  static Future<void> shareInvoice(OrderModel order) async {
    final bytes = await _buildInvoice(order);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'invoice_${order.orderId.substring(0, 8)}.pdf',
    );
  }
}
