# 🚀 From Scratch Setup Guide

## 📱 Flutter Frontend Setup

### 1. Install Flutter
```bash
# Windows
choco install flutter

# macOS
brew install flutter

# Linux
snap install flutter
```

### 2. Create New Flutter Project
```bash
flutter create rag_app
cd rag_app
```

### 3. Add Dependencies
```bash
# Add to pubspec.yaml
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add http
flutter pub add provider
```

### 4. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Configure Firebase in Flutter
flutterfire configure
```

### 5. Run Flutter App
```bash
# Development
flutter run

# Web
flutter run -d chrome

# Build
flutter build web
flutter build apk
flutter build ios
```

---

## 🐍 FastAPI Backend Setup

### 1. Install Python & Create Project
```bash
# Create project directory
mkdir rag_backend
cd rag_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Create requirements.txt
cat > requirements.txt << EOF
fastapi==0.104.1
uvicorn==0.24.0
firebase-admin==6.2.0
langchain==0.1.0
langchain-openai==0.1.0
langchain-groq==0.1.0
chromadb==0.4.22
python-multipart==0.0.6
python-jose==3.3.0
passlib==1.7.4
bcrypt==4.1.2
EOF

# Install dependencies
pip install -r requirements.txt
```

### 2. Create Basic FastAPI App
```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="RAG API")

# Add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "RAG API is running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 3. Run Backend
```bash
# Development
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

---

## 🔗 Connect Flutter to FastAPI

### 1. Create API Service
```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';  // Your backend IP
  
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    return json.decode(response.body);
  }
  
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }
}
```

### 2. Use in Flutter Widget
```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  String response = '';

  Future<void> callApi() async {
    setState(() => isLoading = true);
    
    try {
      final result = await ApiService.post('/chat', {
        'message': 'Hello from Flutter!',
      });
      
      setState(() {
        response = result['response'] ?? 'No response';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        response = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RAG App')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Type your message',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: callApi,
                  child: Text('Send'),
                ),
            SizedBox(height: 16),
            Text(response),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 Quick Start Commands

### Flutter (3 commands)
```bash
# 1. Create project
flutter create rag_app && cd rag_app

# 2. Add dependencies
flutter pub add firebase_core firebase_auth http

# 3. Run app
flutter run
```

### FastAPI (3 commands)
```bash
# 1. Create project
mkdir rag_backend && cd rag_backend

# 2. Setup and install
python -m venv venv && source venv/bin/activate
pip install fastapi uvicorn

# 3. Create and run
echo "from fastapi import FastAPI; app = FastAPI(); uvicorn.run(app)" > main.py
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 🎯 Test Connection

### 1. Start Both Apps
```bash
# Terminal 1 - Backend
cd rag_backend
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000

# Terminal 2 - Frontend
cd rag_app
flutter run
```

### 2. Test API Call
- Open Flutter app
- Click "Send" button
- Check browser network tab for API calls
- Should see response from FastAPI backend

---

## ✅ That's It! 🎉

**Your Flutter + FastAPI RAG application is now running from scratch!**

- Frontend: http://localhost:3000 (or device/emulator)
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs

Next steps: Add authentication, database, and RAG functionality!
