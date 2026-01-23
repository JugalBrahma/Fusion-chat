# 🚀 Complete Deployment Guide

## 📋 Prerequisites

### Backend (Python/FastAPI)
- Python 3.8+
- PostgreSQL or MongoDB (for vector database)
- Redis (for caching)
- Firebase Admin SDK
- Environment variables configured

### Frontend (Flutter)
- Flutter 3.0+
- Firebase configured
- Android/iOS development setup

---

## 🐍 Backend Deployment

### 1. Server Setup
```bash
# Navigate to server directory
cd server

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="your_database_url"
export FIREBASE_CREDENTIALS="path/to/firebase-credentials.json"
export OPENAI_API_KEY="your_openai_key"
export GROQ_API_KEY="your_groq_key"
```

### 2. Database Setup
```bash
# PostgreSQL (recommended for production)
createdb rag_db

# Or MongoDB
mongod --dbpath /data/db
```

### 3. Vector Store Setup
```bash
# ChromaDB (included)
# Or Pinecone/Weaviate for cloud
pip install chromadb
```

### 4. Start Backend Server
```bash
# Development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production with Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### 5. Backend Health Check
```bash
curl http://localhost:8000/health
curl http://localhost:8000/analytics/status
```

---

## 📱 Frontend Deployment

### 1. Flutter Web Deployment
```bash
# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 2. Android Deployment
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Deploy to Google Play Store
# Use Google Play Console
```

### 3. iOS Deployment
```bash
# Build iOS
flutter build ios --release

# Deploy to App Store
# Use Xcode -> App Store Connect
```

---

## 🔧 Environment Configuration

### Backend .env
```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/rag_db
REDIS_URL=redis://localhost:6379

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY_ID=your_key_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."

# API Keys
OPENAI_API_KEY=sk-...
GROQ_API_KEY=gsk_...
GOOGLE_API_KEY=AIza...

# Vector Store
VECTOR_STORE_TYPE=chroma
CHROMA_PERSIST_DIRECTORY=./chroma_db
```

### Frontend Configuration
```dart
// lib/firebase_options.dart
const FirebaseOptions firebaseOptions = {
  apiKey: "your_api_key",
  authDomain: "your_project.firebaseapp.com",
  projectId: "your_project_id",
  storageBucket: "your_project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef",
};
```

---

## 🐳 Docker Deployment

### 1. Backend Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Docker Compose
```yaml
version: '3.8'

services:
  backend:
    build: ./server
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/rag_db
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=rag_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### 3. Deploy with Docker
```bash
# Build and run
docker-compose up -d

# Scale backend
docker-compose up -d --scale backend=3
```

---

## ☁️ Cloud Deployment

### AWS EC2
```bash
# 1. Launch EC2 instance (Ubuntu 22.04)
# 2. Open ports: 8000, 5432, 6379
# 3. SSH into instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# 4. Setup application
git clone your-repo
cd your-repo
docker-compose up -d
```

### Google Cloud Platform
```bash
# 1. Create GCE instance
gcloud compute instances create rag-server --zone=us-central1-a

# 2. Setup firewall
gcloud compute firewall-rules create allow-rag --allow tcp:8000

# 3. Deploy
gcloud compute ssh rag-server --zone=us-central1-a
git clone your-repo
cd your-repo
docker-compose up -d
```

### Azure Container Instances
```bash
# 1. Create container group
az container create --resource-group rag-rg --name rag-app

# 2. Deploy container
az container up --resource-group rag-rg --name rag-app
```

---

## 🔒 Security & SSL

### 1. SSL Certificate
```bash
# Let's Encrypt (free)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com

# Or Cloudflare (free SSL)
# Add domain to Cloudflare dashboard
```

### 2. Environment Security
```bash
# Secure environment variables
export $(cat .env | xargs)
chmod 600 .env

# Firewall setup
sudo ufw allow 8000
sudo ufw allow 443
sudo ufw enable
```

---

## 📊 Monitoring & Logging

### 1. Application Monitoring
```bash
# PM2 for process management
npm install -g pm2
pm2 start "uvicorn app.main:app --host 0.0.0.0 --port 8000" --name rag-api

# Logs
pm2 logs rag-api
pm2 monit
```

### 2. Health Checks
```python
# Add to main.py
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }
```

---

## 🚀 CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy RAG App

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to server
        run: |
          ssh user@server "cd /app && git pull && docker-compose up -d"
```

---

## 📱 Mobile App Store Deployment

### Google Play Store
1. **Prepare Release**
   - Generate signed APK/AAB
   - Create store listing
   - Set content rating

2. **Upload**
   - Go to Google Play Console
   - Upload AAB file
   - Submit for review

### Apple App Store
1. **Prepare Release**
   - Generate IPA file
   - Create App Store Connect listing
   - Set app metadata

2. **Upload**
   - Use Xcode or Transporter
   - Upload to App Store Connect
   - Submit for review

---

## 🔧 Production Checklist

### Backend ✅
- [ ] Environment variables set
- [ ] Database configured
- [ ] Vector store working
- [ ] SSL certificate installed
- [ ] Firewall configured
- [ ] Monitoring enabled
- [ ] Backup strategy
- [ ] Load balancer setup (if needed)

### Frontend ✅
- [ ] Firebase configured
- [ ] API endpoints updated
- [ ] Build optimized
- [ ] Icons and splash screens
- [ ] Privacy policy added
- [ ] Terms of service added
- [ ] Testing completed

### Security ✅
- [ ] API keys secured
- [ ] HTTPS enabled
- [ ] Rate limiting configured
- [ ] Input validation
- [ ] Authentication working
- [ ] CORS configured

---

## 🆘 Troubleshooting

### Common Issues
1. **CORS Errors**
   ```python
   # Add to main.py
   from fastapi.middleware.cors import CORSMiddleware
   app.add_middleware(CORSMiddleware, allow_origins=["*"])
   ```

2. **Database Connection**
   ```bash
   # Check connection
   python -c "from app.db import engine; print(engine.url)"
   ```

3. **Firebase Authentication**
   ```dart
   # Check Firebase config
   flutter pub get
   flutter run --debug
   ```

### Log Locations
- Backend: `/var/log/rag-app/`
- Docker: `docker-compose logs`
- Flutter: `flutter logs`

---

## 📞 Support

### Deployment Commands Quick Reference
```bash
# Quick restart
docker-compose restart

# Check status
docker-compose ps

# View logs
docker-compose logs -f backend

# Scale services
docker-compose up -d --scale backend=3

# Update
git pull && docker-compose up -d --build
```

---

**🎉 Your RAG application is now ready for production deployment!**
