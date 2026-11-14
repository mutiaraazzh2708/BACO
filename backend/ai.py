import os
import re
import json
import mimetypes
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

# Baca .env di folder utama proyek (root repo)
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")

BAHASA = {
    "id": "bahasa Indonesia sederhana",
    "min": "bahasa Minangkabau yang sederhana",
}
KUNCI = ["penjelasan", "tenggat", "nominal", "tindakan"]

PROMPT = """Kamu adalah BACO, asisten yang membantu tunanetra dan lansia memahami dokumen resmi.
Baca dokumen pada gambar, lalu jawab HANYA dalam JSON dengan format:
{
  "penjelasan": "penjelasan sederhana 2-4 kalimat, seperti menjelaskan ke orang awam",
  "tenggat": "semua tanggal penting (jadwal dan batas akhir), atau 'Tidak ada' jika tidak tertulis",
  "nominal": "jumlah uang; jika dokumen menyebut gratis, tulis 'Gratis'; jika tidak ada sama sekali, tulis 'Tidak ada'",
  "tindakan": "apa yang harus dilakukan pengguna, singkat dan jelas"
}
Tulis semua isi JSON dalam bahasa Indonesia sederhana.
Jangan mengarang. Jika informasi tidak ada di dokumen, tulis 'Tidak ada'.
Jika ada beberapa angka yang harus dijumlahkan, jumlahkan dengan teliti dan tulis totalnya.
Bedakan tanggal batas bayar dengan tanggal sanksi atau pemutusan, dan sebutkan keduanya jika ada.
Jika gambar bukan dokumen atau tidak terbaca, jelaskan di 'penjelasan' dan minta pengguna memotret ulang."""

GAYA_MINANG = """Panduan bahasa Minang: gunakan kalimat pendek dan kata sehari-hari seperti
'indak' (tidak), 'bayia' (bayar), 'ambo' (saya), 'iko' (ini), 'sabalun' (sebelum),
'lah' (sudah), 'bana' (sungguh/sangat). Hindari kata Indonesia baku jika ada padanan
Minang yang umum. Angka, tanggal, nama tempat, dan nama instansi tetap ditulis apa adanya.
Jangan memakai kata 'kaba' untuk 'surat'. Tulis 'surek' untuk surat.

Contoh gaya (sesuaikan dengan koreksi penutur):
- Indonesia: "Pengambilan ini gratis."  ->  Minang: "Mangambiak iko indak bayia."
- Indonesia: "Bawa Kartu Keluarga asli."  ->  Minang: "Baok Kartu Keluarga nan asli."
- Indonesia: "Datang sebelum tanggal 25."  ->  Minang: "Datang sabalun tanggal 25.\""""

PESAN_GAGAL = {
    "penjelasan": "Maaf, BACO belum bisa membaca dokumen ini. Coba foto ulang dengan cahaya yang cukup.",
    "tenggat": "Tidak ada",
    "nominal": "Tidak ada",
    "tindakan": "Foto ulang dokumen atau coba lagi sebentar lagi.",
}


def _parse_json(teks: str) -> dict:
    """Parse JSON dari respons Gemini, termasuk jika dibungkus ```json."""
    bersih = re.sub(r"^```(?:json)?|```$", "", teks.strip(), flags=re.MULTILINE).strip()
    data = json.loads(bersih)
    if isinstance(data, list) and data:
        data = data[0]
    if not isinstance(data, dict):
        raise ValueError("Respons bukan objek JSON")
    return data


def _angka(teks: str) -> list:
    """Ambil semua angka dari teks, untuk memastikan terjemahan tidak mengubahnya."""
    return sorted(re.findall(r"\d+", teks))


def terjemah_ke_minang(hasil: dict) -> dict:
    """Terjemahkan hasil bahasa Indonesia ke Minang. Angka dijaga tetap sama."""
    prompt = f"""Terjemahkan nilai JSON berikut ke bahasa Minangkabau sehari-hari yang sederhana.
Kunci JSON tetap sama. Jangan ubah angka, tanggal, nama tempat, dan nama instansi.
Jawab HANYA JSON.

{json.dumps(hasil, ensure_ascii=False)}

{GAYA_MINANG}"""
    response = client.models.generate_content(
        model=MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )
    data = _parse_json(response.text)
    terjemahan = {}
    for k in KUNCI:
        nilai = str(data.get(k, hasil[k]))
        # Jika angka berubah, pakai teks asli (Indonesia) agar tidak salah informasi
        if _angka(nilai) != _angka(hasil[k]):
            print(f"PERINGATAN: angka berubah di '{k}', pakai versi Indonesia")
            nilai = hasil[k]
        terjemahan[k] = nilai
    return terjemahan


def analisis_dokumen(gambar: bytes, mime_type: str = "image/jpeg", bahasa: str = "id") -> dict:
    """Baca foto dokumen, kembalikan dict: penjelasan, tenggat, nominal, tindakan.
    bahasa: 'id' (Indonesia) atau 'min' (Minang). Tidak pernah melempar error."""
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=[types.Part.from_bytes(data=gambar, mime_type=mime_type), PROMPT],
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        data = _parse_json(response.text)
        hasil = {k: str(data.get(k, "Tidak ada")) for k in KUNCI}
    except Exception as e:
        print("ERROR Gemini (analisis):", e)
        return dict(PESAN_GAGAL)

    if bahasa == "min":
        try:
            hasil = terjemah_ke_minang(hasil)
        except Exception as e:
            print("ERROR terjemah Minang (pakai hasil Indonesia):", e)
    return hasil


def jawab_pertanyaan(pertanyaan: str, konteks="", bahasa: str = "id") -> str:
    """Jawab pertanyaan pengguna berdasarkan hasil analisis dokumen.
    konteks: dict hasil analisis_dokumen atau teks. Return: teks jawaban."""
    if isinstance(konteks, dict):
        konteks = json.dumps(konteks, ensure_ascii=False)
    prompt = f"""Kamu adalah BACO, asisten yang membantu tunanetra dan lansia.
Jawab pertanyaan pengguna berdasarkan isi dokumen berikut.

Isi dokumen: {konteks}

Pertanyaan: {pertanyaan}

Aturan:
- Jawab dalam {BAHASA.get(bahasa, BAHASA["id"])}, singkat, 1-3 kalimat, mudah dipahami lansia.
- Hanya gunakan informasi dari dokumen. Jika tidak ada, katakan tidak tahu
  dan sarankan bertanya ke petugas atau instansi terkait.
- Jangan mengarang angka atau tanggal. Angka dan tanggal ditulis apa adanya.
{GAYA_MINANG if bahasa == "min" else ""}"""
    try:
        response = client.models.generate_content(model=MODEL, contents=prompt)
        return response.text.strip()
    except Exception as e:
        print("ERROR Gemini (ask):", e)
        return "Maaf, BACO belum bisa menjawab sekarang. Coba lagi sebentar lagi."


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Pemakaian:")
        print("  python backend/ai.py <foto> [id|min]")
        print('  python backend/ai.py ask "<pertanyaan>" <foto> [id|min]')
        sys.exit(1)

    def baca(path):
        mime = mimetypes.guess_type(path)[0] or "image/jpeg"
        with open(path, "rb") as f:
            return f.read(), mime

    if sys.argv[1] == "ask":
        pertanyaan, path = sys.argv[2], sys.argv[3]
        bhs = sys.argv[4] if len(sys.argv) > 4 else "id"
        img, mime = baca(path)
        hasil = analisis_dokumen(img, mime, bhs)
        print(json.dumps(hasil, indent=2, ensure_ascii=False))
        print("\nJAWABAN:", jawab_pertanyaan(pertanyaan, hasil, bhs))
    else:
        path = sys.argv[1]
        bhs = sys.argv[2] if len(sys.argv) > 2 else "id"
        img, mime = baca(path)
        print(json.dumps(analisis_dokumen(img, mime, bhs), indent=2, ensure_ascii=False))