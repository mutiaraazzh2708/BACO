# BACO



\## Menjalankan backend

1\. cd backend

2\. python -m venv venv

3\. venv\\Scripts\\activate

4\. pip install -r requirements.txt

5\. Buat file .env di folder utama berisi GEMINI\_API\_KEY dan GEMINI\_MODEL (tidak ikut repo)

6\. uvicorn main:app --host 0.0.0.0 --port 8000

&#x20;  (atau klik dua kali jalankan.bat)

7\. Buka http://localhost:8000/docs untuk mencoba endpoint



\## Endpoint

\- POST /api/analyze : form-data "foto", "bahasa" (id/min)

\- POST /api/stt     : form-data "audio"

\- POST /api/ask     : JSON {"pertanyaan","konteks","bahasa"}

\- GET  /health      : cek server

