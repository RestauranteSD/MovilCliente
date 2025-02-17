import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String menuInfo = "";
  bool scanCompleted = false; // Controla la visibilidad del botón

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // Pausar la cámara después de escanear

      String scannedUrl = scanData.code ?? "";
      if (scannedUrl.isNotEmpty) {
        await fetchMenuData(scannedUrl);
      }
    });
  }

  Future<void> fetchMenuData(String url) async {
    try {
      Uri uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          menuInfo = "Menú: ${data['nombre']}\nPlatos:\n" +
              (data['platos'] as List)
                  .map((plato) => "- ${plato['nombre']} (\$${plato['precio']})\n")
                  .join("");
          scanCompleted = true; // Mostrar el botón después del escaneo
        });
      } else {
        setState(() {
          menuInfo = "Error al obtener los datos del menú";
          scanCompleted = true; // Aún mostrar el botón si hubo error
        });
      }
    } catch (e) {
      setState(() {
        menuInfo = "Error: $e";
        scanCompleted = true;
      });
    }
  }

  void restartScan() {
    setState(() {
      menuInfo = ""; // Borrar información del menú
      scanCompleted = false; // Ocultar el botón
    });
    controller?.resumeCamera(); // Reactivar la cámara para escanear otro QR
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escáner QR")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: QRView(
              key: qrKey,
              onQRViewCreated: onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(menuInfo, textAlign: TextAlign.center),
                SizedBox(height: 20),
                if (scanCompleted) // Mostrar botón solo después del escaneo
                  ElevatedButton(
                    onPressed: restartScan,
                    child: Text("Volver a escanear"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
