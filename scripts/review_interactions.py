#!/usr/bin/env python3
"""Create an offline frame/state inspector for any interaction recording."""
import argparse
import json
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    run, output = args.run.resolve(), args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    data = json.loads((run / "recording/trace.json").read_text())
    for sample in data["samples"]:
        sample["image"] = os.path.relpath(run / "recording" / sample["file"], output)
    data["video"] = os.path.relpath(run / "interaction.mp4", output)
    data["slow"] = os.path.relpath(run / "slow.mp4", output)
    encoded = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")
    page = '''<!doctype html><html lang="ru"><meta charset="utf-8"><title>Детали Qt-MacOS</title>
<style>body{font:16px system-ui;margin:24px;background:#f5f5f7;color:#242527}main{display:flex;gap:24px}article{flex:3;min-width:0}aside{flex:1;min-width:240px}img,video{width:100%}input{width:100%}pre{white-space:pre-wrap;font:12px monospace}h1{font-size:24px}</style>
<h1>Детали Qt-MacOS: запись взаимодействий</h1>
<p>Исходные кадры и состояния приложения. Захват влияет на интервалы; это не измерение FPS или задержки дисплея.</p>
<select></select><input type="range" min="0" step="1"><p id="stamp"></p>
<main><article><img alt="Исходный кадр Qt"><video controls></video><a>Замедление 3×</a></article><aside><pre id="state"></pre><pre id="info"></pre></aside></main>
<script type="application/json" id="data">__DATA__</script><script>
const data=JSON.parse(document.querySelector('#data').textContent),select=document.querySelector('select'),slider=document.querySelector('input');
for(const tag of [...new Set(data.samples.map(s=>s.tag))]){const o=document.createElement('option');o.textContent=tag;select.append(o)}
let frames=[];function draw(){const s=frames[Number(slider.value)];document.querySelector('img').src=s.image;
 document.querySelector('#stamp').textContent=`${s.tag} · ${s.sample_ms.toFixed(1)} мс · ${Number(slider.value)+1}/${frames.length}`;
 const state={...s};delete state.image;delete state.sha256;document.querySelector('#state').textContent=JSON.stringify(state,null,2)}
function stage(){frames=data.samples.filter(s=>s.tag===select.value);slider.max=frames.length-1;slider.value=0;draw()}
select.onchange=stage;slider.oninput=draw;stage();document.querySelector('video').src=data.video;document.querySelector('a').href=data.slow;
document.querySelector('#info').textContent=JSON.stringify({qt:data.qt_version,platform:data.platform,graphicsApi:data.graphics_api,dpr:data.dpr,
 keyEvents:data.input_events.filter(e=>'key'in e).length,mouseEvents:data.input_events.filter(e=>'buttons'in e).length},null,2);
</script></html>'''.replace("__DATA__", encoded)
    (output / "index.html").write_text(page)
    print(output / "index.html")


if __name__ == "__main__":
    main()
