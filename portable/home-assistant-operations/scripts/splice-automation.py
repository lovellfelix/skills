"""Replace (or delete) one automation in automations.yaml by id, as text.

Usage: python3 splice-automation.py automations.yaml AUTOMATION_ID SNIPPET.yaml
       python3 splice-automation.py automations.yaml AUTOMATION_ID -      # delete it

The snippet is a one-item YAML list (`- id: ...`). Everything outside the replaced item stays
byte-identical, unlike loading and re-dumping the file (which re-sorts keys and breaks the order
of `variables`). Items are found by top-level `- ` lines; the id may be on the first line
(`- id: '123'`) or an indented `  id:` line.
"""
import re
import sys


def main(path, aid, snippet):
    with open(path) as fh:
        lines = fh.read().split("\n")
    starts = [i for i, line in enumerate(lines) if line.startswith("- ")] + [len(lines)]
    own_line = re.compile(rf"^(- |  )id: '?{re.escape(aid)}'?\s*$")
    for start, end in zip(starts, starts[1:]):
        if any(own_line.match(line) for line in lines[start:end]):
            break
    else:
        sys.exit(f"automation id {aid} not found in {path}")
    if snippet == "-":
        new = []
    else:
        with open(snippet) as fh:
            new = fh.read().rstrip("\n").split("\n")
    lines[start:end] = new
    with open(path, "w") as fh:
        fh.write("\n".join(lines))
    print(f"{path}: replaced lines {start + 1}-{end} with {len(new)} lines")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:4])
