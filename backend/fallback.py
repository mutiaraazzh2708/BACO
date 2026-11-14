import os
import tempfile

_reader = None


def _get_reader():
    global _reader
    if _reader is None:
        import easyocr
        _reader = easyocr.Reader(["id", "en"], gpu=False)
    return _reader


def ocr_cadangan(gambar: bytes) -> dict:
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as f:
        f.write(gambar)
        path = f.name
    try:
        teks = " ".join(_get_reader().readtext(path, detail=0)).strip()
    finally:
        os.remove(path)

    if not teks:
        teks = "Teks tidak terbaca."
    return {
        "penjelasan": "Layanan AI sedang tidak tersedia. Ini teks yang terbaca dari dokumen: " + teks[:600],
        "tenggat": "Tidak ada",
        "nominal": "Tidak ada",
        "tindakan": "Baca teks di atas, atau coba lagi sebentar lagi.",
    }