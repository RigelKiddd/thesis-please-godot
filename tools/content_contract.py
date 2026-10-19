"""Publication contracts mirrored by editor contract.js and shared fixtures.

Errors use stable codes so UI wording can change without changing semantics.
"""
import math
import json
from pathlib import Path

SCHEMA = json.loads(Path(__file__).with_name('content_schema.json').read_text(encoding='utf-8'))

def shape_errors(value, schema=SCHEMA, path='project'):
    """Shared schema subset: types, required fields, properties and array items."""
    def matches(kind):
        if kind == 'object': return isinstance(value, dict)
        if kind == 'array': return isinstance(value, list)
        if kind == 'string': return isinstance(value, str)
        if kind == 'boolean': return isinstance(value, bool)
        if kind == 'null': return value is None
        if kind == 'number': return type(value) in (int, float) and math.isfinite(value)
        if kind == 'integer': return type(value) in (int, float) and math.isfinite(value) and int(value) == value
        return False
    types = schema['type'] if isinstance(schema['type'], list) else [schema['type']]
    if not any(matches(t) for t in types):
        return [path + ':type']
    errors = []
    if isinstance(value, dict):
        for key in schema.get('required', []):
            if key not in value:
                errors.append(path + '.' + key + ':required')
        for key, child in schema.get('properties', {}).items():
            if key in value:
                errors.extend(shape_errors(value[key], child, path + '.' + key))
    if isinstance(value, list) and 'items' in schema:
        for i, child in enumerate(value):
            errors.extend(shape_errors(child, schema['items'], path + '.' + str(i)))
    return errors

SPEAKERS = ("student", "player", "auto", "system")
OPS = ("==", "!=", ">=", "<=", ">", "<", "contains", "startsWith", "in", "truthy")
NODE_TYPES = ("start", "condition", "all", "any", "not", "set", "result")


def text(v):
    return isinstance(v, str) and bool(v.strip())


def dialogue_errors(dialogue):
    if dialogue is None:
        return []
    if not isinstance(dialogue, dict):
        return ["dialogue.object"]
    nodes = dialogue.get("nodes")
    if not isinstance(nodes, list) or not nodes or any(not isinstance(n, dict) for n in nodes):
        return ["dialogue.nodes"]
    errors = []
    ids = [n.get("id") for n in nodes]
    if any(not text(i) for i in ids):
        return ["dialogue.id"]
    if len(set(ids)) != len(ids):
        errors.append("dialogue.duplicate_id")
    if dialogue.get("start") not in ids:
        errors.append("dialogue.start")
    automatic = {}
    for n in nodes:
        if n.get("speaker", "student") not in SPEAKERS:
            errors.append("dialogue.speaker")
        for key in ["text", "next"]:
            if key in n and not isinstance(n[key], str):
                errors.append("dialogue." + key)
        if n.get("next") and n["next"] not in ids:
            errors.append("dialogue.target")
        if "delay" in n and (type(n["delay"]) not in (float, int) or not math.isfinite(n["delay"]) or n["delay"] < 0):
            errors.append("dialogue.delay")
        choices = n.get("choices", [])
        if not isinstance(choices, list) or len(choices) > 4 or any(not isinstance(c, dict) for c in choices):
            errors.append("dialogue.choices")
            continue
        for c in choices:
            if not text(c.get("label")):
                errors.append("dialogue.label")
            if "next" in c and not isinstance(c["next"], str):
                errors.append("dialogue.target")
            elif c.get("next") and c["next"] not in ids:
                errors.append("dialogue.target")
            if c.get("style", "") not in ("", "checklist", "concern", "desk"):
                errors.append("dialogue.style")
            saved = c.get("timeSaved", 0)
            if type(saved) not in (int, float) or not math.isfinite(saved) or saved < 0 or int(saved) != saved:
                errors.append("dialogue.timeSaved")
        if not choices and isinstance(n.get("next"), str):
            automatic[n["id"]] = n["next"]
    for start in ids:
        seen = set()
        current = start
        while current in automatic:
            if current in seen:
                errors.append("dialogue.automatic_cycle")
                break
            seen.add(current)
            current = automatic[current]
    return sorted(set(errors))


def logic_errors(doc):
    if not isinstance(doc, dict) or not isinstance(doc.get("chains"), list):
        return ["logic.chains"]
    errors = []
    chain_ids = set()
    for chain in doc["chains"]:
        if not isinstance(chain, dict) or not text(chain.get("id")):
            errors.append("logic.id")
            continue
        if chain["id"] in chain_ids:
            errors.append("logic.duplicate_chain")
        chain_ids.add(chain["id"])
        nodes = chain.get("nodes")
        if not isinstance(nodes, list) or not nodes or any(not isinstance(n, dict) for n in nodes):
            errors.append("logic.nodes")
            continue
        ids = [n.get("id") for n in nodes]
        if any(not text(i) for i in ids):
            errors.append("logic.node_id")
            continue
        if len(set(ids)) != len(ids):
            errors.append("logic.duplicate_node")
        lookup = {n["id"]: n for n in nodes}
        entry = chain.get("entry")
        if not isinstance(entry, str) or lookup.get(entry, {}).get("type") != "start":
            errors.append("logic.entry")
            entry = ""
        if not any(n.get("type") == "result" for n in nodes):
            errors.append("logic.result_missing")
        edges = {}
        for n in nodes:
            kind = n.get("type")
            if kind not in NODE_TYPES:
                errors.append("logic.type")
            refs = [n[k] for k in ("next", "true", "false") if n.get(k) not in (None, "")]
            valid_refs = [v for v in refs if isinstance(v, str) and v in lookup]
            if len(valid_refs) != len(refs):
                errors.append("logic.target")
            edges[n["id"]] = valid_refs
            if kind == "result":
                if n.get("result") not in ("approve", "return", "reject", "flag"):
                    errors.append("logic.result")
                if refs:
                    errors.append("logic.result_edges")
            if kind == "set" and not text(n.get("field")):
                errors.append("logic.set_field")
            if kind in ("condition", "all", "any", "not"):
                clauses = [n] if kind == "condition" else n.get("conditions")
                if not isinstance(clauses, list) or not clauses:
                    errors.append("logic.conditions")
                else:
                    for c in clauses:
                        if not isinstance(c, dict) or not text(c.get("field")) or c.get("op") not in OPS:
                            errors.append("logic.condition")
        visited, visiting = set(), set()
        def visit(nid):
            if nid in visiting:
                errors.append("logic.cycle")
                return
            if nid in visited or nid not in edges:
                return
            visiting.add(nid)
            for nxt in edges[nid]:
                visit(nxt)
            visiting.remove(nid)
            visited.add(nid)
        visit(entry)
        if set(ids) - visited:
            errors.append("logic.unreachable")
    return sorted(set(errors))
