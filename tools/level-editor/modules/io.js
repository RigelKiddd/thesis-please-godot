/* io: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['io'] = function (env) {
'use strict';
const { $, $$, clone, esc, asArray, num, FILES, LOGIC_FILE, state } = env.model;
const asObj = (...args) => env.api.asObj(...args);
const cases = (...args) => env.api.cases(...args);
const chains = (...args) => env.api.chains(...args);
const characters = (...args) => env.api.characters(...args);
const closeModal = (...args) => env.api.closeModal(...args);
const compileProject = (...args) => env.api.compileProject(...args);
const content = (...args) => env.api.content(...args);
const levels = (...args) => env.api.levels(...args);
const logicDoc = (...args) => env.api.logicDoc(...args);
const logicIssueNodeIds = (...args) => env.api.logicIssueNodeIds(...args);
const openModal = (...args) => env.api.openModal(...args);
const refreshHealth = (...args) => env.api.refreshHealth(...args);
const render = (...args) => env.api.render(...args);
const selChain = (...args) => env.api.selChain(...args);
const showExportModal = (...args) => env.api.showExportModal(...args);
const tasks = (...args) => env.api.tasks(...args);
const toast = (...args) => env.api.toast(...args);
const updateChrome = (...args) => env.api.updateChrome(...args);
const validateProject = (...args) => env.api.validateProject(...args);

function markSaved() {
  state.dirty = false;
  updateChrome();
}


function captureBaseline() {
  state.baselinePayload = serializeContent();
}


function scheduleAutosave() {
  clearTimeout(scheduleAutosave._timer);
  scheduleAutosave._timer = setTimeout(() => {
    if (!state.loaded || !state.dirty) return;
    try {
      localStorage.setItem('thesis-editor-autosave', JSON.stringify({
        at: Date.now(),
        source: state.source,
        content: clone(state.content),
      }));
    } catch (_) { /* private mode / quota: autosave is best-effort */ }
  }, 1400);
}


function hasAutosave() {
  try { return !!localStorage.getItem('thesis-editor-autosave'); } catch (_) { return false; }
}


function restoreAutosave() {
  try {
    const raw = localStorage.getItem('thesis-editor-autosave');
    if (!raw) { toast('没有自动保存记录', 'warn'); return; }
    const snap = JSON.parse(raw);
    if (!snap?.content) return;
    if (!confirm(`恢复 ${new Date(snap.at).toLocaleString()} 的自动保存？当前未保存修改会被覆盖。`)) return;
    applyContent({
      'world.json': snap.content.world,
      'characters.json': snap.content.charactersDoc,
      'cases.json': snap.content.casesDoc,
      'levels.json': snap.content.levelsDoc,
      'tasks.json': snap.content.tasksDoc,
      [LOGIC_FILE]: snap.content.logicDoc,
    });
    state.source = '自动保存 · ' + new Date(snap.at).toLocaleTimeString();
    state.dirty = true;
    closeModal();
    state.validation = validateProject();
    render();
    toast('已恢复自动保存，记得保存全部', 'good');
  } catch (error) {
    toast('自动保存损坏：' + error.message, 'err');
  }
}


function scheduleValidate() {
  clearTimeout(scheduleValidate._timer);
  scheduleValidate._timer = setTimeout(() => {
    state.validation = validateProject();
    refreshHealth();
    if (state.view === 'logic') refreshLogicErrorMarks();
  }, 260);
}


function refreshLogicErrorMarks() {
  if (state.view !== 'logic') return;
  const ids = logicIssueNodeIds();
  $$('.logic-node').forEach((el) => {
    const bad = ids.has(el.dataset.logicNode);
    el.classList.toggle('has-error', bad);
    let badge = el.querySelector('.logic-error-badge');
    if (bad && !badge) {
      badge = document.createElement('span');
      badge.className = 'logic-error-badge';
      badge.title = '校验问题';
      badge.textContent = '!';
      el.querySelector('.logic-node-head')?.appendChild(badge);
    } else if (!bad && badge) {
      badge.remove();
    }
  });
  $$('.mm-node').forEach((el) => {
    const node = asArray(selChain()?.nodes)[Number(el.dataset.mmIndex)];
    el.classList.toggle('bad', !!(node && ids.has(node.id)));
  });
}


async function tryLoadFetch(notify = true) {
  try {
    const results = await Promise.all(FILES.map(async (name) => {
      const response = await fetch(`../../content/${name}?t=${Date.now()}`, { cache: 'no-store' });
      if (!response.ok) throw new Error(`${name}: HTTP ${response.status}`);
      return [name, await response.json()];
    }));
    const map = Object.fromEntries(results);
    try {
      const lr = await fetch(`../../content/${LOGIC_FILE}?t=${Date.now()}`, { cache: 'no-store' });
      if (lr.ok) map[LOGIC_FILE] = await lr.json();
    } catch (_) { /* logic is optional */ }
    applyContent(map);
    state.source = 'content/ · 自动载入';
    state.dirHandle = null;
    state.contentPrefix = '';
    markSaved();
    captureBaseline();
    state.validation = validateProject();
    render();
    if (notify) toast('已从 content/ 重新读取');
    return true;
  } catch (error) {
    if (notify) toast(`读取 content/ 失败：${error.message}`, 'warn');
    if (!state.loaded) toast('请选择项目文件夹，或通过本地服务器打开编辑器', 'warn');
    return false;
  }
}


function applyContent(map) {
  const world = map['world.json'];
  const charactersDoc = map['characters.json'];
  const casesDoc = map['cases.json'];
  const levelsDoc = map['levels.json'];
  const tasksDoc = map['tasks.json'];
  if (!world || !charactersDoc || !casesDoc || !levelsDoc || !tasksDoc) {
    throw new Error('缺少 world/characters/cases/levels/tasks 中的文件');
  }
  const shape = env.api.shapeErrors({world, characters:charactersDoc.characters,
    cases:casesDoc.cases, tasks:tasksDoc.tasks, levels_doc:levelsDoc});
  if (shape.length) throw new Error('内容结构错误：' + shape.join(', '));
  if (map[LOGIC_FILE] !== undefined && (!map[LOGIC_FILE] || !Array.isArray(map[LOGIC_FILE].chains) ||
      map[LOGIC_FILE].chains.some(c => !c || !Array.isArray(c.nodes) || c.nodes.some(n => !n || typeof n !== 'object' || Array.isArray(n))))) {
    throw new Error('logic.json 的 chains / nodes 必须是对象数组');
  }
  state.content = {
    world,
    charactersDoc: { schema: charactersDoc.schema || 1, characters: asArray(charactersDoc.characters) },
    casesDoc: { schema: casesDoc.schema || 1, cases: asArray(casesDoc.cases) },
    levelsDoc: {
      schema: levelsDoc.schema || 1,
      chapter: levelsDoc.chapter || { id: 'chapter-1', title: '第一周', startDate: '' },
      levels: asArray(levelsDoc.levels),
    },
    tasksDoc: { schema: tasksDoc.schema || 1, tasks: asArray(tasksDoc.tasks) },
    logicDoc: normalizeLogicDoc(map[LOGIC_FILE]),
  };
  state.loaded = true;
  state.dirty = false;
  state.selectedLevel = Math.min(state.selectedLevel, Math.max(0, levels().length - 1));
  state.selectedCharacter = Math.min(state.selectedCharacter, Math.max(0, characters().length - 1));
  state.selectedTask = Math.min(state.selectedTask, Math.max(0, tasks().length - 1));
  state.selectedDoc = 0;
  state.selectedChain = Math.min(state.selectedChain, Math.max(0, chains().length - 1));
  state.selectedLogicNode = asArray(selChain()?.nodes)[0]?.id || '';
  state.logicSelection = state.selectedLogicNode ? [state.selectedLogicNode] : [];
  state.logicUndo = [];
  state.logicRedo = [];
  state.logicClipboard = null;
  state.logicCtx = {};
  state.logicSim = null;
}


function normalizeLogicDoc(doc) {
  const src = doc && typeof doc === 'object' ? doc : {};
  return {
    schema: num(src.schema, 1),
    meta: asObj(src.meta),
    chains: asArray(src.chains).map((chain) => ({
      ...chain,
      nodes: asArray(chain.nodes).map((node) => ({ ...node })),
    })),
  };
}


async function loadFromFileList(files) {
  try {
    const map = {};
    for (const file of files) {
      const base = file.name;
      if (FILES.includes(base) || base === LOGIC_FILE) map[base] = JSON.parse(await file.text());
    }
    applyContent(map);
    state.source = `文件 · ${files.length} 个`;
    state.dirHandle = null;
    state.contentPrefix = '';
    closeModal();
    markSaved();
    captureBaseline();
    state.validation = validateProject();
    render();
    toast('项目已载入。未选择文件夹时，保存会下载 JSON。');
  } catch (error) {
    toast(`载入失败：${error.message}`, 'err');
  }
}


async function openProjectFolder() {
  if (!window.showDirectoryPicker) {
    $('#dir-input').click();
    return;
  }
  try {
    const handle = await window.showDirectoryPicker({ mode: 'readwrite' });
    await loadFromDirectoryHandle(handle);
  } catch (error) {
    if (error && error.name !== 'AbortError') {
      toast(`无法打开文件夹：${error.message}。可直接选择 content 文件。`, 'err');
    }
  }
}


async function loadFromDirectoryHandle(rootHandle) {
  let contentDir = rootHandle;
  let prefix = '';
  let names = [];
  for await (const [name, handle] of rootHandle.entries()) {
    if (handle.kind === 'file') names.push(name);
  }
  if (!names.includes('characters.json')) {
    contentDir = await rootHandle.getDirectoryHandle('content');
    prefix = 'content';
    names = [];
    for await (const [name, handle] of contentDir.entries()) {
      if (handle.kind === 'file') names.push(name);
    }
  }
  const map = {};
  for (const name of FILES) {
    const fileHandle = await contentDir.getFileHandle(name);
    const file = await fileHandle.getFile();
    map[name] = JSON.parse(await file.text());
  }
  try {
    const logicHandle = await contentDir.getFileHandle(LOGIC_FILE);
    const logicFile = await logicHandle.getFile();
    map[LOGIC_FILE] = JSON.parse(await logicFile.text());
  } catch (_) { /* optional */ }
  applyContent(map);
  state.dirHandle = rootHandle;
  state.contentPrefix = prefix;
  state.source = `文件夹 · ${rootHandle.name}${prefix ? '/content' : ''}`;
  closeModal();
  markSaved();
  captureBaseline();
  state.validation = validateProject();
  render();
  toast(`项目已载入：${state.source}`, 'good');
}


function contentDirHandle() {
  if (!state.dirHandle) return Promise.resolve(null);
  if (!state.contentPrefix) return Promise.resolve(state.dirHandle);
  return state.dirHandle.getDirectoryHandle(state.contentPrefix, { create: true });
}


function payloadDiff(payloads) {
  return Object.keys(payloads).filter((name) => payloads[name] !== (state.baselinePayload?.[name] ?? ''));
}


function lineDiffSummary(before, after) {
  const a = String(before || '').split('\n');
  const b = String(after || '').split('\n');
  const oldSet = new Set(a);
  const newSet = new Set(b);
  const removed = a.filter((line) => !newSet.has(line)).length;
  const added = b.filter((line) => !oldSet.has(line)).length;
  return { added, removed };
}


function showSaveDiff(payloads, changed) {
  state.pendingSave = payloads;
  const rows = changed.map((name) => {
    const stats = lineDiffSummary(state.baselinePayload?.[name], payloads[name]);
    return `<div class="save-diff-row"><b>${esc(name)}</b><span class="diff-add">+${stats.added}</span><span class="diff-del">−${stats.removed}</span><span class="path">${payloads[name].length} bytes</span></div>`;
  }).join('');
  openModal(`<h3>保存前确认</h3>
    <div class="modal-sub">检测到 ${changed.length} 个文件有变化。确认后会写入目录，或下载这些 JSON。</div>
    <div class="save-diff">${rows}</div>
    <div class="form-note">没有变化的文件不会重复写出。自动保存仍保留在本机浏览器里。</div>
    <div class="modal-actions"><button class="btn ghost" data-action="cancel-save">取消</button><button class="btn primary" data-action="confirm-save">确认保存 ${changed.length} 个文件</button></div>`);
}


async function saveAll() {
  if (!state.loaded) {
    toast('还没有载入项目', 'warn');
    return;
  }
  const payloads = serializeContent();
  state.validation = validateProject();
  if (state.validation.errors.length) {
    state.view = 'publish';
    render();
    toast('校验未通过，请修复后保存。草稿仍保留在浏览器中。', 'err');
    return;
  }
  const changed = payloadDiff(payloads);
  if (!changed.length) {
    toast('没有需要保存的变化', 'good');
    return;
  }
  showSaveDiff(payloads, changed);
}


async function commitSave(payloads) {
  try {
    if (state.dirHandle) {
      const dir = await contentDirHandle();
      for (const [name, text] of Object.entries(payloads)) {
        await writeTextFile(dir, name, text);
      }
      toast(`已写入 ${Object.keys(payloads).length} 个 content 文件`, 'good');
    } else {
      for (const [name, text] of Object.entries(payloads)) downloadText(name, text);
      toast(`已下载 ${Object.keys(payloads).length} 个 content 文件`, 'good');
    }
    state.pendingSave = null;
    closeModal();
    markSaved();
    captureBaseline();
    render();
  } catch (error) {
    toast(`保存失败：${error.message}`, 'err');
  }
}


function serializeContent() {
  return {
    'world.json': JSON.stringify(state.content.world, null, 2) + '\n',
    'characters.json': JSON.stringify(state.content.charactersDoc, null, 2) + '\n',
    'cases.json': JSON.stringify(state.content.casesDoc, null, 2) + '\n',
    'levels.json': JSON.stringify(state.content.levelsDoc, null, 2) + '\n',
    'tasks.json': JSON.stringify(state.content.tasksDoc, null, 2) + '\n',
    [LOGIC_FILE]: JSON.stringify(state.content.logicDoc || normalizeLogicDoc(null), null, 2) + '\n',
  };
}


async function writeTextFile(dirHandle, name, text) {
  const fileHandle = await dirHandle.getFileHandle(name, { create: true });
  const writable = await fileHandle.createWritable();
  await writable.write(text);
  await writable.close();
}


function downloadText(name, text) {
  const blob = new Blob([text], { type: 'application/json;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1200);
}


async function exportGame() {
  if (!state.loaded) return;
  const compiled = compileProject();
  if (compiled.errors.length) {
    state.validation = { errors: compiled.errors, warnings: [] };
    state.view = 'publish';
    render();
    toast('校验未通过，先修正错误再导出', 'err');
    return;
  }
  const dataText = JSON.stringify(compiled.data, null, 2) + '\n';
  const requestsText = JSON.stringify(compiled.requests, null, 2) + '\n';
  try {
    if (state.dirHandle && state.contentPrefix === 'content') {
      const assets = await state.dirHandle.getDirectoryHandle('assets', { create: true });
      await writeTextFile(assets, 'data.json', dataText);
      await writeTextFile(assets, 'requests.json', requestsText);
      toast('已写入 assets/data.json 与 assets/requests.json', 'good');
    } else {
      downloadText('data.json', dataText);
      downloadText('requests.json', requestsText);
      toast('已下载 data.json 与 requests.json', 'good');
    }
    showExportModal(compiled);
  } catch (error) {
    toast(`导出失败：${error.message}`, 'err');
  }
}


Object.assign(env.api, { markSaved, captureBaseline, scheduleAutosave, hasAutosave, restoreAutosave, scheduleValidate, refreshLogicErrorMarks, tryLoadFetch, applyContent, normalizeLogicDoc, loadFromFileList, openProjectFolder, loadFromDirectoryHandle, contentDirHandle, payloadDiff, lineDiffSummary, showSaveDiff, saveAll, commitSave, serializeContent, writeTextFile, downloadText, exportGame });
};
