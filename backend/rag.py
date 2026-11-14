import json
import re
from pathlib import Path

DATA = Path(__file__).parent / "data" / "layanan.json"
_koleksi = None
_data = None

# Kata umum yang tidak membantu mencocokkan topik
STOPWORD = {
    "apakah", "apa", "yang", "dan", "di", "ke", "dari", "untuk", "dengan", "ini", "itu",
    "harus", "bagaimana", "berapa", "kalau", "jika", "bisa", "lewat", "saya", "mau",
    "atau", "ada", "tidak", "akan", "sudah", "dapat", "oleh", "pada", "bila", "cara",
}


def _kata(teks: str) -> set:
    return {k for k in re.findall(r"\w+", teks.lower()) if len(k) >= 3 and k not in STOPWORD}


def _muat_data() -> list:
    global _data
    if _data is None:
        _data = json.loads(DATA.read_text(encoding="utf-8"))
    return _data


def _muat():
    """Buat koleksi ChromaDB di memori dari layanan.json (sekali saja)."""
    global _koleksi
    if _koleksi is None:
        import chromadb

        klien = chromadb.Client()
        koleksi = klien.get_or_create_collection("layanan")
        if koleksi.count() == 0:
            data = _muat_data()
            koleksi.add(
                ids=[d["id"] for d in data],
                documents=[d["teks"] for d in data],
                metadatas=[{"sumber": d["sumber"]} for d in data],
            )
        _koleksi = koleksi
    return _koleksi


def _cari_kata_kunci(pertanyaan: str, n: int) -> list:
    """Urutkan potongan berdasarkan kata kunci yang cocok. Kata yang jarang muncul
    (misalnya KTP) berbobot lebih besar daripada kata umum (misalnya bayar)."""
    data = _muat_data()
    kata_doc = [_kata(d["teks"]) for d in data]
    kunci = _kata(pertanyaan)
    skor = []
    for d, kd in zip(data, kata_doc):
        nilai = 0.0
        for k in kunci & kd:
            jumlah_doc = sum(1 for x in kata_doc if k in x)
            nilai += 1 / jumlah_doc
        if nilai > 0:
            skor.append((nilai, d))
    skor.sort(key=lambda x: -x[0])
    return [d for _, d in skor[:n]]


def cari_info(pertanyaan: str, n: int = 3) -> str:
    """Gabungan pencarian makna (ChromaDB) dan kata kunci. Kembalikan potongan beserta
    sumbernya, atau teks kosong. Tidak pernah melempar error."""
    hasil = []  # daftar (teks, sumber), tanpa duplikat

    def tambah(teks, sumber):
        if all(teks != t for t, _ in hasil):
            hasil.append((teks, sumber))

    # 1. Pencocokan kata kunci berbobot (kuat untuk istilah unik seperti KTP, PLN, BPJS)
    try:
        for d in _cari_kata_kunci(pertanyaan, 2):
            tambah(d["teks"], d["sumber"])
    except Exception as e:
        print("ERROR RAG kata kunci:", e)

    # 2. Pencarian makna lewat ChromaDB
    try:
        res = _muat().query(query_texts=[pertanyaan], n_results=n)
        for teks, meta in zip(res["documents"][0], res["metadatas"][0]):
            tambah(teks, meta["sumber"])
    except Exception as e:
        print("ERROR RAG embedding (lanjut dengan kata kunci saja):", e)

    return "\n".join(f"- {t} (sumber: {s})" for t, s in hasil[:n])