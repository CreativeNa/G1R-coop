---
name: reverse-engineering-toolkit
description: Choose the right reverse-engineering tool for a task in this Gothic 1 Remake co-op project (Unreal Engine 5, a natively injected C++ DLL, an AngelScript mod, UDP traffic between two PCs). Use when a task needs to find a class, property or function in the engine, explain a stutter or a crash, or decode what the mod and the game exchange - and when deciding whether an existing tool can answer instead of writing another hand-rolled probe.
---

# Reverse-engineering toolkit for this project

The catalogue these tools come from is https://github.com/reacher-z/Awesome-REA (1 253 entries, but mostly web,
Android and Unity; only the few below matter here). Machine-readable exports exist at
https://awesomerea.org/catalog.json and https://awesomerea.org/llms.txt if a full search is needed.

## Pick by question, not by tool

| The question | Tool | Why this one |
|---|---|---|
| "Where does the game store X?" (skill levels, trader config, a widget state) | **UE4SS** https://github.com/UE4SS-RE/RE-UE4SS | Live UObject property views and reflected header dumps. This project already has `tools\ue4ss_probe` and a hand-written probe (`findall`, `members`, `get`); UE4SS answers the same question without a rebuild. |
| "What does this asset contain?" (AttributeSet definitions, quest assets, item classes) | **FModel** https://github.com/4sval/FModel | Reads UE5 packages with CUE4Parse, no running game. Faster than discovering a class by probing at runtime. |
| "Which function is this, and what calls it?" | **IDA / Ghidra** + the project's own `native/patch_fnsig.py` | Signature-based lookup beats scanning the object array for a class name. The project already patches functions by signature; keep that habit. |
| "Why does the frame stall?" | **WPR + WPA** (built into Windows), **PIX** for D3D12, **RenderDoc** for GPU | A CPU profiler shows the *stack* of the stall. This is what an in-mod timer cannot do: the 2026-11-07 stall is ~140 ms every 5 s and happens outside every section the mod measures, so only a sampling profiler can name it. |
| "What do the two PCs actually exchange?" | **Wireshark** + the project's `net_sim.txt`, `tools/fuzz_net.ps1` | Wireshark for the wire format; `net_sim` to inject loss/delay; `fuzz_net` to prove a malformed packet cannot kill the copy. |
| "Is the graphics driver / GPU involved?" | **RenderDoc**, **PIX** | A frame capture separates GPU stalls from CPU stalls. RenderDoc says nothing about CPU time - do not use it to explain a CPU hitch. |

## What NOT to reach for

* **UE Explorer, UELib** - Unreal Engine 1-3 packages only; this game is UE5.
* **RenderDoc** as a CPU profiler - it captures frames and GPU work, not call stacks.
* **Tracy** unless the modules are instrumented first; it needs a build with its macros.
* Android/Mobile tooling (jadx, Frida, Il2CppDumper) - irrelevant here, even though the catalogue is full of it.

## How work is done here (rules that already exist)

1. One change, one check; every working call goes to `docs/NOTES.md`, every run to `docs/TESTLOG.md` with a log line as
   evidence.
2. Prefer a measurement over an opinion: the frame-gap probe (`F frame gap` in the story module) and per-module call
   timing (`F stage <module> took N ms` in the core) already exist - use them before adding new ones.
3. A tool that reports "no problem" is only trusted when it can also say what it looked at. That is why `run_auto_tests.ps1`
   prints a reason for every skipped step.
4. Never trust a version claim about a third-party tool in the catalogue; check the repository's README for the engine
   versions it actually supports.

## Practical recipes

**Find a property at runtime (UE5).** UE4SS live view -> note the class and property name -> in this project, address it
with `probe` (`findall`, `members <addr>`, `get <addr> <Prop>`), and put the class name into `docs/NOTES.md` with the
offset you found.

**Attribute an engine hitch.** `wpr -start CPU -start GPU -filemode`, reproduce for 30 s, `wpr -stop trace.etl`, open in
WPA, sort by weight, look for the DLL's own frames first. Compare with the mod's `F frame gap` lines: if the gap is there
but no `F stage` line names a module, the time is spent outside the module updates (network loop or engine).

**Decode traffic.** Wireshark on UDP 40001 with the port filter, export bytes, and compare with the mod's own log lines
(`S event in: type N ...`). The mod's message types are documented in `docs/NOTES.md`.

**Prove robustness.** `tools\fuzz_net.ps1 -Count 200` against a running copy; expect the process alive and no new
`EXCEPTION` lines. A parse-error line is the correct answer, not a failure.
