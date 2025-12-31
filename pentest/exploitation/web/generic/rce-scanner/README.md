# 🔍 RCE Scanner Made By Next Project

**RCE Scanner** adalah tool scanning otomatis berbasis Python yang dirancang untuk mendeteksi keberadaan beberapa *vulnerable endpoints* atau file yang sering ditemukan dalam aplikasi web berbasis PHP seperti Laravel, ThinkPHP, dan lainnya.

Script ini sudah dilengkapi dengan pengecekan redirect, pengecekan string khusus, dan metode aman untuk mendeteksi kerentanan tanpa melakukan eksploitasi berbahaya.

![Scanner Banner](https://img.shields.io/badge/Status-Active-brightgreen) ![Python Version](https://img.shields.io/badge/Python-3.7%2B-blue) ![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 💡 Fitur Utama

- 🚀 Multi-threaded fast scanning
- 🛡️ Bypass redirect detection
- 📡 Mendukung berbagai payload populer seperti:
  - PHPUnit RCE
  - ThinkPHP RCE
  - Laravel Ignition RCE
  - FCKeditor file upload
  - elFinder exposure
  - PHPFileManager detection
- 🔄 Deteksi otomatis protokol (http/https)
- 📁 Simpan hasil scan ke `results.txt`

---

## 📂 Struktur Payload yang Dicek

| Nama Vulnerability     | Path yang Diserang                                      | Metode | Deteksi                    |
|------------------------|----------------------------------------------------------|--------|----------------------------|
| PHPUnit                | `/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php`   | POST   | `ShellOK` di response      |
| ThinkPHP 5.0.x         | `/index.php?s=/index/\think\app/invokefunction`         | GET    | `phpinfo`                  |
| Laravel Ignition       | `/_ignition/execute-solution`                           | POST   | `viewFile` di response     |
| FCKeditor Upload       | `/fckeditor/editor/filemanager/connectors/php/upload.php` | POST   | `shell.php` response check |
| elFinder               | `/elfinder/php/connector.minimal.php`                   | GET    | JSON `{"api":"2.1"}`       |
| PHPFileManager         | `/phpfilemanager.php`                                   | GET    | `File Manager`             |

---

## ⚙️ Cara Penggunaan

1. **Installasi**
```
git clone https://github.com/username/next-project-scanner.git
cd next-project-scanner
```
```
pip install -r requirements.txt
```

2. **Persiapkan list target**  
Buat file berisi daftar URL target (`list.txt`) contoh:
```
example.com
http://targetsite.org
https://another-site.net
```

3. **Jalankan script**
```bash
python scanner.py
```

**Masukkan List**
```
[?] Masukkan nama file target (contoh: list.txt):
>> list.txt
```

**Credit : Next Project**
