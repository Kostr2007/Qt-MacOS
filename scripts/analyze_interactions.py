#!/usr/bin/env python3
"""Compare recorded hover pixels and slider motion; build a portable scrubber."""
import argparse
import json
import os
from pathlib import Path


def metrics(trace):
    rows = trace["samples"]
    enter = [r for r in rows if r["tag"] in ["hover-rest", "hover-enter"]]
    rest, end = enter[0]["probe_luma"], enter[-1]["probe_luma"]
    result = {"sample_count": len(rows), "input_count": len(trace["input_events"]),
              "hover_rest": rest, "hover_end": end, "hover_min": min(r["probe_luma"] for r in enter),
              "hover_dark_undershoot": max(0, min(rest, end) - min(r["probe_luma"] for r in enter)),
              "profiles": []}
    for i in range(3):
        relevant = [r for r in rows if r["activeProfile"] == i]
        release = [r for r in relevant if r["tag"] == "release"]
        states = [r["sliders"][i] for r in relevant]
        settled = [r for n, r in enumerate(release) if all(abs(s["sliders"][i]["offset"]) < .05
                   and abs(s["sliders"][i]["stretch"]) < .001 for s in release[n:])]
        result["profiles"].append({"profile": i, "max_offset_px": max(abs(s["offset"]) for s in states),
            "peak_stretch": max(s["stretch"] for s in states), "final_value": states[-1]["value"],
            "final_alignment_px": abs(states[-1]["drawn"] - states[-1]["target"]),
            "release_value_drift": max(abs(r["sliders"][i]["value"] - release[0]["sliders"][i]["value"]) for r in release),
            "captured_settling_ms": settled[0]["sample_ms"] - release[0]["sample_ms"] if settled else None})
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--before", type=Path, required=True)
    p.add_argument("--after", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    a.output.mkdir(parents=True, exist_ok=True)
    traces = [json.loads((folder / "recording/trace.json").read_text()) for folder in [a.before, a.after]]
    result = {"before": metrics(traces[0]), "after": metrics(traces[1]),
              "note": "Instrumented state/pixel recordings; capture changes timing. Settling values are not physical display latency."}
    result["accepted"] = (result["after"]["hover_dark_undershoot"] < .015 and
        all(m["max_offset_px"] <= 3.001 and m["final_alignment_px"] < .05
            and m["release_value_drift"] < .00001 for m in result["after"]["profiles"]))
    (a.output / "metrics.json").write_text(json.dumps(result, indent=2))
    payload = []
    for folder, trace in zip([a.before, a.after], traces):
        base = os.path.relpath(folder.resolve(), a.output.resolve())
        payload.append({"base": base, "rows": trace["samples"]})
    page = '''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Qt-MacOS: hover и движение</title><style>body{font:16px system-ui;background:#eef0f4;color:#24252a;margin:24px}main{display:grid;grid-template-columns:1fr 1fr;gap:20px}article{background:white;padding:16px;border-radius:12px;min-width:0}img,video{width:100%}input{width:100%}pre{white-space:pre-wrap}canvas{width:100%;background:white}@media(max-width:900px){main{grid-template-columns:1fr}}</style>
<h1>Hover и движение: до / после</h1><p>Реальные кадры Qt. Общий ползунок сопоставляет одинаковые шаги сценария. Запись с захватом кадров не измеряет FPS или задержку дисплея.</p>
<input id="step" type="range" min="0" value="0"><p id="caption"></p>
<main><article><h2>До</h2><img id="before"><pre id="state0"></pre></article><article><h2>После</h2><img id="after"><pre id="state1"></pre></article></main>
<h2>Яркость hover</h2><canvas id="plot" width="1000" height="220"></canvas>
<p>Красный — до, синий — после. Провал красной линии — тёмная вспышка.</p>
<p><a id="normal">Видео после</a> · <a id="slow">Замедление 3×</a> · <a href="metrics.json">Метрики</a></p>
<script>const traces=__DATA__;const slider=document.getElementById('step');slider.max=Math.min(...traces.map(t=>t.rows.length))-1;
function update(){const n=+slider.value;document.getElementById('caption').textContent='Шаг '+n+' · '+traces[1].rows[n].tag;
traces.forEach((t,i)=>{const r=t.rows[n];document.getElementById(i?'after':'before').src=t.base+'/recording/'+r.file;document.getElementById('state'+i).textContent=JSON.stringify({t_ms:r.sample_ms,brightness:r.probe_luma,sliders:r.sliders},null,2);});}slider.oninput=update;update();
document.getElementById('normal').href=traces[1].base+'/interaction.mp4';document.getElementById('slow').href=traces[1].base+'/slow.mp4';
const c=document.getElementById('plot').getContext('2d');c.fillStyle='#444';c.font='14px system-ui';c.fillText('Яркость 0…1; шаги входа hover',15,20);
traces.forEach((t,i)=>{const rows=t.rows.filter(r=>['hover-rest','hover-enter'].includes(r.tag));c.strokeStyle=i?'#156fd1':'#d54b40';c.lineWidth=3;c.beginPath();rows.forEach((r,n)=>{const x=30+n*92,y=205-r.probe_luma*170;n?c.lineTo(x,y):c.moveTo(x,y);});c.stroke();});</script></html>'''
    (a.output / "index.html").write_text(page.replace("__DATA__", json.dumps(payload).replace("</", "<\\/")))
    print(json.dumps(result, indent=2))
    if not result["accepted"]: raise SystemExit(1)


if __name__ == "__main__": main()
