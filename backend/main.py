from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="BACO API")

# Izinkan akses dari HP / aplikasi mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class AskRequest(BaseModel):
    pertanyaan: str
    konteks: str = ""
    bahasa: str = "id"


@app.get("/")
def cek_server():
    return {"status": "BACO backend jalan"}


@app.post("/api/analyze")
async def analyze(foto: UploadFile = File(...), bahasa: str = Form("id")):
    isi = await foto.read()
    print(f"Foto diterima: {foto.filename}, {len(isi)} byte, bahasa={bahasa}")

    # DATA PURA-PURA: nanti diganti fungsi AI dari Mutiara
    return {
        "penjelasan": "Ini surat tagihan iuran BPJS Kesehatan. Kamu diminta membayar iuran bulan ini.",
        "tenggat": "20 November 2026",
        "nominal": "Rp 150.000",
        "tindakan": "Bayar iuran lewat bank atau aplikasi sebelum tanggal tenggat.",
    }


@app.post("/api/stt")
async def stt(audio: UploadFile = File(...)):
    isi = await audio.read()
    print(f"Audio diterima: {audio.filename}, {len(isi)} byte")

    # DATA PURA-PURA
    return {"teks": "Kapan saya harus membayar?"}


@app.post("/api/ask")
def ask(req: AskRequest):
    print(f"Pertanyaan: {req.pertanyaan} (bahasa={req.bahasa})")

    # DATA PURA-PURA
    return {"jawaban": "Kamu harus membayar sebelum tanggal 20 November 2026."}