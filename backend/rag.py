import json
from pathlib import Path

DATA = Path(__file__).parent / "data" / "layanan.json"
_koleksi = None


def _muat():
    """Buat koleksi ChromaDB di memori dari layanan.json (sekali saja)."""
    global _koleksi
    if _koleksi is None:
        import chromadb

        klien = chromadb.Client()
        koleksi = klien.get_or_create_collection("layanan")
        if koleksi.count() == 0:
            data = json.loads(DATA.read_text(encoding="utf-8"))
            koleksi.add(
                ids=[d["id"] for d in data],
                documents=[d["teks"] for d in data],
                metadatas=[{"sumber": d["sumber"]} for d in data],
            )
        _koleksi = koleksi
    return _koleksi


def cari_info(pertanyaan: str, n: int = 2) -> str:
    """Kembalikan potongan info relevan beserta sumbernya, atau teks kosong.
    Tidak pernah melempar error: kalau RAG gagal, jawaban tetap jalan tanpa RAG."""
    try:
        hasil = _muat().query(query_texts=[pertanyaan], n_results=n)
        baris = []
        for teks, meta in zip(hasil["documents"][0], hasil["metadatas"][0]):
            baris.append(f"- {teks} (sumber: {meta['sumber']})")
        return "\n".join(baris)
    except Exception as e:
        print("ERROR RAG (lanjut tanpa RAG):", e)
        return ""