# 🐍 Backend Deployment

## Local Development
```bash
cd server
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Production Server
```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://user:pass@localhost:5432/rag_db"
export FIREBASE_PROJECT_ID="your_project"
export OPENAI_API_KEY="sk-your-key"

# Start with Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## Docker Deployment
```bash
# Build image
docker build -t rag-backend .

# Run container
docker run -p 8000:8000 rag-backend

# Or with docker-compose
docker-compose up -d
```

## Cloud Deployment (AWS)
```bash
# 1. Create EC2 instance
# 2. SSH into server
ssh -i your-key.pem ubuntu@your-ip

# 3. Setup and deploy
git clone your-repo
cd your-repo
pip install -r requirements.txt
docker-compose up -d
```

## Environment Setup (.env)
```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/rag_db

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."

# API Keys
OPENAI_API_KEY=sk-...
GROQ_API_KEY=gsk_...
GOOGLE_API_KEY=AIza...

# Vector Store
CHROMA_PERSIST_DIRECTORY=./chroma_db
```

## Health Check
```bash
curl http://localhost:8000/health
curl http://localhost:8000/analytics/status
```

## That's it! 🚀
Your RAG backend is now running!
