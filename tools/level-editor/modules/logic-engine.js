/* logic-engine: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['logic-engine'] = function (env) {
'use strict';
const { $, asArray, asText, num } = env.model;
const chains = (...args) => env.api.chains(...args);

function logicNodeById(chain, id) {
  return asArray(chain?.nodes).find((n) => n.id === id) || null;
}


function logicClauses(node) {
  if (!node) return [];
  if (node.type === 'condition') return [node];
  return asArray(node.conditions);
}


function logicChainFields(chain) {
  const out = [];
  asArray(chain?.nodes).forEach((node) => {
    logicClauses(node).forEach((clause) => {
      const field = asText(clause.field).trim();
      if (field && !out.includes(field)) out.push(field);
    });
  });
  return out;
}


function parseLogicValue(raw) {
  if (typeof raw === 'boolean' || typeof raw === 'number') return raw;
  const text = asText(raw).trim();
  if (text === 'true') return true;
  if (text === 'false') return false;
  if (text === '') return '';
  const n = Number(text);
  return Number.isFinite(n) ? n : text;
}


function logicCompare(leftRaw, op, rightRaw) {
  const left = parseLogicValue(leftRaw);
  const right = parseLogicValue(rightRaw);
  switch (op) {
    case '==': return left === right || String(left) === String(right);
    case '!=': return !logicCompare(left, '==', right);
    case '>': return Number(left) > Number(right);
    case '>=': return Number(left) >= Number(right);
    case '<': return Number(left) < Number(right);
    case '<=': return Number(left) <= Number(right);
    case 'contains': return String(left).includes(String(right));
    case 'startsWith': return String(left).startsWith(String(right));
    case 'in': return String(right).split(',').map((s) => s.trim()).includes(String(left));
    case 'truthy': return Boolean(left);
    default: return false;
  }
}


function evalLogicClause(clause, ctx) {
  const field = asText(clause?.field).trim();
  if (!field) return false;
  return logicCompare(ctx[field], clause.op || '==', clause.value);
}


function evalLogicNode(node, ctx) {
  if (!node) return false;
  if (node.type === 'condition') return evalLogicClause(node, ctx);
  if (node.type === 'all') return logicClauses(node).length > 0 && logicClauses(node).every((c) => evalLogicClause(c, ctx));
  if (node.type === 'any') return logicClauses(node).some((c) => evalLogicClause(c, ctx));
  if (node.type === 'not') {
    const clauses = logicClauses(node);
    return !(clauses.length > 0 && clauses.every((c) => evalLogicClause(c, ctx)));
  }
  return true;
}


function runLogicChain(chain, ctx) {
  if (!chain) return { ok: false, error: '没有条件链', path: [], result: null };
  let id = asText(chain.entry);
  const path = [];
  const seen = new Set();
  for (let guard = 0; guard < 200; guard += 1) {
    if (!id) return { ok: false, error: '走到了空连接', path, result: null };
    if (seen.has(id)) return { ok: false, error: `检测到循环：${id}`, path, result: null };
    seen.add(id);
    const node = logicNodeById(chain, id);
    if (!node) return { ok: false, error: `找不到节点：${id}`, path, result: null };
    if (node.type === 'result') {
      const result = asText(node.result || 'flag');
      path.push({ id, type: node.type, label: node.label || result, result });
      return { ok: true, error: '', path, result };
    }
    if (node.type === 'set') {
      path.push({ id, type: node.type, label: `SET ${node.field || '?'} = ${node.value ?? ''}` });
      ctx[asText(node.field)] = parseLogicValue(node.value);
      id = asText(node.next);
      continue;
    }
    if (node.type === 'start') {
      path.push({ id, type: node.type, label: '入口' });
      id = asText(node.next);
      continue;
    }
    const value = evalLogicNode(node, ctx);
    path.push({
      id,
      type: node.type,
      label: node.type === 'condition'
        ? `${node.field || '?'} ${node.op || '=='} ${node.value ?? ''}`
        : `${node.type.toUpperCase()} ${logicClauses(node).length} 项`,
      value,
    });
    id = asText(value ? node.true : node.false);
  }
  return { ok: false, error: '判断链过长或存在环', path, result: null };
}


function logicNodeSummary(node) {
  if (!node) return '';
  if (node.type === 'condition') return `${node.field || '未选字段'} ${node.op || '=='} ${node.value ?? ''}`;
  if (node.type === 'all' || node.type === 'any' || node.type === 'not') {
    const n = logicClauses(node).length;
    const head = node.type.toUpperCase();
    return `${head} · ${n} 个条件${n ? '：' + logicClauses(node).map((c) => `${c.field || '?'} ${c.op || '=='} ${c.value ?? ''}`).join(' / ') : ''}`;
  }
  if (node.type === 'set') return `SET ${node.field || '?'} = ${node.value ?? ''}`;
  if (node.type === 'result') return node.label || node.result || '结果';
  if (node.type === 'start') return '开始 → ' + (node.next || '未连接');
  return node.type;
}


function validateLogic(errors, warnings) {
  const doc = env.model.state.content?.logicDoc || {chains: []};
  if (!Array.isArray(doc.chains)) {
    errors.push(...env.api.logicErrors(doc).map(text => ({severity:'error', text, path:'logic:0'})));
    return;
  }
  const seen = new Set();
  doc.chains.forEach((chain, index) => {
    if (seen.has(chain?.id)) errors.push({severity: "error", text: "logic.duplicate_chain", path: `logic:${index}`});
    seen.add(chain?.id);
    const nodes = asArray(chain?.nodes), ids = new Set(nodes.map(n => n?.id));
    for (const code of env.api.logicErrors({chains:[chain]})) {
      let affected = [];
      if (code === 'logic.target') affected = nodes.filter(n => n && ['next','true','false'].some(k => n[k] != null && n[k] !== '' && !ids.has(n[k]))).map(n => n.id);
      if (code === 'logic.duplicate_node') affected = nodes.filter(n => n && nodes.filter(other => other?.id === n.id).length > 1).map(n => n.id);
      errors.push({severity:'error', code, nodeIds:affected, text:`${chain?.id || '?'}: ${env.api.contractMessage(code)}${affected.length ? '（' + affected.join('、') + '）' : ''}`, path:`logic:${index}`});
    }
  });
}


Object.assign(env.api, { logicNodeById, logicClauses, logicChainFields, parseLogicValue, logicCompare, evalLogicClause, evalLogicNode, runLogicChain, logicNodeSummary, validateLogic });
};
