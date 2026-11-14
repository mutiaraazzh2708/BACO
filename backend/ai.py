import os
import re
import json
import time
import mimetypes
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

try:
    from rag import cari_info
except ImportError:
    from backend.rag import cari_info

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
Jika sebagian teks buram, gelap, terpotong, atau tidak terbaca, JANGAN menebak. Tulis di awal 'penjelasan': "Sebagian dokumen kurang jelas terbaca, mohon foto ulang agar hasilnya lengkap." lalu sebutkan hanya yang benar-benar terbaca.
Jika batas waktu tidak terbaca, isi 'tindakan' dengan saran memotret ulang, bukan kalimat umum seperti "sebelum batas waktu".
Jika gambar bukan dokumen atau tidak terbaca sama sekali, jelaskan di 'penjelasan' dan minta pengguna memotret ulang."""

GAYA_MINANG = """Panduan bahasa Minang: gunakan kalimat pendek dan kata sehari-hari seperti
'indak' (tidak), 'bayia' (bayar), 'ambo' (saya), 'iko' (ini), 'sabalun' (sebelum),
'lah' (sudah), 'bana' (sungguh/sangat). Hindari kata Indonesia baku jika ada padanan
Minang yang umum. Angka, tanggal, nama tempat, dan nama instansi tetap ditulis apa adanya.
Tulis 'surek' untuk surat, jangan memakai kata 'kaba' untuk surat.
Kata 'gratis' tetap ditulis 'gratis'. Jangan menyisakan kata Indonesia seperti 'Batas akhir' atau 'Hari/Tanggal', terjemahkan semuanya.
Pakai ejaan konsisten: 'mangambiak' (bukan 'maambiak'), dan satu bentuk 'kantua' atau 'kantor' sepanjang teks."""

# "gagal": True dibaca main.py untuk memicu retry dan OCR cadangan.
PESAN_GAGAL = {
    "penjelasan": "Maaf, BACO belum bisa membaca dokumen ini. Coba foto ulang dengan cahaya yang cukup.",
    "tenggat": "Tidak ada",
    "nominal": "Tidak ada",
    "tindakan": "Foto ulang dokumen atau coba lagi sebentar lagi.",
    "gagal": True,
}
PESAN_SIBUK = {
    "penjelasan": "Maaf, layanan AI sedang sibuk. Dokumen Anda tidak bermasalah, mohon coba lagi sebentar lagi.",
    "tenggat": "Tidak ada",
    "nominal": "Tidak ada",
    "tindakan": "Tekan tombol baca dokumen sekali lagi dalam beberapa saat.",
    "gagal": True,
}

# Kode error yang biasanya sementara: layanan penuh atau kena batas kecepatan
_SEMENTARA = ("503", "429", "UNAVAILABLE", "RESOURCE_EXHAUSTED", "overloaded", "timed out")

MIME_AUDIO = {
    ".m4a": "audio/mp4",
    ".mp4": "audio/mp4",
    ".aac": "audio/aac",
    ".mp3": "audio/mp3",
    ".wav": "audio/wav",
    ".ogg": "audio/ogg",
    ".flac": "audio/flac",
    ".3gp": "audio/3gpp",
    ".webm": "audio/webm",
}


def _sementara(e: Exception) -> bool:
    return any(k.lower() in str(e).lower() for k in _SEMENTARA)


def _generate(contents, config=None, percobaan: int = 3):
    """Panggil Gemini, coba ulang otomatis kalau errornya sementara (503/429)."""
    terakhir = None
    for i in range(percobaan):
        try:
            return client.models.generate_content(model=MODEL, contents=contents, config=config)
        except Exception as e:
            terakhir = e
            if not _sementara(e) or i == percobaan - 1:
                break
            jeda = 2 * (i + 1)
            print(f"Gemini sibuk, coba lagi dalam {jeda} detik ({i + 1}/{percobaan - 1})...")
            time.sleep(jeda)
    raise terakhir


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
    response = _generate(
        prompt,
        types.GenerateContentConfig(response_mime_type="application/json"),
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


def analisis_dokumen(
    gambar: bytes, mime_type: str = "image/jpeg", bahasa: str = "id", percobaan: int = 1
) -> dict:
    """Baca foto dokumen, kembalikan dict: penjelasan, tenggat, nominal, tindakan.
    bahasa: 'id' (Indonesia) atau 'min' (Minang).
    Kalau gagal, hasilnya berisi "gagal": True (main.py yang melakukan retry + OCR cadangan).
    percobaan: jumlah percobaan ke Gemini di dalam fungsi ini. Tidak pernah melempar error."""
    try:
        response = _generate(
            [types.Part.from_bytes(data=gambar, mime_type=mime_type), PROMPT],
            types.GenerateContentConfig(response_mime_type="application/json"),
            percobaan=percobaan,
        )
        data = _parse_json(response.text)
        hasil = {k: str(data.get(k, "Tidak ada")) for k in KUNCI}
    except Exception as e:
        print("ERROR Gemini (analisis):", e)
        return dict(PESAN_SIBUK if _sementara(e) else PESAN_GAGAL)

    if bahasa == "min":
        try:
            hasil = terjemah_ke_minang(hasil)
        except Exception as e:
            print("ERROR terjemah Minang (pakai hasil Indonesia):", e)
    return hasil


def jawab_pertanyaan(pertanyaan: str, konteks="", bahasa: str = "id") -> str:
    """Jawab pertanyaan pengguna berdasarkan hasil analisis dokumen + info layanan publik.
    konteks: dict hasil analisis_dokumen atau teks. Return: teks jawaban."""
    if isinstance(konteks, dict):
        konteks = json.dumps(konteks, ensure_ascii=False)
    info = cari_info(pertanyaan)
    prompt = f"""Kamu adalah BACO, asisten pintar yang ramah dan membantu tunanetra serta lansia memahami dokumen dan layanan publik resmi Indonesia.

Konteks dokumen: {konteks if konteks else "(Belum ada dokumen yang dipindai, ini pertanyaan umum)"}

Info layanan publik referensi:
{info if info else "(tidak ada)"}

Pertanyaan pengguna: {pertanyaan}

Panduan menjawab:
- Langsung jawab inti informasinya, tanpa salam pembuka atau basa-basi.
- Jawab dalam {BAHASA.get(bahasa, BAHASA["id"])}, singkat (2-3 kalimat), bahasa sederhana yang mudah dipahami lansia.
- Jika ada konteks dokumen fisik dan pertanyaan relevan dengan isi dokumen tersebut, utamakan fakta dokumen.
- Jika pengguna bertanya tentang layanan umum resmi Indonesia (seperti cara daftar BPJS PBI/gratis, syarat pengantar RT, batas bayar tagihan listrik/PDAM, bansos DTKS, dll), jawablah dengan panduan resmi dan jelas menggunakan info referensi di atas serta pengetahuan layanan publik Indonesia.
- Jangan mengarang data fiktif atau nomor pribadi. Jika memerlukan kedatangan langsung, sebutkan nama kantor instansi yang tepat (misal kantor kelurahan atau BPJS).
{GAYA_MINANG if bahasa == "min" else ""}"""
    try:
        response = _generate(prompt)
        return response.text.strip()
    except Exception as e:
        print("ERROR Gemini (ask):", e)
        if _sementara(e):
            return "Maaf, layanan AI sedang sibuk. Coba tanya lagi sebentar lagi."
        return "Maaf, BACO belum bisa menjawab sekarang. Coba lagi sebentar lagi."


# Nama yang dipakai main.py (Rafa) untuk /api/ask
tanya_jawab = jawab_pertanyaan


def transkrip_suara(audio: bytes, suffix: str = ".m4a") -> str:
    """Ubah rekaman suara jadi teks (untuk /api/stt). Suara bisa bahasa Indonesia atau Minang.
    Melempar error kalau gagal atau hasilnya kosong, supaya main.py membalas 503."""
    mime = MIME_AUDIO.get(suffix.lower(), "audio/mp4")
    prompt = (
        "Tuliskan persis ucapan dalam rekaman ini sebagai teks. "
        "Pembicara bisa memakai bahasa Indonesia atau Minangkabau; tulis apa adanya sesuai yang diucapkan. "
        "Jawab HANYA teks ucapannya, tanpa komentar, tanpa tanda kutip. "
        "Jika tidak ada ucapan yang terdengar jelas, jawab persis: TIDAK_TERDENGAR"
    )
    response = _generate(
        [types.Part.from_bytes(data=audio, mime_type=mime), prompt],
        percobaan=2,
    )
    teks = (response.text or "").strip()
    if not teks or teks == "TIDAK_TERDENGAR":
        raise ValueError("Suara tidak terdengar jelas")
    return teks


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Pemakaian:")
        print("  python backend/ai.py <foto> [id|min]")
        print('  python backend/ai.py ask "<pertanyaan>" <foto> [id|min]')
        print("  python backend/ai.py suara <rekaman>")
        sys.exit(1)

    def baca(path):
        mime = mimetypes.guess_type(path)[0] or "image/jpeg"
        with open(path, "rb") as f:
            return f.read(), mime

    if sys.argv[1] == "suara":
        path = sys.argv[2]
        with open(path, "rb") as f:
            print(transkrip_suara(f.read(), os.path.splitext(path)[1]))
    elif sys.argv[1] == "ask":
        pertanyaan, path = sys.argv[2], sys.argv[3]
        bhs = sys.argv[4] if len(sys.argv) > 4 else "id"
        img, mime = baca(path)
        hasil = analisis_dokumen(img, mime, bhs, percobaan=3)
        print(json.dumps(hasil, indent=2, ensure_ascii=False))
        print("\nJAWABAN:", jawab_pertanyaan(pertanyaan, hasil, bhs))
    else:
        path = sys.argv[1]
        bhs = sys.argv[2] if len(sys.argv) > 2 else "id"
        img, mime = baca(path)
        print(json.dumps(analisis_dokumen(img, mime, bhs, percobaan=3), indent=2, ensure_ascii=False))