import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:open_file/open_file.dart';

class QRCodeGeneratorPage extends StatefulWidget {
  const QRCodeGeneratorPage({super.key});

  @override
  State<QRCodeGeneratorPage> createState() => _QRCodeGeneratorPageState();
}

class _QRCodeGeneratorPageState extends State<QRCodeGeneratorPage> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController newProductController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController exportDateController = TextEditingController();
  final TextEditingController sellerNameController = TextEditingController();

  String selectedCategory = 'Fruit';
  String? selectedProduct;
  List<String> productList = [];

  Future<void> _generateAndSavePDF() async {
    if (selectedProduct == null ||
        quantityController.text.isEmpty ||
        batchNumberController.text.isEmpty ||
        locationController.text.isEmpty ||
        exportDateController.text.isEmpty ||
        sellerNameController.text.isEmpty) {
      _showSnackBar('Please fill all fields.');
      return;
    }

    int qty = int.tryParse(quantityController.text) ?? 1;
    final pdf = pw.Document();

    for (int i = 1; i <= qty; i++) {
      final qrData =
          'Category: $selectedCategory\nProduct: $selectedProduct\nBatch: ${batchNumberController.text}\nLocation: ${locationController.text}\nExport Date: ${exportDateController.text}\nSeller: ${sellerNameController.text}\nNumber: $i';
      final qrImage = await _generateQRImage(qrData);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('Product: $selectedProduct',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Category: $selectedCategory'),
                pw.Text('Batch: ${batchNumberController.text}'),
                pw.Text('Location: ${locationController.text}'),
                pw.Text('Export Date: ${exportDateController.text}'),
                pw.Text('Seller: ${sellerNameController.text}'),
                pw.Text('Number: $i'),
                pw.SizedBox(height: 12),
                pw.Image(pw.MemoryImage(qrImage)),
              ],
            ),
          ),
        ),
      );
    }

    final directory = await getExternalStorageDirectory();
    final filePath = "${directory!.path}/qr_codes.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    _showSnackBar('PDF saved at: $filePath');
    OpenFile.open(filePath);
  }

  Future<Uint8List> _generateQRImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    final imageData = await qrPainter.toImageData(300);
    final imageBytes = imageData!.buffer.asUint8List();
    final qrImage = img.decodeImage(imageBytes)!;

    return Uint8List.fromList(img.encodePng(qrImage));
  }

  void _addProduct() {
    if (newProductController.text.isNotEmpty) {
      setState(() {
        productList.add(newProductController.text);
        selectedProduct = newProductController.text;
        newProductController.clear();
      });
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add New Product",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: newProductController,
          decoration: InputDecoration(
            hintText: "Enter product name",
            filled: true,
            fillColor: Colors.green.shade50,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: _addProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              _buildCustomAppBar(),
              const SizedBox(height: 20),
              _buildDropdownSection(),
              const SizedBox(height: 20),
              _buildInputSection(),
              const SizedBox(height: 30),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'Agri QR Code Generator',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStyledDropdown(
              label: 'Category',
              value: selectedCategory,
              items: ['Fruit', 'Vegetable', 'Leaf'],
              onChanged: (value) => setState(() => selectedCategory = value!),
            ),
            const SizedBox(height: 20),
            _buildStyledDropdown(
              label: 'Product',
              value: selectedProduct,
              items: productList,
              onChanged: (value) => setState(() => selectedProduct = value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.green),
                label: const Text('Add Product',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            _buildStyledTextField(
              controller: quantityController,
              label: 'Quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildStyledTextField(
              controller: batchNumberController,
              label: 'Batch Number',
            ),
            const SizedBox(height: 16),
            _buildStyledTextField(
              controller: locationController,
              label: 'Location',
            ),
            const SizedBox(height: 16),
            _buildStyledTextField(
              controller: exportDateController,
              label: 'Export Date (YYYY-MM-DD)',
            ),
            const SizedBox(height: 16),
            _buildStyledTextField(
              controller: sellerNameController,
              label: 'Seller Name',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateAndSavePDF,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
        label: const Text('Generate PDF',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String label,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}