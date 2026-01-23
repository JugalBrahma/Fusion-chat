# 🚀 Quick Deployment Guide

## Backend (2 commands)
```bash
cd server
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Frontend (2 commands)
```bash
flutter build web
firebase deploy --only hosting
```

## Environment Variables (.env)
```env
FIREBASE_PROJECT_ID=your_project_id
OPENAI_API_KEY=sk-your-key
GROQ_API_KEY=gsk-your-key
```

## That's it! 🎉

Your RAG app is now deployed at:
- Backend: http://localhost:8000
- Frontend: https://your-project.firebaseapp.com
