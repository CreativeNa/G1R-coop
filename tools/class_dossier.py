#!/usr/bin/env python3
"""Write a dossier per key class: inheritance, own properties with offsets, functions, subclasses.

Reads  sdk/classes.tsv, sdk/props.tsv, sdk/functions.tsv
Writes docs/RE/dossiers/<Class>.md and docs/RE/dossiers/INDEX.md

Why: the SDK tables are complete but flat. For actual work ("what does a chest carry",
"what does an item definition have") one wants everything about one class on one page.

Usage:  python tools\\class_dossier.py
"""
import os
import sys
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SDK = os.path.join(ROOT, "sdk")
OUT = os.path.join(ROOT, "docs", "RE", "dossiers")

# classes worth a page: the ones a mod or an analysis actually touches
WANTED = [
    # character and its modules
    "GothicCharacter", "ClientAuthoritativeCharacter", "Character", "Pawn", "Actor", "Object",
    "DataModule", "DataModule_Targeting", "DataModule_Combat", "DataModule_BaseStats",
    "DataModule_Container", "DataModule_Inventory", "DataModule_Interaction",
    # combat / GAS
    "GothicGASLibrary", "AbilitySystemComponent", "GameplayAbility", "GameplayAbility_CharacterAI",
    "GameplayAbility_CharacterAI_Gothic", "GameplayAbilityMagicBase", "GameplayAbilityCastSpell",
    "GE_Ex_Damage", "AttributeSet_Health",
    # dialogue
    "ConversationTopic", "ConversationTopicSet", "AbilityTask_ActConversationTopic",
    "AbilityTask_HandleSubdialog", "GDS",
    # story / quests
    "StoryG1R", "GameStory", "QuestSubsystem",
    # items
    "ItemDefinition", "ArmorDefinition", "WeaponDefinition", "DataModule_Container",
    # world / interaction
    "Interactive_Chest_C", "InteractiveObjectActor", "GothicTriggerVolume",
    # engine pieces the mod calls
    "World", "GameInstance", "PlayerController", "GameplayStatics",
]


def load():
    classes = {}
    with open(os.path.join(SDK, "classes.tsv"), "r", encoding="utf-8") as f:
        next(f)
        for line in f:
            name, kind, sup, pkg, np_, nf = line.rstrip("\n").split("\t")
            classes[name] = dict(kind=kind, super=sup, pkg=pkg, nprops=int(np_), nfns=int(nf))
    props = collections.defaultdict(list)
    with open(os.path.join(SDK, "props.tsv"), "r", encoding="utf-8") as f:
        next(f)
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 6:
                cls, ptype, pname, off, size, target = parts[:6]
                props[cls].append((int(off), int(size), ptype, pname, target))
    fns = collections.defaultdict(list)
    with open(os.path.join(SDK, "functions.tsv"), "r", encoding="utf-8") as f:
        next(f)
        for line in f:
            cls, fn = line.rstrip("\n").split("\t")
            fns[cls].append(fn)
    return classes, props, fns


def chain(classes, name):
    out = []
    seen = set()
    while name and name in classes and name not in seen:
        seen.add(name)
        out.append(name)
        name = classes[name]["super"]
    return list(reversed(out))


def main():
    if not os.path.isfile(os.path.join(SDK, "classes.tsv")):
        sys.exit("sdk/classes.tsv not found")
    classes, props, fns = load()
    os.makedirs(OUT, exist_ok=True)

    children = collections.defaultdict(list)
    for name, c in classes.items():
        if c["super"]:
            children[c["super"]].append(name)

    written = []
    for name in WANTED:
        if name not in classes:
            continue
        c = classes[name]
        ch = chain(classes, name)
        lines = []
        lines.append("# %s" % name)
        lines.append("")
        lines.append("`%s` in `%s`, %d own properties, %d own functions."
                     % (c["kind"], c["pkg"], c["nprops"], c["nfns"]))
        lines.append("")
        lines.append("Inheritance: " + " → ".join("`%s`" % x for x in ch))
        lines.append("")

        own = sorted(props.get(name, []))
        if own:
            lines.append("## Properties")
            lines.append("")
            lines.append("| offset | size | type | name | points at |")
            lines.append("|---|---|---|---|---|")
            for off, size, ptype, pname, target in own:
                lines.append("| %d | %d | %s | `%s` | %s |"
                             % (off, size, ptype, pname, ("`%s`" % target) if target else ""))
            lines.append("")

        f = fns.get(name, [])
        if f:
            lines.append("## Functions")
            lines.append("")
            for fn in f:
                lines.append("* `%s`" % fn)
            lines.append("")

        kids = sorted(children.get(name, []))
        if kids:
            lines.append("## Subclasses (%d)" % len(kids))
            lines.append("")
            lines.append(", ".join("`%s`" % k for k in kids[:60]))
            if len(kids) > 60:
                lines.append("")
                lines.append("… and %d more" % (len(kids) - 60))
            lines.append("")

        path = os.path.join(OUT, name + ".md")
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(lines))
        written.append(name)

    index = ["# Class dossiers", "",
             "One page per class a mod or an analysis usually touches: inheritance, own properties",
             "with exact offsets and what they point at, functions, subclasses.", "",
             "Generated by `tools/class_dossier.py`. For anything else use `sdk/props.tsv` and",
             "`sdk/functions.tsv` directly (grep by class name).", "",
             "| class | package | props | fns |", "|---|---|---|---|"]
    for name in written:
        c = classes[name]
        index.append("| [%s](%s.md) | %s | %d | %d |" % (name, name, c["pkg"], c["nprops"], c["nfns"]))
    with open(os.path.join(OUT, "INDEX.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(index))

    print("dossiers: %d" % len(written))
    print("written : %s" % OUT)


if __name__ == "__main__":
    main()
