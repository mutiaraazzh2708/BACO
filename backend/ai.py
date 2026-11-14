import os
import json
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

# Baca .env di folder utama proyek (D:\baco\.env)
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")

BAHASA = {"id": "bahasa Indonesia sederhana", "min": "bahasa Minangkabau yang sederhana"}

PROMPT = """Kamu adalah BACO, asisten yang membantu tunanetra dan lansia memahami dokumen resmi.
Baca dokumen pada gambar, lalu jawab HANYA dalam JSON dengan format:
{
  "penjelasan": "penjelasan sederhana 2-4 kalimat, seperti menjelaskan ke orang awam",
  "tenggat": "tanggal batas waktu, atau 'Tidak ada' jika tidak tertulis",
  "nominal": "jumlah uang, atau 'Tidak ada' jika tidak tertulis",
  "tindakan": "apa yang harus dilakukan pengguna, singkat dan jelas"
}
Tulis semua isi JSON dalam {bahasa}.
Jangan mengarang. Jika informasi tidak ada di dokumen, tulis 'Tidak ada'.
Jika gambar bukan dokumen atau tidak terbaca, jelaskan di 'penjelasan' dan minta pengguna memotret ulang."""

KUNCI = ["penjelasan", "tenggat", "nominal", "tindakan"]


def analisis_dokumen(gambar: bytes, mime_type: str = "image/jpeg", bahasa: str = "id") -> dict:
    prompt = PROMPT.replace("{bahasa}", BAHASA.get(bahasa, BAHASA["id"]))
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=[types.Part.from_bytes(data=gambar, mime_type=mime_type), prompt],
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        data = json.loads(response.text)
        return {k: str(data.get(k, "Tidak ada")) for k in KUNCI}
    except Exception as e:
        print("ERROR Gemini:", e)
        return {
            "penjelasan": "Maaf, BACO belum bisa membaca dokumen ini. Coba foto ulang dengan cahaya yang cukup.",
            "tenggat": "Tidak ada",
            "nominal": "Tidak ada",
            "tindakan": "Foto ulang dokumen atau coba lagi sebentar lagi.",
        }


if __name__ == "__main__":
    import sys
    path = sys.argv[1]
    with open(path, "rb") as f:
        hasil = analisis_dokumen(f.read(), "image/jpeg", sys.argv[2] if len(sys.argv) > 2 else "id")
    print(json.dumps(hasil, indent=2, ensure_ascii=False))