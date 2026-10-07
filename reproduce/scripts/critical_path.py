"""Longest import chain (by module count and by source lines) inside a Lean source tree.

Usage: python3 -I critical_path.py <lean_root_dir> <Module.Name> [<built_modules_file>]

With a third argument (one built module name per line), also reports the longest
chain among modules not yet built, which bounds the remaining serial work.
"""
import functools
import os
import re
import sys

root, start = sys.argv[1], sys.argv[2]
built = set()
if len(sys.argv) > 3:
    built = {l.strip() for l in open(sys.argv[3]) if l.strip()}
IMPORT_RE = re.compile(r'^\s*(?:public\s+)?(?:meta\s+)?import\s+(?:all\s+)?([A-Za-z0-9_.«»\'!?]+)')
sys.setrecursionlimit(100000)


def path_of(mod):
    return os.path.join(root, *mod.split('.')) + '.lean'


@functools.lru_cache(maxsize=None)
def info(mod):
    deps, lines = [], 0
    with open(path_of(mod), encoding='utf-8') as fh:
        header = True
        for line in fh:
            lines += 1
            if header:
                m = IMPORT_RE.match(line)
                if m:
                    if os.path.exists(path_of(m.group(1))):
                        deps.append(m.group(1))
                elif line.strip() and not line.strip().startswith(('--', '/-', 'module', 'prelude')):
                    header = False
    return tuple(deps), lines


@functools.lru_cache(maxsize=None)
def depth(mod, remaining_only):
    deps, lines = info(mod)
    if remaining_only and mod in built:
        return (0, 0)
    best = (0, 0)
    for d in deps:
        best = max(best, depth(d, remaining_only), key=lambda t: t[1])
    return (best[0] + 1, best[1] + lines)


seen, stack = set(), [start]
while stack:
    m = stack.pop()
    if m in seen:
        continue
    seen.add(m)
    stack.extend(info(m)[0])
total_lines = sum(info(m)[1] for m in seen)
n, l = depth(start, False)
print(f'modules={len(seen)} total_lines={total_lines}')
print(f'longest chain (weighted by lines): {n} modules, {l} lines ({100*l/total_lines:.1f}% of all lines)')
if built:
    rem = [m for m in seen if m not in built]
    rn, rl = depth(start, True)
    print(f'not yet built: {len(rem)} modules, {sum(info(m)[1] for m in rem)} lines')
    print(f'longest remaining chain: {rn} modules, {rl} lines')
