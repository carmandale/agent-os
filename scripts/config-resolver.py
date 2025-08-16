#!/usr/bin/env python3
"""
Resolve project configuration by precedence:
  .env/.env.local > start.sh > .agent-os/product/tech-stack.md

Outputs JSON to stdout, e.g.:
{
  "python_package_manager": "uv",
  "javascript_package_manager": "yarn",
  "frontend_port": 3001,
  "backend_port": 8001,
  "startup_command": "./start.sh"
}
"""
import json
import os
import re
from pathlib import Path

ROOT = Path(os.getcwd())

def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""

def parse_env_file(path: Path) -> dict:
    cfg = {}
    if not path.exists():
        return cfg
    for line in read_text(path).splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, val = line.split('=', 1)
            key = key.strip()
            val = val.strip().strip('"\'')
            cfg[key] = val
    return cfg

def detect_pkg_manager_from_start(start_sh: str) -> dict:
    js = None
    py = None
    if re.search(r"\byarn\b", start_sh):
        js = "yarn"
    elif re.search(r"\bnpm\b", start_sh):
        js = "npm"
    elif re.search(r"\bpnpm\b", start_sh):
        js = "pnpm"
    elif re.search(r"\bbun\b", start_sh):
        js = "bun"
    if re.search(r"\buv\b", start_sh):
        py = "uv"
    elif re.search(r"\bpip\b", start_sh):
        py = "pip"
    elif re.search(r"\bpoetry\b", start_sh):
        py = "poetry"
    elif re.search(r"\bpipenv\b", start_sh):
        py = "pipenv"
    return {"javascript_package_manager": js, "python_package_manager": py}

def parse_tech_stack(md: str) -> dict:
    cfg = {}
    # Remove markdown bold/italics asterisks to simplify parsing
    md_clean = re.sub(r"\*", "", md)
    m = re.search(r"Python Package Manager:\s*([^\n]+)", md_clean)
    if m: cfg["python_package_manager"] = m.group(1).strip()
    m = re.search(r"JavaScript Package Manager:\s*([^\n]+)", md_clean)
    if m: cfg["javascript_package_manager"] = m.group(1).strip()
    m = re.search(r"Frontend Port:\s*([^\n]+)", md_clean)
    if m:
        try:
            cfg["frontend_port"] = int(m.group(1).strip())
        except Exception:
            pass
    m = re.search(r"Backend Port:\s*([^\n]+)", md_clean)
    if m:
        try:
            cfg["backend_port"] = int(m.group(1).strip())
        except Exception:
            pass
    return cfg

def main():
    result = {
        "python_package_manager": None,
        "javascript_package_manager": None,
        "frontend_port": None,
        "backend_port": None,
        "startup_command": None,
    }

    # Lowest precedence: tech-stack.md
    tech_stack_path = ROOT / ".agent-os" / "product" / "tech-stack.md"
    if tech_stack_path.exists():
        result.update({k: v for k, v in parse_tech_stack(read_text(tech_stack_path)).items() if v})

    # Middle precedence: start.sh signals
    start_sh_path = ROOT / "start.sh"
    if start_sh_path.exists():
        start_txt = read_text(start_sh_path)
        result.update({k: v for k, v in detect_pkg_manager_from_start(start_txt).items() if v})
        result["startup_command"] = "./start.sh"

    # Highest precedence: .env files
    env_local = parse_env_file(ROOT / ".env.local")
    env_backend = parse_env_file(ROOT / ".env")
    # Frontend port
    if env_local.get("PORT"):
        try:
            result["frontend_port"] = int(env_local["PORT"])
        except Exception:
            pass
    # Backend port
    api_port = env_backend.get("API_PORT") or env_backend.get("PORT")
    if api_port:
        try:
            result["backend_port"] = int(api_port)
        except Exception:
            pass

    # Normalize strings
    for key in ("python_package_manager", "javascript_package_manager"):
        if isinstance(result.get(key), str):
            result[key] = result[key].strip()

    print(json.dumps(result, separators=(",", ":")))

if __name__ == "__main__":
    main()


