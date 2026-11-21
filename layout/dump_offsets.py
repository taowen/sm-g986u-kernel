#!/usr/bin/env python3
"""Parse llvm-dwarfdump --debug-info output and print absolute member offsets.

Usage: dump_offsets.py probe.dwarf.txt task_struct cred file_operations ...
Prints "<struct>.<path> = 0x<off>  (size 0x..)" for every leaf member.
"""
import re
import sys

TAG = re.compile(r'^(0x[0-9a-f]+):(\s+)(DW_TAG_\w+)$')
ATTR = re.compile(r'^\s+(DW_AT_\w+)\s+(.*)$')

def parse(path):
    types = {}          # die offset -> dict
    stack = []          # list of die offsets (open scopes)
    cur = None
    with open(path, 'r', errors='replace') as f:
        for line in f:
            m = TAG.match(line.rstrip('\n'))
            if m:
                die, indent, tag = m.group(1), m.group(2), m.group(3)
                depth = len(indent)
                while stack and stack[-1][0] >= depth:
                    stack.pop()
                node = {'tag': tag, 'off': die, 'depth': depth,
                        'name': None, 'byte_size': None, 'type': None,
                        'loc': None, 'bit_size': None, 'data_bit': None,
                        'decl_file': None}
                types[die] = node
                stack.append((depth, die))
                cur = node
                continue
            m = ATTR.match(line.rstrip('\n'))
            if m and cur is not None:
                key, val = m.group(1), m.group(2).strip()
                if key == 'DW_AT_name':
                    mm = re.match(r'\("(.*)"\)', val)
                    if mm:
                        cur['name'] = mm.group(1)
                elif key == 'DW_AT_byte_size':
                    mm = re.search(r'\((0x[0-9a-f]+|\d+)\)', val)
                    if mm:
                        cur['byte_size'] = int(mm.group(1), 0)
                elif key == 'DW_AT_type':
                    mm = re.match(r'\((0x[0-9a-f]+)', val)
                    if mm:
                        cur['type'] = mm.group(1)
                elif key == 'DW_AT_data_member_location':
                    mm = re.search(r'\((0x[0-9a-f]+|\d+)\)', val)
                    if mm:
                        cur['loc'] = int(mm.group(1), 0)
                elif key == 'DW_AT_bit_size':
                    mm = re.search(r'\((\d+)\)', val)
                    if mm:
                        cur['bit_size'] = int(mm.group(1))
                elif key == 'DW_AT_data_bit_offset':
                    mm = re.search(r'\((\d+)\)', val)
                    if mm:
                        cur['data_bit'] = int(mm.group(1))
                elif key == 'DW_AT_decl_file':
                    cur['decl_file'] = val
    return types

def children(types, parent_off):
    # DIE tree is ordered; a child has depth == parent.depth + 2 and appears
    # after parent until a sibling/parent of <= depth shows up.
    parent = types[parent_off]
    out = []
    started = False
    for off, node in types.items():
        if off == parent_off:
            started = True
            continue
        if not started:
            continue
        if node['depth'] <= parent['depth']:
            break
        if node['depth'] == parent['depth'] + 2:
            out.append(off)
    return out

def type_name(types, off):
    n = types.get(off)
    return n['name'] if n and n['name'] else '?'

def is_aggregate(types, off):
    n = types.get(off)
    while n and n['tag'] in ('DW_TAG_typedef', 'DW_TAG_const_type',
                             'DW_TAG_volatile_type'):
        n = types.get(n['type']) if n['type'] else None
    return n is not None and n['tag'] in ('DW_TAG_structure_type',
                                          'DW_TAG_union_type')

def walk(types, struct_off, prefix, base, out, depth=0):
    if depth > 6:
        return
    for moff in children(types, struct_off):
        m = types[moff]
        if m['tag'] not in ('DW_TAG_member',):
            continue
        name = m['name'] or '<anon>'
        loc = base + (m['loc'] or 0)
        path = (prefix + '.' + name) if prefix else name
        t = m['type']
        tn = type_name(types, t) if t else '?'
        if t and is_aggregate(types, t) and m['name'] is None:
            walk(types, t, path, loc, out, depth + 1)
        else:
            out.append((path, loc, m['data_bit'], m['bit_size'], tn))

def dump(types, struct_name):
    cands = [o for o, n in types.items()
             if n['tag'] in ('DW_TAG_structure_type', 'DW_TAG_union_type')
             and n['name'] == struct_name]
    if not cands:
        print('!! %s not found' % struct_name)
        return
    # prefer the definition with members
    cands.sort(key=lambda o: -len(children(types, o)))
    off = cands[0]
    t = types[off]
    out = []
    walk(types, off, '', 0, out)
    print('=== %s  size=0x%x  (%d bytes) ===' %
          (struct_name, t['byte_size'] or 0, t['byte_size'] or 0))
    for path, loc, dbit, bsize, tn in out:
        extra = ''
        if bsize:
            extra = ' bit_size=%d data_bit=%d' % (bsize, dbit or 0)
        print('%-58s 0x%04x  %s%s' % (path, loc, tn, extra))
    print()

def main():
    types = parse(sys.argv[1])
    for name in sys.argv[2:]:
        dump(types, name)

if __name__ == '__main__':
    main()
