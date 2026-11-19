"""Find `variables` blocks whose templates use a key defined later in the same block.

HA renders a variables mapping top to bottom, so a forward reference is undefined at run time
and the automation fails before it starts. Run locally: uv run --with pyyaml python var-order.py FILE...
Exit 1 if any forward reference is found.
"""
import re
import sys

import yaml


class _Loader(yaml.SafeLoader):
    pass


for _tag in ("!secret", "!include", "!input", "!env_var", "!include_dir_merge_named"):
    _Loader.add_constructor(_tag, lambda loader, node: f"<{node.tag}>")

WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
TEMPLATE = re.compile(r"\{[{%](.*?)[}%]\}", re.S)


def names_in(value):
    found = set()
    if isinstance(value, str):
        for body in TEMPLATE.findall(value):
            found |= set(WORD.findall(body))
    elif isinstance(value, dict):
        for item in value.values():
            found |= names_in(item)
    elif isinstance(value, list):
        for item in value:
            found |= names_in(item)
    return found


def walk(node, where, issues):
    if isinstance(node, dict):
        block = node.get("variables")
        if isinstance(block, dict):
            keys = list(block)
            for i, key in enumerate(keys):
                later = sorted(names_in(block[key]) & set(keys[i + 1:]))
                if later:
                    issues.append(f"{where}: '{key}' uses later key(s) {later}")
        for key, value in node.items():
            if key != "variables":
                walk(value, where, issues)
    elif isinstance(node, list):
        for item in node:
            walk(item, where, issues)


def main(paths):
    issues = []
    for path in paths:
        with open(path) as fh:
            data = yaml.load(fh, Loader=_Loader) or []
        items = data if isinstance(data, list) else [dict(v or {}, alias=k) for k, v in data.items()]
        for item in items:
            walk(item, f"{path}: {item.get('alias', item.get('id', '?'))}", issues)
    for line in issues:
        print(line)
    return 1 if issues else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1:]))
