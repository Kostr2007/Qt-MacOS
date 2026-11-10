#!/usr/bin/env python3
"""Build a local frame inspector for two actual navigation recordings."""
import argparse
import json
import os
from pathlib import Path


def inspect(run, output):
    trace = json.loads((run / "recording/trace.json").read_text())
    samples = trace["samples"]
    def partial(key, tag):
        return sum(0 < s[key] < 1 for s in samples if s["tag"].startswith(tag))
    metrics = {
        "samples": len(samples),
        "help_enter_intermediate_opacity_samples": partial("helpOpacity", "help-enter"),
        "hover_intermediate_opacity_samples": partial("hoverOpacity", "hover-"),
        "page_intermediate_opacity_samples": partial("contentOpacity", "select-"),
        "minimum_held_back_scale": min(s["backScale"] for s in samples if s["tag"] == "back-held"),
        "help_closed_after_dialog": not samples[-1]["helpVisible"],
        "dialog_closed_at_end": not samples[-1]["advancedVisible"],
        "final_category": samples[-1]["category"],
    }
    centers = [s["helpCenterX"] for s in samples if s["tag"] == "help-enter" and "helpCenterX" in s]
    if centers:
        metrics["help_reveal_horizontal_drift_px"] = max(centers) - min(centers)
    velocities = [abs(s["hoverVelocity"]) for s in samples if "hoverVelocity" in s]
    if velocities:
        metrics["maximum_sampled_hover_speed_px_s"] = max(velocities)
    for sample in samples:
        sample["image"] = os.path.relpath(run / "recording" / sample["file"], output)
    return {"samples": samples, "metrics": metrics,
            "manifest": json.loads((run / "manifest.json").read_text()),
            "video": os.path.relpath(run / "interaction.mp4", output),
            "slow": os.path.relpath(run / "slow.mp4", output)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", type=Path, required=True)
    parser.add_argument("--after", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    data = {name: inspect(run.resolve(), output) for name, run in
            [("До", args.before), ("После", args.after)]}
    (output / "metrics.json").write_text(json.dumps({k: v["metrics"] for k, v in data.items()}, indent=2))
    # Embed serialized data as inert JSON, escaping HTML's script end delimiter.
    encoded = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")
    page = '''<!doctype html><html lang="ru"><meta charset="utf-8">
<title>Навигация Qt-MacOS: кадры взаимодействия</title>
<style>body{font:16px system-ui;margin:24px;background:#f5f5f7;color:#202024}main{display:flex;gap:20px}section{min-width:0;flex:1}img,video{width:100%;background:#ddd}input{width:100%}pre{white-space:pre-wrap;font-size:12px}select{max-width:100%}h1{font-size:24px}</style>
<h1>Навигация Qt-MacOS: до и после</h1>
<p>Реальные кадры Qt. Выберите этап и двигайте ползунок кадров. Видео использует временные метки захвата.</p>
<p>Запись с инструментированием — не измерение FPS или задержки экрана. Сценарии сохранены рядом с каждой записью;
между версиями могут добавляться действия и перемещения указателя. Сравнивайте соответствующие этапы, а не номера кадров.</p>
<main></main><script type="application/json" id="data">__DATA__</script>
<script>
const data=JSON.parse(document.querySelector('#data').textContent);
for(const [name,run] of Object.entries(data)){
 const section=document.createElement('section');document.querySelector('main').append(section);
 section.innerHTML='<h2></h2><select></select><input type="range" min="0" step="1"><p class="stamp"></p><img alt="Кадр Qt"><pre class="state"></pre><video controls></video><p><a>Замедление 3×</a></p><pre class="metrics"></pre>';
 section.querySelector('h2').textContent=name;
 const select=section.querySelector('select'),slider=section.querySelector('input');
 for(const tag of [...new Set(run.samples.map(s=>s.tag))]){const option=document.createElement('option');option.textContent=tag;select.append(option)}
 let frames=[];
 function draw(){const s=frames[Number(slider.value)];section.querySelector('img').src=s.image;
 section.querySelector('.stamp').textContent=`${s.tag} · ${s.sample_ms.toFixed(1)} мс · ${Number(slider.value)+1}/${frames.length}`;
 const state={...s};delete state.image;delete state.sha256;section.querySelector('.state').textContent=JSON.stringify(state,null,2)}
 function stage(){frames=run.samples.filter(s=>s.tag===select.value);slider.max=frames.length-1;slider.value=0;draw()}
 select.onchange=stage;slider.oninput=draw;stage();section.querySelector('video').src=run.video;
 section.querySelector('a').href=run.slow;section.querySelector('.metrics').textContent=JSON.stringify(run.metrics,null,2);
}
</script></html>'''.replace("__DATA__", encoded)
    (output / "index.html").write_text(page)
    print(output / "index.html")


if __name__ == "__main__":
    main()
