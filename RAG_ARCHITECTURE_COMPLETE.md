# Complete RAG Architecture Code

## 🏗️ System Overview
```
PDF Upload → Text Extraction → Chunking → Embedding → Vector Store → Retrieval → LLM → Answer
```

## 📁 File Structure
```
server/
├── backend/
│   ├── ingest/
│   │   ├── embed_and_store.py      # PDF processing & vector storage
│   └── rag/
│       ├── chain.py                # RAG chain logic
│       ├── retriever.py            # Document retrieval
│       └── prompt.py               # RAG prompt template
├── services/
│   ├── vector_store.py             # AstraDB vector store
│   └── database.py                # Firestore setup
├── routes/
│   ├── upload.py                   # PDF upload endpoint
│   └── chat.py                     # Chat endpoint
└── main.py                         # FastAPI app
```

## 🔧 Complete Code Files

### 1. Vector Store Setup (`services/vector_store.py`)
```python
import os
from langchain_openai import OpenAIEmbeddings
from langchain_astradb import AstraDBVectorStore

# Singleton embeddings instance
embeddings = OpenAIEmbeddings(
    model="text-embedding-3-small",
)

# Singleton vector store instance reused across the app
vector_store = AstraDBVectorStore(
    embedding=embeddings,
    api_endpoint=os.getenv("ASTRA_DB_API_ENDPOINT"),
    collection_name="pdf_chunks",
    token=os.getenv("ASTRA_DB_APPLICATION_TOKEN"),
    namespace=os.getenv("ASTRA_DB_NAMESPACE"),
)
```

### 2. Document Ingestion (`backend/ingest/embed_and_store.py`)
```python
import os
from typing import List
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from langchain_openai import OpenAIEmbeddings
from services.vector_store import vector_store

# Text splitter configuration
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
)

def process_and_store_pdf(
    pdf_text: str,
    user_id: str,
    folder_id: str,
    pdf_id: str,
    pdf_name: str
) -> int:
    """
    Process PDF text and store in vector store
    
    Args:
        pdf_text: Extracted text from PDF
        user_id: User ID from Firebase
        folder_id: Folder ID from Firestore
        pdf_id: PDF document ID
        pdf_name: PDF file name
    
    Returns:
        Number of chunks stored
    """
    # Create document
    doc = Document(
        page_content=pdf_text,
        metadata={
            "userId": user_id,
            "folderId": folder_id,
            "pdfId": pdf_id,
            "pdfName": pdf_name,
            "source": pdf_name
        }
    )
    
    # Split into chunks
    chunks = text_splitter.split_documents([doc])
    
    # Add metadata to each chunk
    for i, chunk in enumerate(chunks):
        chunk.metadata.update({
            "chunkIndex": i,
            "totalChunks": len(chunks)
        })
    
    # Store in vector store
    vector_store.add_documents(chunks)
    
    print(f"Stored {len(chunks)} chunks for {pdf_name}")
    return len(chunks)

def delete_pdf_vectors(user_id: str, folder_id: str, pdf_id: str) -> int:
    """
    Delete all vectors for a specific PDF
    
    Args:
        user_id: User ID
        folder_id: Folder ID  
        pdf_id: PDF ID
    
    Returns:
        Number of deleted documents
    """
    # Delete by metadata filter
    delete_count = vector_store.delete(
        filter={
            "userId": user_id,
            "folderId": folder_id,
            "pdfId": pdf_id
        }
    )
    
    print(f"Deleted {delete_count} vectors for PDF {pdf_id}")
    return delete_count
```

### 3. RAG Retriever (`backend/rag/retriever.py`)
```python
from services.vector_store import vector_store

def get_retriever(user_id: str, folder_id: str):
    """
    Get a retriever for a specific user's folder
    
    Args:
        user_id: User ID from Firebase
        folder_id: Folder ID from Firestore
    
    Returns:
        Configured retriever
    """
    return vector_store.as_retriever(
        search_kwargs={
            "k": 5,
            "filter": {
                "userId": user_id,
                "folderId": folder_id,
            }
        }
    )
```

### 4. RAG Prompt (`backend/rag/prompt.py`)
```python
from langchain_core.prompts import ChatPromptTemplate

prompt = ChatPromptTemplate.from_template(
"""
You are a helpful AI assistant. Answer the user's question based on the provided context when relevant, but also engage in natural conversation.

Context from documents:
{context}

User question:
{question}

Instructions:
- If the context contains relevant information for the question, use it to provide a detailed answer
- If the question is a general greeting, small talk, or not related to the documents, respond naturally and conversationally
- Be helpful, friendly, and informative
- If you don't know something specific from the documents but can still help generally, do so

Answer:
"""
)
```

### 5. RAG Chain (`backend/rag/chain.py`)
```python
from langchain_openai import ChatOpenAI
from langchain_groq import ChatGroq
from langchain_community.llms import HuggingFaceHub
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from .prompt import prompt
from .retriever import get_retriever
import os
import google.generativeai as genai

def _get_llm(provider: str):
    """
    Select the underlying chat model based on provider.

    Supported:
    - 'openai' (default)
    - 'groq'
    - 'gemini'
    - 'huggingface'
    """
    provider = (provider or "openai").lower()

    if provider == "groq":
        return ChatGroq(
            model="llama-3.1-8b-instant",
            temperature=0.0,
        )
    elif provider == "gemini":
        genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
        return genai.GenerativeModel("gemini-2.5-flash")
    elif provider == "huggingface":
        return HuggingFaceHub(
            repo_id="microsoft/DialoGPT-medium",
            model_kwargs={"temperature": 0.0},
        )

    # Default: OpenAI GPT-4o mini
    return ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0.0,
    )

def format_docs(docs):
    return "\n\n".join(d.page_content for d in docs)

def build_rag_chain(user_id: str, folder_id: str, provider: str = "openai"):
    """
    Build a complete RAG chain for a user's folder
    
    Args:
        user_id: User ID from Firebase
        folder_id: Folder ID from Firestore
        provider: LLM provider to use
    
    Returns:
        Callable RAG chain
    """
    retriever = get_retriever(user_id, folder_id)
    llm = _get_llm(provider)

    def rag_chain(question: str):
        try:
            # Retrieve documents
            docs = retriever.invoke(question)
            print(f"Retrieved {len(docs)} chunks")
            
            if docs:
                print("Sample metadata:", docs[0].metadata)
            
            # Format context
            formatted_docs = format_docs(docs) if docs else "No specific document context available for this question."
            
            # Create prompt
            prompt_formatted = prompt.invoke({"context": formatted_docs, "question": question})
            
            # Generate response
            if provider.lower() == "gemini":
                response = llm.generate_content(prompt_formatted.to_string())
                return response.text
            else:
                response = llm.invoke(prompt_formatted)
                return response.content
                
        except Exception as e:
            print(f"Error in RAG chain: {e}")
            return f"Error processing request: {str(e)}"

    return rag_chain
```

### 6. PDF Upload Route (`routes/upload.py`)
```python
import os
import uuid
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Header, HTTPException, Form
from firebase_admin import auth
from PyMuPDF import fitz
from backend.ingest.embed_and_store import process_and_store_pdf
from services.database import get_firestore

router = APIRouter()

@router.post("/upload-pdf")
async def upload_pdf(
    file: UploadFile = File(...),
    folder_id: str = Form(...),
    authorization: str = Header(...),
):
    """
    Upload and process a PDF file
    
    Args:
        file: PDF file to upload
        folder_id: Target folder ID
        authorization: Firebase auth token
    
    Returns:
        Upload result with processing info
    """
    # Verify Firebase token
    try:
        token = authorization.split(" ")[1]
        decoded = auth.verify_id_token(token)
        user_id = decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Validate file
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are allowed")

    try:
        # Read PDF content
        pdf_content = await file.read()
        
        # Extract text from PDF
        pdf_text = extract_text_from_pdf(pdf_content)
        
        if not pdf_text.strip():
            raise HTTPException(status_code=400, detail="No text found in PDF")

        # Generate PDF ID
        pdf_id = str(uuid.uuid4())
        
        # Process and store in vector store
        chunk_count = process_and_store_pdf(
            pdf_text=pdf_text,
            user_id=user_id,
            folder_id=folder_id,
            pdf_id=pdf_id,
            pdf_name=file.filename
        )
        
        # Store metadata in Firestore
        db = get_firestore()
        db.collection("users") \
          .document(user_id) \
          .collection("folders") \
          .document(folder_id) \
          .collection("pdfs") \
          .document(pdf_id) \
          .set({
              "filename": file.filename,
              "uploadedAt": firestore.SERVER_TIMESTAMP,
              "chunkCount": chunk_count,
              "status": "processed"
          })

        return {
            "success": True,
            "pdf_id": pdf_id,
            "filename": file.filename,
            "chunk_count": chunk_count,
            "message": "PDF uploaded and processed successfully"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")

def extract_text_from_pdf(pdf_content: bytes) -> str:
    """Extract text from PDF bytes"""
    doc = fitz.open(stream=pdf_content, filetype="pdf")
    text = ""
    
    for page in doc:
        text += page.get_text()
    
    doc.close()
    return text
```

### 7. Chat Route (`routes/chat.py`)
```python
from fastapi import APIRouter, Header, HTTPException
from firebase_admin import auth
from pydantic import BaseModel
from backend.rag.chain import build_rag_chain

router = APIRouter()

class ChatRequest(BaseModel):
    question: str
    folder_id: str
    provider: str | None = "openai"

@router.post("/chat")
async def chat(
    request: ChatRequest,
    authorization: str = Header(...),
):
    """
    Chat endpoint with RAG functionality
    
    Args:
        request: Chat request with question and folder
        authorization: Firebase auth token
    
    Returns:
        AI response based on documents and conversation
    """
    # Verify Firebase token
    try:
        token = authorization.split(" ")[1]
        decoded = auth.verify_id_token(token)
        user_id = decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    # Build RAG chain
    rag_chain = build_rag_chain(
        user_id=user_id,
        folder_id=request.folder_id,
        provider=request.provider or "openai",
    )

    # Get answer
    answer = rag_chain(request.question)

    return {"answer": answer}
```

### 8. Main FastAPI App (`main.py`)
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.upload import router as upload_router
from routes.chat import router as chat_router

app = FastAPI(title="RAG PDF Chat API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(upload_router, prefix="/api")
app.include_router(chat_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "RAG PDF Chat API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

## 🔑 Environment Variables (.env)
```bash
# AstraDB Configuration
ASTRA_DB_API_ENDPOINT=https://your-endpoint.apps.astra.datastax.com
ASTRA_DB_APPLICATION_TOKEN=AstraCS:your-token
ASTRA_DB_NAMESPACE=default_keyspace

# OpenAI Configuration
OPENAI_API_KEY=sk-your-openai-key

# Google AI Configuration
GOOGLE_API_KEY=your-google-api-key

# Groq Configuration (optional)
GROQ_API_KEY=your-groq-api-key

# HuggingFace Configuration (optional)
HUGGINGFACE_API_KEY=your-huggingface-key

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY=firebase-adminsdk.json
```

## 📦 Requirements.txt
```txt
langchain
langchain-groq
langchain-openai
langchain-astradb
langchain-community
fastapi
uvicorn[standard]
python-multipart
PyMuPDF
firebase-admin
google-generativeai
openai
transformers
torch
python-dotenv
```

## 🚀 How It Works

### 1. PDF Upload Flow
```
User uploads PDF → FastAPI receives file → PyMuPDF extracts text → 
Text chunked → Embeddings created → Stored in AstraDB → Metadata saved to Firestore
```

### 2. Chat Flow
```
User asks question → Firebase auth → RAG chain built → 
Retriever fetches relevant chunks → Context formatted → 
LLM generates answer → Response returned
```

### 3. Key Components

**Vector Store (AstraDB):**
- Stores document embeddings with metadata
- Allows filtered retrieval by user/folder
- Scalable for large document collections

**Text Processing:**
- Recursive character splitting (1000 chars, 200 overlap)
- Preserves metadata (user, folder, PDF info)
- Efficient chunking for better retrieval

**RAG Chain:**
- Configurable LLM providers (OpenAI, Groq, Gemini, HuggingFace)
- Context-aware prompting
- Graceful handling of no-document scenarios

## 🔍 Testing the System

### Upload Test
```bash
curl -X POST "http://localhost:8000/api/upload-pdf" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -F "file=@document.pdf" \
  -F "folder_id=your-folder-id"
```

### Chat Test
```bash
curl -X POST "http://localhost:8000/api/chat" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is this document about?",
    "folder_id": "your-folder-id",
    "provider": "openai"
  }'
```

## 🐛 Common Issues & Solutions

1. **No documents retrieved**: Check metadata keys (userId vs user_id)
2. **Embedding errors**: Verify OpenAI API key and model access
3. **AstraDB connection**: Check endpoint URL and application token
4. **Firebase auth**: Ensure service account key is valid
5. **Memory issues**: Adjust chunk size for large PDFs

## 🎯 Optimization Tips

1. **Chunk size**: 1000 chars with 200 overlap works well for most docs
2. **Retrieval**: k=5 provides good balance of relevance vs context
3. **Temperature**: 0.0 for factual answers, 0.7 for creative responses
4. **Models**: GPT-4o-mini for cost efficiency, Groq for speed

This complete RAG system handles the full pipeline from document upload to intelligent chat responses!
