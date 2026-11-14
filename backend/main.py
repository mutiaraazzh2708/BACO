import mimetypes
import os

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ---------- Fungsi AI dari Mutiara (kalau belum ada, pakai data pura-pura) ----------
try:
    from ai import analisis_dokumen
except ImportError:
    def analisis_dokumen(gambar, mime_type="image/jpeg", bahasa="id"):
        return {
            "penjelasan": "Ini surat tagihan iuran BPJS Kesehatan. Kamu diminta membayar iuran bulan ini.",
            "tenggat": "20 November 2026",
            "nominal": "Rp 150.000",
            "tindakan": "Bayar iuran lewat bank atau aplikasi sebelum tanggal tenggat.",
        }

try:
    from ai import tanya_jawab
except ImportError:
    def tanya_jawab(pertanyaan, konteks="", bahasa="id"):
        return "Kamu harus membayar sebelum tanggal 20 November 2026."

try:
    from ai import transkrip_suara
except ImportError:
    def transkrip_suara(audio, suffix=".m4a"):
        return "Kapan saya harus membayar?"


app = FastAPI(title="BACO API")

# Izinkan akses dari HP / aplikasi mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

TIPE_OK = {"image/jpeg", "image/png", "image/webp"}
MAKS_FOTO = 8 * 1024 * 1024    # 8 MB
MAKS_AUDIO = 15 * 1024 * 1024  # 15 MB


class AskRequest(BaseModel):
    pertanyaan: str
    konteks: str = ""
    bahasa: str = "id"


@app.get("/")
def cek_server():
    return {"status": "BACO backend jalan"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/api/analyze")
async def analyze(foto: UploadFile = File(...), bahasa: str = Form("id")):
    isi = await foto.read()
    print(f"Foto diterima: {foto.filename}, {len(isi)} byte, bahasa={bahasa}")

    if not isi:
        raise HTTPException(400, "Foto kosong, coba foto ulang")
    if len(isi) > MAKS_FOTO:
        raise HTTPException(413, "Foto terlalu besar, maksimal 8 MB")

    # HP kadang mengirim tipe file generik, jadi tebak dari nama file
    mime = foto.content_type
    if mime not in TIPE_OK:
        mime = mimetypes.guess_type(foto.filename or "")[0]
    if mime not in TIPE_OK:
        raise HTTPException(400, "Format foto harus JPG, PNG, atau WEBP")

    try:
        return await run_in_threadpool(analisis_dokumen, isi, mime_type=mime, bahasa=bahasa)
    except Exception as e:
        print("ERROR analyze:", e)
        raise HTTPException(503, "BACO sedang sibuk, coba lagi sebentar")


@app.post("/api/stt")
async def stt(audio: UploadFile = File(...)):
    isi = await audio.read()
    print(f"Audio diterima: {audio.filename}, {len(isi)} byte")

    if not isi:
        raise HTTPException(400, "Rekaman kosong, coba rekam lagi")
    if len(isi) > MAKS_AUDIO:
        raise HTTPException(413, "Rekaman terlalu panjang")

    suffix = os.path.splitext(audio.filename or "")[1] or ".m4a"
    try:
        teks = await run_in_threadpool(transkrip_suara, isi, suffix)
    except Exception as e:
        print("ERROR stt:", e)
        raise HTTPException(503, "Suara belum bisa dibaca, coba rekam lagi")
    return {"teks": teks}


@app.post("/api/ask")
async def ask(req: AskRequest):
    print(f"Pertanyaan: {req.pertanyaan} (bahasa={req.bahasa})")
    try:
        jawaban = await run_in_threadpool(tanya_jawab, req.pertanyaan, req.konteks, req.bahasa)
    except Exception as e:
        print("ERROR ask:", e)
        raise HTTPException(503, "BACO sedang sibuk, coba lagi sebentar")
    return {"jawaban": jawaban}