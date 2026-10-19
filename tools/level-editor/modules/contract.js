/* Publication validation. Keep behavior paired with tools/content_contract.py.
 * tests/fixtures/content-contract.json is executed in Python and JavaScript. */
globalThis.ThesisEditor.factories.contract = function (env) {
  'use strict';
  const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
  const text = v => typeof v === 'string' && !!v.trim();
  const unique = errors => [...new Set(errors)].sort();
  const messages = {
    'dialogue.object':'对话树必须是对象', 'dialogue.nodes':'对话树需要有效节点',
    'dialogue.id':'节点 ID 必须是非空文本', 'dialogue.duplicate_id':'对话节点 ID 重复',
    'dialogue.start':'对话起点不存在', 'dialogue.speaker':'说话人无效', 'dialogue.text':'对话文本类型错误',
    'dialogue.next':'后续节点 ID 必须是文本', 'dialogue.target':'对话指向不存在的节点',
    'dialogue.delay':'延时必须是非负数', 'dialogue.choices':'回复选项必须是对象数组，最多 4 项',
    'dialogue.label':'回复选项缺少文字', 'dialogue.style':'回复风格无效',
    'dialogue.timeSaved':'节省时间必须是非负整数', 'dialogue.automatic_cycle':'自动推进的对话存在循环',
    'logic.chains':'条件链必须是数组', 'logic.id':'条件链 ID 无效', 'logic.duplicate_chain':'条件链 ID 重复',
    'logic.nodes':'条件链需要有效节点', 'logic.node_id':'节点 ID 无效', 'logic.duplicate_node':'节点 ID 重复',
    'logic.entry':'入口必须指向起点节点', 'logic.result_missing':'缺少结果节点',
    'logic.type':'节点类型无效', 'logic.target':'连线指向不存在的节点', 'logic.result':'判断结果无效',
    'logic.result_edges':'结果节点不能有后续连线', 'logic.set_field':'赋值节点缺少字段',
    'logic.conditions':'条件组不能为空', 'logic.condition':'条件字段或运算符无效',
    'logic.cycle':'条件链存在循环', 'logic.unreachable':'存在从入口无法到达的节点',
  };
  const contractMessage = code => messages[code] || code;
  function shapeErrors(value, schema = globalThis.ThesisEditor.contentSchema, path = 'project') {
    const matches = kind => ({
      object: object(value), array: Array.isArray(value), string: typeof value === 'string',
      boolean: typeof value === 'boolean', null: value === null,
      number: typeof value === 'number' && Number.isFinite(value), integer: Number.isInteger(value),
    })[kind];
    const types = Array.isArray(schema.type) ? schema.type : [schema.type];
    if (!types.some(matches)) return [path + ':type'];
    const errors = [];
    if (object(value)) {
      for (const key of schema.required || []) if (!(key in value)) errors.push(path + '.' + key + ':required');
      for (const [key, child] of Object.entries(schema.properties || {})) if (key in value) errors.push(...shapeErrors(value[key], child, path + '.' + key));
    }
    if (Array.isArray(value) && schema.items) value.forEach((child, i) => errors.push(...shapeErrors(child, schema.items, path + '.' + i)));
    return errors;
  }
  function dialogueErrors(d) {
    if (d === null || d === undefined) return [];
    if (!object(d)) return ['dialogue.object'];
    if (!Array.isArray(d.nodes) || !d.nodes.length || d.nodes.some(n => !object(n))) return ['dialogue.nodes'];
    const errors = [], ids = d.nodes.map(n => n.id), automatic = new Map();
    if (ids.some(i => !text(i))) return ['dialogue.id'];
    if (new Set(ids).size !== ids.length) errors.push('dialogue.duplicate_id');
    if (!ids.includes(d.start)) errors.push('dialogue.start');
    for (const n of d.nodes) {
      if (!['student', 'player', 'auto', 'system'].includes(n.speaker === undefined ? 'student' : n.speaker)) errors.push('dialogue.speaker');
      for (const key of ['text', 'next']) if (key in n && typeof n[key] !== 'string') errors.push('dialogue.' + key);
      if (n.next && !ids.includes(n.next)) errors.push('dialogue.target');
      if ('delay' in n && (typeof n.delay !== 'number' || !Number.isFinite(n.delay) || n.delay < 0)) errors.push('dialogue.delay');
      const choices = n.choices === undefined ? [] : n.choices;
      if (!Array.isArray(choices) || choices.length > 4 || choices.some(c => !object(c))) { errors.push('dialogue.choices'); continue; }
      for (const c of choices) {
        if (!text(c.label)) errors.push('dialogue.label');
        if (('next' in c && typeof c.next !== 'string') || (c.next && !ids.includes(c.next))) errors.push('dialogue.target');
        if (!['', 'checklist', 'concern', 'desk'].includes(c.style === undefined ? '' : c.style)) errors.push('dialogue.style');
        const saved = c.timeSaved === undefined ? 0 : c.timeSaved;
        if (typeof saved !== 'number' || !Number.isInteger(saved) || saved < 0) errors.push('dialogue.timeSaved');
      }
      if (!choices.length && typeof n.next === 'string') automatic.set(n.id, n.next);
    }
    for (const start of ids) {
      let id = start; const seen = new Set();
      while (automatic.has(id)) {
        if (seen.has(id)) { errors.push('dialogue.automatic_cycle'); break; }
        seen.add(id); id = automatic.get(id);
      }
    }
    return unique(errors);
  }
  function logicErrors(doc) {
    if (!object(doc) || !Array.isArray(doc.chains)) return ['logic.chains'];
    const errors = [], chainIds = new Set();
    for (const chain of doc.chains) {
      if (!object(chain) || !text(chain.id)) { errors.push('logic.id'); continue; }
      if (chainIds.has(chain.id)) errors.push('logic.duplicate_chain');
      chainIds.add(chain.id);
      const nodes = chain.nodes;
      if (!Array.isArray(nodes) || !nodes.length || nodes.some(n => !object(n))) { errors.push('logic.nodes'); continue; }
      const ids = nodes.map(n => n.id);
      if (ids.some(i => !text(i))) { errors.push('logic.node_id'); continue; }
      if (new Set(ids).size !== ids.length) errors.push('logic.duplicate_node');
      const lookup = new Map(nodes.map(n => [n.id, n])), edges = new Map();
      let entry = chain.entry;
      if (typeof entry !== 'string' || lookup.get(entry)?.type !== 'start') { errors.push('logic.entry'); entry = ''; }
      if (!nodes.some(n => n.type === 'result')) errors.push('logic.result_missing');
      for (const n of nodes) {
        if (!['start','condition','all','any','not','set','result'].includes(n.type)) errors.push('logic.type');
        const refs = ['next','true','false'].map(k => n[k]).filter(v => v !== undefined && v !== null && v !== '');
        const valid = refs.filter(v => typeof v === 'string' && lookup.has(v));
        if (valid.length !== refs.length) errors.push('logic.target');
        edges.set(n.id, valid);
        if (n.type === 'result') {
          if (!['approve','return','reject','flag'].includes(n.result)) errors.push('logic.result');
          if (refs.length) errors.push('logic.result_edges');
        }
        if (n.type === 'set' && !text(n.field)) errors.push('logic.set_field');
        if (['condition','all','any','not'].includes(n.type)) {
          const clauses = n.type === 'condition' ? [n] : n.conditions;
          if (!Array.isArray(clauses) || !clauses.length) errors.push('logic.conditions');
          else for (const c of clauses) if (!object(c) || !text(c.field) || !['==','!=','>=','<=','>','<','contains','startsWith','in','truthy'].includes(c.op)) errors.push('logic.condition');
        }
      }
      const visited = new Set(), visiting = new Set();
      function visit(id) {
        if (visiting.has(id)) { errors.push('logic.cycle'); return; }
        if (visited.has(id) || !edges.has(id)) return;
        visiting.add(id); for (const next of edges.get(id)) visit(next);
        visiting.delete(id); visited.add(id);
      }
      visit(entry);
      if (ids.some(id => !visited.has(id))) errors.push('logic.unreachable');
    }
    return unique(errors);
  }
  Object.assign(env.api, {dialogueErrors, logicErrors, shapeErrors, contractMessage});
};
