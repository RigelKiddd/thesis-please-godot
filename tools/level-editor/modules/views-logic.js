/* views-logic: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-logic'] = function (env) {
'use strict';
const { $, $$, clone, esc, asArray, num, LOGIC_OPS, LOGIC_RESULTS, LOGIC_NODE_LABEL, state, LOGIC_SAMPLE } = env.model;
const chains = (...args) => env.api.chains(...args);
const content = (...args) => env.api.content(...args);
const logicChainFields = (...args) => env.api.logicChainFields(...args);
const logicClauses = (...args) => env.api.logicClauses(...args);
const logicDoc = (...args) => env.api.logicDoc(...args);
const logicNodeById = (...args) => env.api.logicNodeById(...args);
const logicNodeSummary = (...args) => env.api.logicNodeSummary(...args);
const normalizeLogicDoc = (...args) => env.api.normalizeLogicDoc(...args);
const render = (...args) => env.api.render(...args);
const runLogicChain = (...args) => env.api.runLogicChain(...args);
const selChain = (...args) => env.api.selChain(...args);
const selLogicNode = (...args) => env.api.selLogicNode(...args);
const toast = (...args) => env.api.toast(...args);
const touch = (...args) => env.api.touch(...args);

function logicOptionList(selected, includeEmpty = true) {
  const chain = selChain();
  const opts = includeEmpty ? ['<option value="">— 未连接 —</option>'] : [];
  asArray(chain?.nodes).forEach((node) => {
    if (node.id === state.selectedLogicNode) return;
    opts.push(`<option value="${esc(node.id)}" ${node.id === selected ? 'selected' : ''}>${esc(node.id)} · ${esc(LOGIC_NODE_LABEL[node.type] || node.type)}</option>`);
  });
  return opts.join('');
}


function logicConnSelect(label, field, value) {
  return `<div class="field"><label>${label}</label><select data-logic-conn="${field}">${logicOptionList(value)}</select></div>`;
}


function logicConditionRow(clause, index, ownerType) {
  return `<div class="logic-clause" data-cond-row="${index}">
    <input data-logic-cond="field" data-cond-index="${index}" value="${esc(clause.field || '')}" placeholder="字段，例如 gpa" />
    <select data-logic-cond="op" data-cond-index="${index}">${LOGIC_OPS.map(([v, l]) => `<option value="${v}" ${v === (clause.op || '==') ? 'selected' : ''}>${l}</option>`).join('')}</select>
    <input data-logic-cond="value" data-cond-index="${index}" value="${esc(clause.value ?? '')}" placeholder="值" />
    <button class="btn icon" data-action="logic-del-condition" data-cond-index="${index}" title="删除条件">×</button>
  </div>`;
}


function logicInspector() {
  const chain = selChain();
  const node = selLogicNode();
  if (!chain) return '<div class="empty">先新建一条条件链。</div>';
  if (!node) return '<div class="empty">点选左侧节点编辑；或从上面添加一个节点。</div>';
  let fields = '';
  if (node.type === 'condition') {
    fields = `<div class="grid two">
      <div class="field"><label>字段</label><input data-logic-node-field="field" value="${esc(node.field || '')}" placeholder="gpa / rank / noticeDays" /></div>
      <div class="field"><label>运算符</label><select data-logic-node-field="op">${LOGIC_OPS.map(([v, l]) => `<option value="${v}" ${v === (node.op || '==') ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
    </div>
    <div class="grid two">
      <div class="field"><label>比较值</label><input data-logic-node-field="value" value="${esc(node.value ?? '')}" placeholder="3.5 / true / province" /></div>
      <div class="field"><label>节点说明</label><input data-logic-node-field="note" value="${esc(node.note || '')}" placeholder="可选" /></div>
    </div>
    <div class="grid two">${logicConnSelect('TRUE →', 'true', node.true)}${logicConnSelect('FALSE →', 'false', node.false)}</div>`;
  } else if (node.type === 'all' || node.type === 'any' || node.type === 'not') {
    const rows = logicClauses(node).map((c, i) => logicConditionRow(c, i, node.type)).join('') || '<div class="empty small">还没有条件。</div>';
    fields = `<div class="logic-clause-head"><b>${node.type.toUpperCase()} 条件组</b><button class="btn small" data-action="logic-add-condition">+ 条件</button></div>
      <div class="logic-clauses">${rows}</div>
      <div class="grid two">${logicConnSelect('TRUE →', 'true', node.true)}${logicConnSelect('FALSE →', 'false', node.false)}</div>`;
  } else if (node.type === 'set') {
    fields = `<div class="grid two">
      <div class="field"><label>字段</label><input data-logic-node-field="field" value="${esc(node.field || '')}" placeholder="flagName" /></div>
      <div class="field"><label>值</label><input data-logic-node-field="value" value="${esc(node.value ?? '')}" placeholder="true" /></div>
    </div>${logicConnSelect('NEXT →', 'next', node.next)}`;
  } else if (node.type === 'result') {
    fields = `<div class="grid two">
      <div class="field"><label>结果</label><select data-logic-node-field="result">${LOGIC_RESULTS.map(([v, l]) => `<option value="${v}" ${v === node.result ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
      <div class="field"><label>显示文字</label><input data-logic-node-field="label" value="${esc(node.label || '')}" placeholder="通过 / 退回原因" /></div>
    </div>`;
  } else if (node.type === 'start') {
    fields = logicConnSelect('NEXT →', 'next', node.next);
  }
  return `<div class="panel logic-inspector">
    <div class="panel-head"><h3>节点 · ${esc(node.id)}</h3><span class="hint">${esc(LOGIC_NODE_LABEL[node.type] || node.type)}</span></div>
    <div class="grid"><div class="field"><label>节点 id</label><input value="${esc(node.id)}" readonly /></div></div>
    ${fields}
    <div class="row" style="margin-top:10px"><button class="btn danger small" data-action="logic-del-node">删除节点</button><button class="btn small" data-action="logic-center">居中画面</button></div>
  </div>`;
}


function logicPreview(chain) {
  const fields = logicChainFields(chain);
  const ctx = { ...LOGIC_SAMPLE, ...state.logicCtx };
  const inputs = fields.map((field) => `<div class="field"><label>${esc(field)}</label><input data-logic-ctx="${esc(field)}" value="${esc(ctx[field] ?? '')}" /></div>`).join('');
  const sim = state.logicSim && state.logicSim.chainId === chain.id ? state.logicSim : null;
  const path = sim ? sim.path.map((p) => `<span class="logic-step ${p.value === true ? 'ok' : p.value === false ? 'no' : ''}">${esc(p.id)} · ${esc(p.label)}</span>`).join('<i>→</i>') : '<span class="muted">还没有试算。填好字段后点“运行判断链”。</span>';
  const result = sim ? (sim.ok ? `<b class="logic-result ${esc(sim.result)}">${esc(sim.result)}</b>` : `<b class="logic-result err">${esc(sim.error)}</b>`) : '';
  return `<div class="panel logic-preview">
    <div class="panel-head"><h3>试算上下文</h3><span class="hint">只用于编辑器预览，尚未接入游戏</span></div>
    <div class="grid four">${inputs || '<div class="empty small">这条链还没有字段。</div>'}</div>
    <div class="row" style="margin-top:10px"><button class="btn primary small" data-action="logic-run">运行判断链</button><button class="btn ghost small" data-action="logic-clear-sim">清空结果</button>${result}</div>
    <div class="logic-path">${path}</div>
  </div>`;
}


function logicEmptyView() {
  return `<div class="view-head"><div><div class="view-kicker">BRANCHING / CONDITION CHAINS</div><h1 class="view-title">条件链</h1><div class="view-sub">可视化编辑判断链：比较、AND/OR/NOT 组合、字段赋值与结果。当前只保存在内容侧，尚未接入游戏运行时。</div></div></div>
    <div class="empty" style="padding:48px"><b>还没有条件链</b><button class="btn primary" data-action="logic-add-chain">新建一条条件链</button></div>`;
}


function logicSnapshot() {
  return clone(logicDoc());
}


function pushLogicUndo() {
  state.logicUndo.push(logicSnapshot());
  if (state.logicUndo.length > 60) state.logicUndo.shift();
  state.logicRedo = [];
}


function restoreLogicSnapshot(snapshot) {
  state.content.logicDoc = normalizeLogicDoc(snapshot);
  state.selectedChain = Math.max(0, Math.min(state.selectedChain, chains().length - 1));
  const ids = asArray(selChain()?.nodes).map((n) => n.id);
  state.logicSelection = state.logicSelection.filter((id) => ids.includes(id));
  if (!state.logicSelection.length) state.logicSelection = ids.slice(0, 1);
  state.selectedLogicNode = state.logicSelection[0] || '';
  state.logicSim = null;
  touch();
  render();
}


function logicUndoStep() {
  if (!state.logicUndo.length) { toast('没有可撤销的操作', 'warn'); return; }
  state.logicRedo.push(logicSnapshot());
  restoreLogicSnapshot(state.logicUndo.pop());
}


function logicRedoStep() {
  if (!state.logicRedo.length) { toast('没有可重做的操作', 'warn'); return; }
  state.logicUndo.push(logicSnapshot());
  restoreLogicSnapshot(state.logicRedo.pop());
}


function logicSelectOnly(id, additive = false) {
  if (additive) {
    if (state.logicSelection.includes(id)) state.logicSelection = state.logicSelection.filter((x) => x !== id);
    else state.logicSelection.push(id);
    if (!state.logicSelection.length) state.logicSelection = [id];
    state.selectedLogicNode = state.logicSelection[state.logicSelection.length - 1];
  } else {
    state.logicSelection = [id];
    state.selectedLogicNode = id;
  }
}


function logicSelectedNodes() {
  const chain = selChain();
  return asArray(chain?.nodes).filter((n) => state.logicSelection.includes(n.id));
}


function logicCopySelection() {
  const nodes = logicSelectedNodes();
  if (!nodes.length) { toast('先选中节点', 'warn'); return; }
  state.logicClipboard = { nodes: clone(nodes) };
  toast(`已复制 ${nodes.length} 个节点`, 'good');
}


function logicPasteSelection() {
  const chain = selChain();
  if (!chain || !state.logicClipboard?.nodes?.length) { toast('剪贴板为空', 'warn'); return; }
  pushLogicUndo();
  const nodes = asArray(chain.nodes);
  const used = new Set(nodes.map((n) => n.id));
  const idMap = {};
  const copies = state.logicClipboard.nodes.map((src) => {
    let base = `${src.type}-copy`;
    let id = base;
    let n = 2;
    while (used.has(id)) { id = `${base}-${n}`; n += 1; }
    used.add(id);
    idMap[src.id] = id;
    return { ...clone(src), id, x: num(src.x, 60) + 42, y: num(src.y, 160) + 48 };
  });
  copies.forEach((node) => {
    ['next', 'true', 'false'].forEach((key) => {
      if (node[key] && idMap[node[key]]) node[key] = idMap[node[key]];
      else if (node[key]) node[key] = '';
    });
    chain.nodes.push(node);
  });
  state.logicSelection = copies.map((n) => n.id);
  state.selectedLogicNode = copies[0]?.id || '';
  touch();
  render();
}


function logicDeleteSelection() {
  const chain = selChain();
  if (!chain) return;
  const ids = state.logicSelection.filter((id) => id !== 'start');
  if (!ids.length) { toast('选中的节点里没有可删除项（START 保留）', 'warn'); return; }
  pushLogicUndo();
  chain.nodes = asArray(chain.nodes).filter((n) => !ids.includes(n.id));
  asArray(chain.nodes).forEach((n) => {
    ['next', 'true', 'false'].forEach((k) => { if (ids.includes(n[k])) n[k] = ''; });
  });
  if (ids.includes(chain.entry)) chain.entry = asArray(chain.nodes).find((n) => n.type === 'start')?.id || '';
  state.logicSelection = asArray(chain.nodes)[0] ? [asArray(chain.nodes)[0].id] : [];
  state.selectedLogicNode = state.logicSelection[0] || '';
  touch();
  render();
}


function logicAutoLayout() {
  const chain = selChain();
  if (!chain) return;
  pushLogicUndo();
  const nodes = asArray(chain.nodes);
  const byId = Object.fromEntries(nodes.map((n) => [n.id, n]));
  const depth = {};
  const order = [];
  const visit = (id, d) => {
    if (!id || !byId[id]) return;
    if (depth[id] !== undefined && depth[id] <= d) return;
    depth[id] = d;
    if (!order.includes(id)) order.push(id);
    const node = byId[id];
    visit(node.next, d + 1);
    visit(node.true, d + 1);
    visit(node.false, d + 1);
  };
  visit(chain.entry, 0);
  nodes.forEach((n) => { if (depth[n.id] === undefined) depth[n.id] = 0; });
  const columns = {};
  nodes.sort((a, b) => (depth[a.id] - depth[b.id]) || String(a.id).localeCompare(String(b.id)));
  nodes.forEach((node) => {
    const d = depth[node.id] || 0;
    columns[d] = (columns[d] || 0) + 1;
    node.x = 60 + d * 245;
    node.y = 70 + (columns[d] - 1) * 120;
  });
  state.logicSelection = nodes.slice(0, 1).map((n) => n.id);
  state.selectedLogicNode = state.logicSelection[0] || '';
  touch();
  render();
  toast('已按判断深度自动布局', 'good');
}


function logicZoomBy(delta) {
  state.logicZoom = Math.max(0.5, Math.min(1.6, Math.round((state.logicZoom + delta) * 10) / 10));
  applyLogicZoom();
}


function applyLogicZoom() {
  const canvas = $('#logic-canvas');
  const label = $('#logic-zoom');
  if (canvas) canvas.style.zoom = String(state.logicZoom);
  if (label) label.textContent = Math.round(state.logicZoom * 100) + '%';
}


function logicFitView() {
  const chain = selChain();
  const wrap = $('#logic-canvas-wrap');
  if (!chain || !wrap) return;
  const maxX = Math.max(980, ...asArray(chain.nodes).map((n) => num(n.x, 0) + 240));
  const maxY = Math.max(520, ...asArray(chain.nodes).map((n) => num(n.y, 0) + 170));
  state.logicZoom = Math.max(0.5, Math.min(1.1, Math.min((wrap.clientWidth - 24) / maxX, (wrap.clientHeight - 24) / maxY)));
  state.logicZoom = Math.round(state.logicZoom * 10) / 10;
  applyLogicZoom();
  wrap.scrollLeft = 0;
  wrap.scrollTop = 0;
}


function logicJumpToNode(id) {
  const node = logicNodeById(selChain(), id);
  if (!node) return;
  state.selectedLogicNode = id;
  state.logicSelection = [id];
  render();
  requestAnimationFrame(() => {
    const canvas = $('#logic-canvas');
    const wrap = $('#logic-canvas-wrap');
    const el = canvas?.querySelector(`[data-logic-node="${CSS.escape(id)}"]`);
    if (wrap && el) wrap.scrollTo({ left: Math.max(0, el.offsetLeft - 80), top: Math.max(0, el.offsetTop - 80), behavior: 'smooth' });
  });
}


function logicRunNodeSearch() {
  const q = state.logicNodeQuery.trim().toLowerCase();
  if (!q) return;
  const node = asArray(selChain()?.nodes).find((n) => n.id.toLowerCase().includes(q) || logicNodeSummary(n).toLowerCase().includes(q));
  if (!node) { toast('没有匹配的节点', 'warn'); return; }
  logicJumpToNode(node.id);
}


function logicRunChainSearch() {
  const q = state.logicChainQuery.trim().toLowerCase();
  if (!q) return;
  const index = chains().findIndex((c) => String(c.name || '').toLowerCase().includes(q) || String(c.id || '').toLowerCase().includes(q));
  if (index < 0) { toast('没有匹配的条件链', 'warn'); return; }
  state.selectedChain = index;
  state.selectedLogicNode = asArray(selChain()?.nodes)[0]?.id || '';
  state.logicSelection = [state.selectedLogicNode];
  state.logicSim = null;
  render();
}


function logicIssueNodeIds() {
  const chain = selChain();
  if (!chain) return new Set();
  const prefix = `logic:${state.selectedChain}`;
  const ids = new Set();
  [...state.validation.errors]
    .filter((issue) => String(issue.path || '').startsWith(prefix))
    .forEach((issue) => {
      asArray(chain.nodes).forEach((node) => {
        if (issue.text && issue.text.includes(String(node.id))) ids.add(node.id);
      });
      const parts = String(issue.path || '').split(':');
      const index = Number(parts[2]);
      if (Number.isInteger(index) && chain.nodes[index]) ids.add(chain.nodes[index].id);
    });
  return ids;
}



function logicNodeHTML(node, selected, hasError = false, linkTarget = false) {
  const outputs = [];
  if (node.type === 'start') outputs.push(['next', 'NEXT', node.next]);
  else if (node.type === 'set') outputs.push(['next', 'NEXT', node.next]);
  else if (node.type !== 'result') {
    outputs.push(['true', 'TRUE', node.true]);
    outputs.push(['false', 'FALSE', node.false]);
  }
  const armed = state.logicLinkSource && state.logicLinkSource.id === node.id;
  const outHtml = outputs.map(([key, label, value]) => `<span class="logic-port ${key} ${value ? 'connected' : ''} ${armed && state.logicLinkSource.port === key ? 'armed' : ''}" data-logic-port="${key}" data-logic-source="${esc(node.id)}" title="${esc(value || '未连接')}">${label}</span>`).join('');
  return `<div class="logic-node type-${esc(node.type)} ${selected ? 'selected' : ''} ${hasError ? 'has-error' : ''} ${linkTarget ? 'link-target' : ''}" data-logic-node="${esc(node.id)}" style="left:${num(node.x, 60)}px;top:${num(node.y, 160)}px">
    <div class="logic-node-head">
      <span class="logic-type">${esc(LOGIC_NODE_LABEL[node.type] || node.type)}</span>
      <b>${esc(node.id)}</b>
      ${hasError ? '<span class="logic-error-badge" title="校验问题">!</span>' : ''}
      <button class="logic-x" data-action="logic-del-node" title="删除节点">×</button>
    </div>
    <div class="logic-node-body">${esc(logicNodeSummary(node))}</div>
    <div class="logic-node-foot">${outHtml}</div>
  </div>`;
}


function viewLogic() {
  if (!chains().length) return logicEmptyView();
  const chain = selChain() || chains()[0];
  const node = selLogicNode();
  const maxY = Math.max(420, ...asArray(chain.nodes).map((n) => num(n.y, 0) + 170));
  const maxX = Math.max(980, ...asArray(chain.nodes).map((n) => num(n.x, 0) + 240));
  const selection = state.logicSelection.length ? state.logicSelection : (node ? [node.id] : []);
  const issueIds = logicIssueNodeIds();
  const linkSource = state.logicLinkSource;
  const nodes = asArray(chain.nodes).map((n) => logicNodeHTML(
    n,
    selection.includes(n.id),
    issueIds.has(n.id),
    linkSource && linkSource.id !== n.id,
  )).join('');
  const chainOptions = chains().map((c, i) => `<option value="${i}" ${i === state.selectedChain ? 'selected' : ''}>${esc(c.name || c.id)}</option>`).join('');
  const palette = ['condition', 'all', 'any', 'not', 'set', 'result']
    .map((t) => `<button class="btn small" data-action="logic-add-node" data-type="${t}">+ ${esc(LOGIC_NODE_LABEL[t])}</button>`).join('');
  const mmW = 190;
  const mmH = 112;
  const mini = asArray(chain.nodes).map((n, ni) => {
    const x = Math.round((num(n.x, 0) / maxX) * (mmW - 16)) + 4;
    const y = Math.round((num(n.y, 0) / maxY) * (mmH - 14)) + 4;
    return `<button class="mm-node ${issueIds.has(n.id) ? 'bad' : ''}" data-action="logic-jump" data-node="${esc(n.id)}" data-mm-index="${ni}" style="left:${x}px;top:${y}px" title="${esc(n.id)} · ${esc(logicNodeSummary(n))}"></button>`;
  }).join('');
  return `<div class="view-head">
    <div><div class="view-kicker">BRANCHING / CONDITION CHAINS</div><h1 class="view-title">条件链</h1><div class="view-sub">用 START → 条件 / ALL / ANY / NOT → 结果 组成判断链。拖节点调位置；点输出口再点目标节点连线。当前是编辑器功能，尚未接入游戏。</div></div>
    <div class="view-actions"><select id="logic-chain-select">${chainOptions}</select><button class="btn" data-action="logic-add-chain">+ 条件链</button><button class="btn danger small" data-action="logic-del-chain">删除链</button></div>
  </div>
  <div class="logic-toolbar">
    <div class="logic-toolgroup">
      <button class="btn small" data-action="logic-undo" title="Ctrl+Z">↶ 撤销</button>
      <button class="btn small" data-action="logic-redo" title="Ctrl+Y">↷ 重做</button>
      <button class="btn small" data-action="logic-copy" title="Ctrl+C">复制</button>
      <button class="btn small" data-action="logic-paste" title="Ctrl+V">粘贴</button>
      <button class="btn small danger" data-action="logic-delete-selection" title="Delete">删除选中</button>
      <button class="btn small" data-action="logic-autolayout">自动布局</button>
    </div>
    <div class="logic-toolgroup">
      <input id="logic-chain-search" class="logic-search" value="${esc(state.logicChainQuery)}" placeholder="搜索条件链…" />
      <button class="btn small" data-action="logic-search-chain">定位链</button>
    </div>
    <div class="logic-toolgroup">
      <input id="logic-node-search" class="logic-search" value="${esc(state.logicNodeQuery)}" placeholder="搜索节点 / 字段…" />
      <button class="btn small" data-action="logic-search-node">找节点</button>
    </div>
    <div class="logic-toolgroup logic-zoom-tools">
      <button class="btn small icon" data-action="logic-zoom-out" title="缩小">−</button>
      <span id="logic-zoom">${Math.round(state.logicZoom * 100)}%</span>
      <button class="btn small icon" data-action="logic-zoom-in" title="放大">＋</button>
      <button class="btn small" data-action="logic-fit">适配</button>
    </div>
  </div>
  <div class="logic-layout">
    <div class="logic-main">
      <div class="panel logic-canvas-panel">
        <div class="panel-head"><h3>判断图</h3><span class="hint">拖节点 · Shift 点选多个 · 点输出口再点目标节点连线 · 拖空白平移</span></div>
        <div class="logic-canvas-wrap" id="logic-canvas-wrap">
          <div class="logic-canvas" id="logic-canvas" style="width:${maxX}px;height:${maxY}px;zoom:${state.logicZoom}">
            <svg class="logic-links" id="logic-links"></svg>
            ${nodes}
          </div>
        </div>
        <div class="logic-minimap-wrap">
          <span class="logic-minimap-label">MINIMAP</span>
          <div class="logic-minimap" id="logic-minimap" style="width:${mmW}px;height:${mmH}px">${mini}</div>
          <span class="hint">${issueIds.size ? issueIds.size + ' 个节点有问题' : '拖动画布 · Ctrl+滚轮缩放'}</span>
        </div>
      </div>
      ${logicPreview(chain)}
    </div>
    <aside class="logic-side">
      <div class="panel">
        <div class="panel-head"><h3>链设置</h3><span class="hint">${esc(chain.id)}</span></div>
        <div class="grid"><div class="field"><label>名称</label><input data-logic-chain-field="name" value="${esc(chain.name || '')}" /></div></div>
        <div class="grid"><div class="field"><label>说明</label><textarea data-logic-chain-field="description" rows="2">${esc(chain.description || '')}</textarea></div></div>
        <div class="grid two"><div class="field"><label>Entry</label><select data-logic-entry>${asArray(chain.nodes).filter((n) => n.type === 'start').map((n) => `<option value="${esc(n.id)}" ${n.id === chain.entry ? 'selected' : ''}>${esc(n.id)}</option>`).join('')}</select></div></div>
      </div>
      <div class="panel"><div class="panel-head"><h3>添加节点</h3><span class="hint">放到当前链</span></div><div class="logic-palette">${palette}</div></div>
      ${logicInspector()}
      <div class="panel"><div class="panel-head"><h3>图例</h3></div><div class="logic-legend"><span><i class="dot true"></i>TRUE</span><span><i class="dot false"></i>FALSE</span><span><i class="dot next"></i>NEXT</span><span><i class="dot result"></i>RESULT</span><span><i class="dot bad"></i>ERROR</span></div></div>
    </aside>
  </div>`;
}


function drawLogicLinks() {
  const canvas = $('#logic-canvas');
  const svg = $('#logic-links');
  if (!canvas || !svg) return;
  const chain = selChain();
  if (!chain) return;
  const rect = canvas.getBoundingClientRect();
  const width = canvas.offsetWidth;
  const height = canvas.offsetHeight;
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  svg.setAttribute('width', width);
  svg.setAttribute('height', height);
  const byId = {};
  $$('.logic-node', canvas).forEach((el) => { byId[el.dataset.logicNode] = el; });
  const paths = [];
  asArray(chain.nodes).forEach((node) => {
    const el = byId[node.id];
    if (!el) return;
    const sx = el.offsetLeft + el.offsetWidth;
    const sy = el.offsetTop + 40;
    const outputs = [];
    if (node.type === 'start' || node.type === 'set') outputs.push(['next', node.next]);
    else if (node.type !== 'result') outputs.push(['true', node.true], ['false', node.false]);
    outputs.forEach(([port, target], oi) => {
      if (!target || !byId[target]) return;
      const t = byId[target];
      const tx = t.offsetLeft;
      const ty = t.offsetTop + 42;
      const color = port === 'true' ? '#4e6d4f' : port === 'false' ? '#a83a2f' : '#8a6a32';
      const bend = Math.max(50, Math.abs(tx - sx) * 0.42);
      const d = `M ${sx} ${sy + oi * 12} C ${sx + bend} ${sy + oi * 12}, ${tx - bend} ${ty}, ${tx} ${ty}`;
      paths.push(`<path d="${d}" fill="none" stroke="${color}" stroke-width="2" stroke-dasharray="${port === 'next' ? '0' : '6 4'}" opacity=".9"/>`);
      paths.push(`<text x="${sx + 8}" y="${sy + oi * 12 - 5}" fill="${color}" font-size="8" font-family="monospace">${port.toUpperCase()}</text>`);
      paths.push(`<circle cx="${tx}" cy="${ty}" r="3" fill="${color}"/>`);
    });
  });
  svg.innerHTML = paths.join('');
  // keep the SVG coordinate space stable while canvas scrolls
  svg.style.left = '0px';
  svg.style.top = '0px';
  svg.style.width = width + 'px';
  svg.style.height = height + 'px';
}


function bindLogicCanvas() {
  drawLogicLinks();
  applyLogicZoom();
  const canvas = $('#logic-canvas');
  const wrap = $('#logic-canvas-wrap');
  if (!canvas) return;
  let drag = null;
  let pan = null;
  $$('.logic-node', canvas).forEach((el) => {
    el.addEventListener('pointerdown', (event) => {
      if (event.target.closest('button, input, select, textarea, .logic-port')) return;
      const node = logicNodeById(selChain(), el.dataset.logicNode);
      if (!node) return;
      if (event.shiftKey || event.ctrlKey || event.metaKey) {
        logicSelectOnly(node.id, true);
        render();
        return;
      }
      if (!state.logicSelection.includes(node.id)) {
        state.logicSelection = [node.id];
        state.selectedLogicNode = node.id;
        render();
        return;
      }
      pushLogicUndo();
      drag = {
        id: node.id,
        startX: event.clientX,
        startY: event.clientY,
        x: num(node.x, 60),
        y: num(node.y, 160),
        el,
      };
      el.setPointerCapture?.(event.pointerId);
      event.preventDefault();
    });
  });
  canvas.addEventListener('pointermove', (event) => {
    if (!drag) return;
    const node = logicNodeById(selChain(), drag.id);
    if (!node) return;
    const z = state.logicZoom || 1;
    const dx = (event.clientX - drag.startX) / z;
    const dy = (event.clientY - drag.startY) / z;
    node.x = Math.max(10, Math.round(drag.x + dx));
    node.y = Math.max(10, Math.round(drag.y + dy));
    drag.el.style.left = node.x + 'px';
    drag.el.style.top = node.y + 'px';
    drawLogicLinks();
  });
  canvas.addEventListener('pointerup', () => {
    if (!drag) return;
    drag = null;
    touch();
  });
  canvas.addEventListener('pointercancel', () => { drag = null; });
  // Pan the canvas by dragging blank paper.
  canvas.addEventListener('pointerdown', (event) => {
    if (event.target.closest('.logic-node')) return;
    if (!wrap) return;
    pan = { x: event.clientX, y: event.clientY, left: wrap.scrollLeft, top: wrap.scrollTop };
    canvas.setPointerCapture?.(event.pointerId);
  });
  canvas.addEventListener('pointermove', (event) => {
    if (!pan || !wrap) return;
    wrap.scrollLeft = pan.left - (event.clientX - pan.x);
    wrap.scrollTop = pan.top - (event.clientY - pan.y);
  });
  canvas.addEventListener('pointerup', () => { pan = null; });
  canvas.addEventListener('pointercancel', () => { pan = null; });
  wrap?.addEventListener('wheel', (event) => {
    if (!event.ctrlKey && !event.metaKey) return;
    event.preventDefault();
    const dir = event.deltaY > 0 ? -0.1 : 0.1;
    state.logicZoom = Math.max(0.5, Math.min(1.6, Math.round((state.logicZoom + dir) * 10) / 10));
    applyLogicZoom();
  }, { passive: false });
}


function applyLogicChange(el) {
  const chain = selChain();
  if (!chain) return;
  const node = selLogicNode();
  if (el.matches('[data-logic-chain-field]')) {
    pushLogicUndo();
    chain[el.dataset.logicChainField] = el.value;
  } else if (el.matches('[data-logic-entry]')) {
    pushLogicUndo();
    chain.entry = el.value;
  } else if (el.matches('[data-logic-node-field]') && node) {
    pushLogicUndo();
    node[el.dataset.logicNodeField] = el.value;
  } else if (el.matches('[data-logic-conn]') && node) {
    pushLogicUndo();
    node[el.dataset.logicConn] = el.value;
  } else if (el.matches('[data-logic-cond]') && node) {
    pushLogicUndo();
    const i = num(el.dataset.condIndex, 0);
    if (!Array.isArray(node.conditions)) node.conditions = [];
    if (!node.conditions[i]) node.conditions[i] = { field: '', op: '==', value: '' };
    node.conditions[i][el.dataset.logicCond] = el.value;
  } else if (el.matches('[data-logic-ctx]')) {
    state.logicCtx[el.dataset.logicCtx] = el.value;
    return;
  } else {
    return;
  }
  touch();
  state.logicSim = null;
  if (el.matches('select') || el.matches('[data-logic-entry]')) render();
}


function logicAddNode(type) {
  const chain = selChain();
  if (!chain) return;
  pushLogicUndo();
  const nodes = asArray(chain.nodes);
  let n = nodes.length + 1;
  while (nodes.some((x) => x.id === `${type}-${n}`)) n += 1;
  const id = `${type}-${n}`;
  const base = { id, type, x: 160 + (nodes.length % 4) * 210, y: 120 + (nodes.length % 3) * 120 };
  if (type === 'condition') Object.assign(base, { field: 'gpa', op: '>=', value: '3.5', true: '', false: '' });
  if (type === 'all' || type === 'any' || type === 'not') Object.assign(base, { conditions: [{ field: 'gpa', op: '>=', value: '3.5' }], true: '', false: '' });
  if (type === 'set') Object.assign(base, { field: 'flag', value: 'true', next: '' });
  if (type === 'result') Object.assign(base, { result: 'approve', label: '结果' });
  chain.nodes.push(base);
  state.selectedLogicNode = id;
  state.logicSelection = [id];
  touch();
  render();
}


function logicAddChain() {
  pushLogicUndo();
  let n = chains().length + 1;
  while (chains().some((c) => c.id === `chain-${n}`)) n += 1;
  const chain = {
    id: `chain-${n}`,
    name: `新条件链 ${n}`,
    description: '',
    entry: 'start',
    nodes: [{ id: 'start', type: 'start', x: 60, y: 180, next: '' }],
  };
  state.content.logicDoc.chains.push(chain);
  state.selectedChain = chains().length - 1;
  state.selectedLogicNode = 'start';
  state.logicSelection = ['start'];
  touch();
  render();
}


function logicDeleteChain() {
  if (chains().length <= 1) { toast('至少保留一条条件链', 'warn'); return; }
  if (!confirm(`删除条件链「${selChain()?.name || ''}」？`)) return;
  pushLogicUndo();
  state.content.logicDoc.chains.splice(state.selectedChain, 1);
  state.selectedChain = Math.max(0, state.selectedChain - 1);
  state.selectedLogicNode = asArray(selChain()?.nodes)[0]?.id || '';
  touch();
  render();
}


function logicDeleteNode() {
  const chain = selChain();
  const node = selLogicNode();
  if (!chain || !node) return;
  if (node.type === 'start') { toast('START 节点不能删除', 'warn'); return; }
  if (!confirm(`删除节点「${node.id}」？引用它的连接会变成未连接。`)) return;
  pushLogicUndo();
  chain.nodes = asArray(chain.nodes).filter((n) => n.id !== node.id);
  asArray(chain.nodes).forEach((n) => {
    ['next', 'true', 'false'].forEach((k) => { if (n[k] === node.id) n[k] = ''; });
  });
  if (chain.entry === node.id) chain.entry = asArray(chain.nodes).find((n) => n.type === 'start')?.id || '';
  state.selectedLogicNode = asArray(chain.nodes)[0]?.id || '';
  touch();
  render();
}


function logicRun() {
  const chain = selChain();
  if (!chain) return;
  const ctx = { ...LOGIC_SAMPLE };
  logicChainFields(chain).forEach((field) => {
    const el = $(`[data-logic-ctx="${CSS.escape(field)}"]`);
    if (el) ctx[field] = el.value;
  });
  state.logicCtx = ctx;
  const sim = runLogicChain(chain, ctx);
  sim.chainId = chain.id;
  state.logicSim = sim;
  render();
  if (sim.ok) toast(`判断结果：${sim.result}`, sim.result === 'approve' ? 'good' : 'warn');
  else toast(sim.error, 'err');
}




function logicAddCondition() {
  const node = selLogicNode();
  if (!node || !['all', 'any', 'not'].includes(node.type)) return;
  if (!Array.isArray(node.conditions)) node.conditions = [];
  pushLogicUndo();
  node.conditions.push({ field: '', op: '==', value: '' });
  touch();
  state.logicSim = null;
  render();
}


function logicDeleteCondition(index) {
  const node = selLogicNode();
  if (!node || !['all', 'any', 'not'].includes(node.type)) return;
  pushLogicUndo();
  node.conditions = asArray(node.conditions).filter((_, i) => i !== index);
  touch();
  state.logicSim = null;
  render();
}


function logicClearSim() {
  state.logicSim = null;
  render();
}


function logicCenter() {
  const wrap = $('#logic-canvas-wrap');
  if (wrap) { wrap.scrollLeft = 0; wrap.scrollTop = 0; }
}


Object.assign(env.api, { logicOptionList, logicConnSelect, logicConditionRow, logicInspector, logicPreview, logicEmptyView, logicSnapshot, pushLogicUndo, restoreLogicSnapshot, logicUndoStep, logicRedoStep, logicSelectOnly, logicSelectedNodes, logicCopySelection, logicPasteSelection, logicDeleteSelection, logicAutoLayout, logicZoomBy, applyLogicZoom, logicFitView, logicJumpToNode, logicRunNodeSearch, logicRunChainSearch, logicIssueNodeIds, logicNodeHTML, viewLogic, drawLogicLinks, bindLogicCanvas, applyLogicChange, logicAddNode, logicAddChain, logicDeleteChain, logicDeleteNode, logicRun, logicAddCondition, logicDeleteCondition, logicClearSim, logicCenter });
};
