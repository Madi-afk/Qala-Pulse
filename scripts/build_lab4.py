"""Build the offline Lab 4 preview and native Figma development plugin."""

import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
LAB = ROOT / "docs" / "lab4"


def main():
    spec = json.loads((LAB / "spec.json").read_text(encoding="utf-8"))
    assert len(spec["screens"]) == 15
    assert len(spec["modals"]) == 5
    screen_ids = {s["id"] for s in spec["screens"]}
    modal_ids = {s["id"] for s in spec["modals"]}
    for item in spec["screens"] + spec["modals"]:
        for block in item.get("blocks", []) + item.get("buttons", []):
            action = block.get("action", "")
            if action.startswith("go:"):
                assert action[3:] in screen_ids, action
            elif action.startswith("modal:"):
                assert action[6:] in modal_ids, action
    data = json.dumps(spec, ensure_ascii=False).replace("</", "<\\/")
    css = (LAB / "styles.css").read_text(encoding="utf-8")
    js = (LAB / "prototype.js").read_text(encoding="utf-8")
    tabs = [("prototype", "Прототип"), ("screens", "15 экранов + 5 модалей"),
            ("flow", "User Flow"), ("states", "Состояния"), ("report", "Отчёт")]
    nav = "".join(f'<button class="tab" data-tab="{key}">{label}</button>' for key, label in tabs)
    html = f'''<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>QalaPulse — Laboratory Work №4</title><style>
@font-face{{font-family:'Noto Sans';src:url('assets/NotoSans.ttf') format('truetype');font-weight:100 900;font-display:swap}}
{css}</style></head><body><header class="lab-header"><div><div class="eyebrow">LABORATORY WORK №4 · LOW-FIDELITY</div><h1>QalaPulse · Wireframes &amp; Interactions</h1></div><nav aria-label="Материалы лабораторной">{nav}</nav></header><main></main>
<script>const SPEC = {data};\n{js}</script></body></html>'''
    (LAB / "index.html").write_text(html, encoding="utf-8")
    plugin = LAB / "figma-plugin"
    runtime = (plugin / "runtime.js").read_text(encoding="utf-8")
    connect = (plugin / "connect.js").read_text(encoding="utf-8")
    (plugin / "code.js").write_text(f"const SPEC = {data};\n{connect}\n{runtime}", encoding="utf-8")
    excluded = {"QalaPulse-Lab4.zip", "figma-helpers.js", "figma-state.json"}
    with ZipFile(LAB / "QalaPulse-Lab4.zip", "w", ZIP_DEFLATED) as archive:
        for path in LAB.rglob("*"):
            if path.is_file() and path.name not in excluded:
                archive.write(path, Path("QalaPulse-Lab4") / path.relative_to(LAB))
    print("Built: index.html, figma-plugin/code.js, QalaPulse-Lab4.zip")
    print("Validated: 15 screens, 5 modals, all declarative navigation targets")


if __name__ == "__main__":
    main()
