# \# BACO

# 

# \*\*BACO\*\* adalah asisten pembaca dokumen layanan publik untuk lansia dan tunanetra. Pengguna cukup memotret dokumen (tagihan BPJS, tagihan listrik, surat kelurahan, dan sejenisnya), lalu BACO menjelaskan isinya dengan bahasa sederhana dalam \*\*Bahasa Indonesia\*\* atau \*\*Bahasa Minang\*\*, menyorot tenggat, nominal, dan tindakan yang perlu dilakukan, serta bisa membacakannya dengan suara.

# 

# Proyek ini dibuat untuk Hackathon CyberTech 2026, subtema \*AI for Access and Digital Life\*.

# 

# \## Masalah yang diselesaikan

# 

# Banyak lansia dan penyandang tunanetra kesulitan memahami surat dan tagihan resmi: bahasanya kaku, angka dan tanggalnya mudah tertukar, dan mereka bergantung pada orang lain untuk membacakannya. BACO membuat informasi itu bisa dipahami sendiri, dalam bahasa yang akrab bagi mereka.

# 

# \## Fitur utama

# 

# \- \*\*Baca dokumen dari foto\*\*: kamera atau galeri, dianalisis oleh Gemini.

# \- \*\*Penjelasan sederhana\*\* dalam Bahasa Indonesia atau Minang.

# \- \*\*Kartu ringkas\*\*: tenggat, nominal, dan tindakan yang harus dilakukan.

# \- \*\*Bacakan suara (text-to-speech)\*\* di aplikasi mobile.

# \- \*\*Tanya jawab\*\*: pengguna bertanya dengan suara atau teks, jawaban berdasarkan isi dokumen dan basis informasi layanan publik (RAG).

# \- \*\*Tampilan ramah lansia\*\*: teks besar, tombol besar, kontras tinggi, alur sedikit layar.

# 

# \## Arsitektur singkat

# 

# ```

# Aplikasi mobile  ->  FastAPI (backend/)  ->  Gemini API

# &#x20;                         |

# &#x20;                         +-> ChromaDB (RAG: info layanan publik)

# ```

# 

# \- `backend/ai.py`: fungsi AI (analisis dokumen, tanya jawab, transkrip suara).

# \- `backend/main.py`: server FastAPI dan endpoint.

# \- `mobile/`: aplikasi HP (framework: \*\*ISI: Flutter / React Native / Kotlin\*\*).

# 

# \## Menjalankan backend

# 

# 1\. `cd backend`

# 2\. `python -m venv venv`

# 3\. `venv\\Scripts\\activate`

# 4\. `pip install -r requirements.txt`

# 5\. Buat file `.env` di folder utama berisi `GEMINI\_API\_KEY` dan `GEMINI\_MODEL` (tidak ikut repo). Contoh format ada di `.env.example`.

# 6\. `uvicorn main:app --host 0.0.0.0 --port 8000`

# &#x20;  (atau klik dua kali `jalankan.bat`)

# 7\. Buka http://localhost:8000/docs untuk mencoba endpoint.

# 

# Agar bisa diakses dari HP, laptop dan HP harus di jaringan Wi-Fi yang sama, firewall mengizinkan port 8000, dan aplikasi diarahkan ke IP laptop (contoh `http://192.168.x.x:8000`).

# 

# \## Menjalankan aplikasi mobile

# 

# ISI: langkah menjalankan aplikasi (dari Veli), misalnya instal dependensi, atur alamat backend, jalankan di HP.

# 

# \## Endpoint

# 

# | Method | Path | Input | Output |

# |---|---|---|---|

# | POST | `/api/analyze` | form-data `foto`, `bahasa` (`id`/`min`) | JSON: penjelasan, tenggat, nominal, tindakan |

# | POST | `/api/stt` | form-data `audio` | JSON: teks hasil transkrip |

# | POST | `/api/ask` | JSON `{"pertanyaan","konteks","bahasa"}` | JSON: jawaban |

# | GET | `/health` | tidak ada | status server |

# 

# Contoh `/api/ask`:

# 

# ```json

# {

# &#x20; "pertanyaan": "Bayarnya bisa lewat mana?",

# &#x20; "konteks": "Tagihan BPJS Rp 200.000, batas bayar 20 November 2026",

# &#x20; "bahasa": "id"

# }

# ```

# 

# \## Pengujian

# 

# Dokumen contoh ada di folder `samples/` dan seluruhnya \*\*berisi data fiktif\*\*:

# 

# \- `bpjs\_tagihan.jpg`: nominal Rp 200.000 (dijumlah dari dua baris), batas bayar 20 November 2026.

# \- `listrik\_tagihan.jpg`: nominal Rp 248.300, batas bayar 25 November (bukan tanggal pemutusan).

# \- `kelurahan\_undangan.jpg`: jadwal 23 November, nominal "Gratis".

# 

# Tes suara: `python backend/ai.py suara samples/tes\_suara.mp4`

# 

# \## Desain

# 

# Desain UI/UX: ISI link Figma di sini.

# 

# \## Teknologi, kredit, dan lisensi

# 

# Sesuai ketentuan lomba (aturan 02), berikut library, model, dan data yang dipakai beserta lisensinya. Daftar lengkap seluruh paket (termasuk dependensi turunan) dihasilkan dengan `pip-licenses`.

# 

# \### Layanan AI

# 

# | Komponen | Kegunaan | Lisensi / ketentuan |

# |---|---|---|

# | Google Gemini API | Membaca gambar dokumen, penjelasan, tanya jawab | Ketentuan layanan Google (API dengan kunci sendiri, bukan open-source) |

# 

# \### Library backend utama

# 

# | Komponen | Kegunaan | Lisensi | Sumber |

# |---|---|---|---|

# | FastAPI 0.162.7 | Framework backend | MIT | https://github.com/fastapi/fastapi |

# | Uvicorn 0.54.0 | Server ASGI | BSD-3-Clause | https://uvicorn.dev/ |

# | python-multipart 0.0.33 | Menerima upload foto/audio | Apache-2.0 | https://github.com/Kludex/python-multipart |

# | python-dotenv 1.2.4 | Membaca file `.env` | BSD-3-Clause | https://github.com/theskumar/python-dotenv |

# | google-genai 3.3.0 | Klien Gemini API | Apache-2.0 | https://github.com/googleapis/python-genai |

# | ChromaDB 1.5.9 | Basis data vektor untuk RAG | Apache-2.0 | https://github.com/chroma-core/chroma |

# | EasyOCR 1.7.2 | OCR mode cadangan | Apache-2.0 | https://github.com/jaidedai/easyocr |

# | Pillow 13.0.0 | Pengolahan gambar | MIT-CMU | https://python-pillow.org |

# | PyTorch 2.15.0 | Mesin model (dependensi EasyOCR) | BSD-3-Clause dan lisensi komponen lain | https://pytorch.org |

# | OpenCV (opencv-python-headless) 5.0.0.93 | Pengolahan gambar (dependensi EasyOCR) | Apache-2.0 | https://github.com/opencv/opencv-python |

# 

# \### Dependensi turunan yang perlu dicatat

# 

# \- `python-bidi` 0.6.12 (dependensi EasyOCR) berlisensi \*\*LGPL\*\*. Dipakai apa adanya sebagai library, tanpa modifikasi.

# \- `certifi` berlisensi MPL-2.0, dan `tqdm` serta `orjson` memuat komponen MPL-2.0.

# \- Seluruh dependensi lain berlisensi permisif (MIT, BSD, Apache-2.0, PSF, ISC).

# 

# \### Model

# 

# | Model | Kegunaan | Lisensi |

# |---|---|---|

# | Gemini `gemini-3.5-flash-lite` (bisa diganti lewat `GEMINI\_MODEL` di `.env`) | Analisis dokumen dan tanya jawab | Ketentuan layanan Google |

# | Model embedding bawaan ChromaDB (`all-MiniLM-L6-v2`, ONNX) | Pencarian makna untuk RAG | Apache-2.0 (https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) |

# | Bobot EasyOCR untuk bahasa `id` dan `en` | OCR cadangan | Diunduh otomatis oleh EasyOCR saat pertama dijalankan; kode EasyOCR berlisensi Apache-2.0 (https://github.com/JaidedAI/EasyOCR) |

# 

# \### Aplikasi mobile

# 

# ISI: daftar paket dari Veli (kamera, TTS, HTTP, rekam suara) beserta lisensinya, plus font dan ikon yang dipakai.

# 

# \*\*Sumber data RAG:\*\* ISI jumlah potongan dan sumber tiap potongan (misalnya situs resmi BPJS Kesehatan, PLN, layanan kelurahan), lengkap dengan alamat situsnya.

# 

# \## Batasan

# 

# \- BACO adalah alat bantu, \*\*bukan pengganti petugas resmi\*\*. Untuk keputusan penting (pembayaran, denda, pemutusan layanan), periksa kembali ke instansi terkait.

# \- Akurasi bergantung pada kualitas foto; foto buram atau miring dapat menghasilkan penjelasan kurang tepat.

# \- Hasil Bahasa Minang dibuat oleh model AI dan telah dinilai secara terbatas oleh penutur asli; masih mungkin ada kekeliruan.

# \- Pengenalan suara paling akurat untuk Bahasa Indonesia; logat Minang dan ruangan berisik dapat menurunkan akurasi.

# \- Dokumen yang dikirim diproses melalui API Gemini. Jangan mengunggah dokumen berisi data pribadi sensitif untuk keperluan demo.

# 

## Cara menjalankan

1. Clone repo dan masuk ke foldernya:
   git clone https://github.com/mutiaraazzh2708/BACO.git
   cd BACO

2. Buat dan aktifkan virtual environment (Python 3.12):
   py -3.12 -m venv venv
   venv\Scripts\activate

3. Install library:
   pip install fastapi uvicorn python-multipart python-dotenv google-genai pillow

4. Salin .env.example menjadi .env, lalu isi API key Gemini sendiri:
   copy .env.example .env

5. Jalankan backend:
   cd backend
   uvicorn main:app --host 0.0.0.0 --port 8000

6. Buka dokumentasi API di http://localhost:8000/docs

# 
\## Tim

# 

# | Nama | Peran |

# |---|---|

# | Rafa | Backend \& Integrasi |

# | Mutiara | AI Lead + GitHub |

# | Veli | Mobile Developer |

# | Fikri | UI/UX (Figma) + QA + Presenter |

# 

# \## Lisensi proyek

# 

# Proyek ini dirilis di bawah lisensi MIT. Lihat file \[`LICENSE`](LICENSE).

