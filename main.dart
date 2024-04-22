import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Raleway', // Replace 'YourFontFamily' with your desired font family
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _urlController = TextEditingController();
  String _predictionRF = '';
  String _predictionSVM = '';
  String _resultStr = '';
  List<String> _googleResults = [];
  bool _isLoading = false;

  Future<void> _predict() async {
    setState(() {
      _isLoading = true;
    });
    final url = 'http://localhost:5000/predict';
    final data = {'url': _urlController.text};
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);
    setState(() {
      _predictionRF = responseData['prediction_rf'];
      _predictionSVM = responseData['prediction_svm'];
      _resultStr = responseData['result_str'];
      _googleResults = List<String>.from(responseData['google_results'] ?? []);
      _isLoading = false;
    });
    _showResultDialog();
  }

  void _showResultDialog() {
    Color dialogColor = _resultStr == 'URL IS MALICIOUS!' ? Colors.red : Colors.green;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(
            'Prediction Result',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Random Forest Prediction: $_predictionRF',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'SVM Prediction: $_predictionSVM',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20), // Adding separation between RF/SVM predictions and the result
              Text(
                'Result -> $_resultStr',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('URL Predictor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(labelText: 'Enter URL'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                child: Text('Predict'),
              ),
              // Using CircularProgressIndicator for the loading animation
              _isLoading ? CircularProgressIndicator() : SizedBox.shrink(),
              SizedBox(height: 20),
              _googleResults.isEmpty ? Container() : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Similar safe URLs:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: _googleResults.map((result) => Card(
                      child: ListTile(
                        title: Text(
                          result,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(result),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
