/* controller: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['controller'] = function (env) {
'use strict';
const { $, clone, esc, asArray, asText, num, CONTENT_VERSION, STYLE_DEFS, state } = env.model;
const addDialogueNode = (...args) => env.api.addDialogueNode(...args);
const applyDialogueChoiceField = (...args) => env.api.applyDialogueChoiceField(...args);
const applyDialogueField = (...args) => env.api.applyDialogueField(...args);
const applyLogicChange = (...args) => env.api.applyLogicChange(...args);
const caseForCharacter = (...args) => env.api.caseForCharacter(...args);
const cases = (...args) => env.api.cases(...args);
const chains = (...args) => env.api.chains(...args);
const characterForSlot = (...args) => env.api.characterForSlot(...args);
const characterUsage = (...args) => env.api.characterUsage(...args);
const characters = (...args) => env.api.characters(...args);
const closeModal = (...args) => env.api.closeModal(...args);
const commitSave = (...args) => env.api.commitSave(...args);
const content = (...args) => env.api.content(...args);
const deleteDialogueNode = (...args) => env.api.deleteDialogueNode(...args);
const dialogueFromAuto = (...args) => env.api.dialogueFromAuto(...args);
const dialogueNodeById = (...args) => env.api.dialogueNodeById(...args);
const exportGame = (...args) => env.api.exportGame(...args);
const findCase = (...args) => env.api.findCase(...args);
const findChar = (...args) => env.api.findChar(...args);
const levels = (...args) => env.api.levels(...args);
const loadFromFileList = (...args) => env.api.loadFromFileList(...args);
const logicAddChain = (...args) => env.api.logicAddChain(...args);
const logicAddCondition = (...args) => env.api.logicAddCondition(...args);
const logicAddNode = (...args) => env.api.logicAddNode(...args);
const logicAutoLayout = (...args) => env.api.logicAutoLayout(...args);
const logicCenter = (...args) => env.api.logicCenter(...args);
const logicClearSim = (...args) => env.api.logicClearSim(...args);
const logicCopySelection = (...args) => env.api.logicCopySelection(...args);
const logicDeleteChain = (...args) => env.api.logicDeleteChain(...args);
const logicDeleteCondition = (...args) => env.api.logicDeleteCondition(...args);
const logicDeleteNode = (...args) => env.api.logicDeleteNode(...args);
const logicDeleteSelection = (...args) => env.api.logicDeleteSelection(...args);
const logicFitView = (...args) => env.api.logicFitView(...args);
const logicJumpToNode = (...args) => env.api.logicJumpToNode(...args);
const logicNodeById = (...args) => env.api.logicNodeById(...args);
const logicPasteSelection = (...args) => env.api.logicPasteSelection(...args);
const logicRedoStep = (...args) => env.api.logicRedoStep(...args);
const logicRun = (...args) => env.api.logicRun(...args);
const logicRunChainSearch = (...args) => env.api.logicRunChainSearch(...args);
const logicRunNodeSearch = (...args) => env.api.logicRunNodeSearch(...args);
const logicSelectOnly = (...args) => env.api.logicSelectOnly(...args);
const logicUndoStep = (...args) => env.api.logicUndoStep(...args);
const logicZoomBy = (...args) => env.api.logicZoomBy(...args);
const newDialogue = (...args) => env.api.newDialogue(...args);
const nextId = (...args) => env.api.nextId(...args);
const openModal = (...args) => env.api.openModal(...args);
const openProjectFolder = (...args) => env.api.openProjectFolder(...args);
const portraitPath = (...args) => env.api.portraitPath(...args);
const pushLogicUndo = (...args) => env.api.pushLogicUndo(...args);
const refreshPreview = (...args) => env.api.refreshPreview(...args);
const render = (...args) => env.api.render(...args);
const restoreAutosave = (...args) => env.api.restoreAutosave(...args);
const saveAll = (...args) => env.api.saveAll(...args);
const selChain = (...args) => env.api.selChain(...args);
const selCharacter = (...args) => env.api.selCharacter(...args);
const selLevel = (...args) => env.api.selLevel(...args);
const selTask = (...args) => env.api.selTask(...args);
const selectedCase = (...args) => env.api.selectedCase(...args);
const showHelp = (...args) => env.api.showHelp(...args);
const showWelcome = (...args) => env.api.showWelcome(...args);
const taskUsage = (...args) => env.api.taskUsage(...args);
const tasks = (...args) => env.api.tasks(...args);
const toast = (...args) => env.api.toast(...args);
const touch = (...args) => env.api.touch(...args);
const tryLoadFetch = (...args) => env.api.tryLoadFetch(...args);
const uidSuffix = (...args) => env.api.uidSuffix(...args);
const updateChrome = (...args) => env.api.updateChrome(...args);
const validateProject = (...args) => env.api.validateProject(...args);

async function boot() {
  $('#version-pill').textContent = CONTENT_VERSION;
  await tryLoadFetch(false);
  if (!state.loaded) {
    showWelcome();
    render();
  }
}


function bindGlobalEvents() {
  document.addEventListener('click', (event) => {
    const nav = event.target.closest('[data-nav]');
    if (nav) {
      state.view = nav.dataset.nav;
      render();
      return;
    }
    const logicPort = event.target.closest('[data-logic-port]');
    if (logicPort) {
      state.logicLinkSource = {
        id: logicPort.dataset.logicSource,
        port: logicPort.dataset.logicPort,
      };
      state.selectedLogicNode = logicPort.dataset.logicSource;
      state.view = 'logic';
      render();
      toast('已选中输出口，再点一个目标节点完成连接', 'good');
      return;
    }
    const logicNode = event.target.closest('[data-logic-node]');
    if (logicNode && !event.target.closest('[data-action]')) {
      if (state.logicLinkSource) {
        const source = logicNodeById(selChain(), state.logicLinkSource.id);
        const target = logicNode.dataset.logicNode;
        if (source && target !== source.id) {
          pushLogicUndo();
          source[state.logicLinkSource.port] = target;
          state.logicLinkSource = null;
          state.selectedLogicNode = source.id;
          state.logicSelection = [source.id];
          touch();
          render();
          toast(`已连接 ${source.id} → ${target}`, 'good');
          return;
        }
        state.logicLinkSource = null;
      }
      logicSelectOnly(logicNode.dataset.logicNode, event.shiftKey || event.ctrlKey || event.metaKey);
      state.view = 'logic';
      render();
      return;
    }
    const actionEl = event.target.closest('[data-action]');
    if (actionEl && !actionEl.disabled) {
      event.preventDefault();
      handleAction(actionEl.dataset.action, actionEl);
      return;
    }
  });

  document.addEventListener('input', (event) => {
    const el = event.target;
    if (el.id === 'char-search') {
      state.charFilter = el.value;
      render();
      const again = $('#char-search');
      if (again) {
        again.focus();
        again.setSelectionRange(again.value.length, again.value.length);
      }
      return;
    }
    if (el.matches('[data-doclist]')) {
      applyDocList(el);
      return;
    }
    if (el.matches('[data-scope]')) {
      applyScopeInput(el);
    }
    if (el.matches('[data-dialogue-field]') && el.dataset.dialogueField !== 'id') {
      applyDialogueField(el);
    }
    if (el.matches('[data-dialogue-choice-field]')) {
      applyDialogueChoiceField(el);
    }
    if (el.matches('[data-logic-ctx]')) {
      state.logicCtx[el.dataset.logicCtx] = el.value;
    }
    if (el.id === 'logic-node-search') state.logicNodeQuery = el.value;
    if (el.id === 'logic-chain-search') state.logicChainQuery = el.value;
  });

  document.addEventListener('change', (event) => {
    const el = event.target;
    if (el.id === 'logic-chain-select') {
      state.selectedChain = num(el.value, 0);
      state.selectedLogicNode = asArray(selChain()?.nodes)[0]?.id || '';
      state.logicSim = null;
      render();
      return;
    }
    if (el.matches('[data-logic-chain-field], [data-logic-entry], [data-logic-node-field], [data-logic-conn], [data-logic-cond]')) {
      applyLogicChange(el);
      return;
    }
    if (el.matches('[data-dialogue-field], [data-dialogue-choice-field]')) {
      if (el.matches('[data-dialogue-field]')) applyDialogueField(el);
      else applyDialogueChoiceField(el);
      return;
    }
    if (el.matches('[data-dialogue-start]')) {
      const cs = selectedCase();
      if (cs?.dialogue) { cs.dialogue.start = el.value; touch(); render(); }
      return;
    }
    if (el.matches('[data-slot-character]')) {
      changeSlotCharacter(num(el.dataset.slot, 0), el.value);
      return;
    }
    if (el.matches('[data-slot-case]')) {
      const slot = selLevel().queue[num(el.dataset.slot, 0)];
      if (slot) slot.caseId = el.value;
      touch();
      return;
    }
    if (el.matches('[data-slot-task]')) {
      const slot = selLevel().queue[num(el.dataset.slot, 0)];
      if (slot) slot.taskId = el.value || null;
      touch();
      return;
    }
    if (el.matches('[data-scope]')) {
      applyScopeInput(el);
    }
  });

  window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      if (state.logicLinkSource) {
        state.logicLinkSource = null;
        render();
        return;
      }
      if ($('#modal-root').classList.contains('open')) closeModal();
      return;
    }
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
      event.preventDefault();
      saveAll();
      return;
    }
    if (state.view === 'logic' && !['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement?.tagName)) {
      const key = event.key.toLowerCase();
      if ((event.ctrlKey || event.metaKey) && (key === 'y' || (key === 'z' && event.shiftKey))) { event.preventDefault(); logicRedoStep(); return; }
      if ((event.ctrlKey || event.metaKey) && key === 'z') { event.preventDefault(); logicUndoStep(); return; }
      if ((event.ctrlKey || event.metaKey) && key === 'c') { event.preventDefault(); logicCopySelection(); return; }
      if ((event.ctrlKey || event.metaKey) && key === 'v') { event.preventDefault(); logicPasteSelection(); return; }
      if (event.key === 'Delete' || event.key === 'Backspace') { event.preventDefault(); logicDeleteSelection(); }
    }
  });

  window.addEventListener('beforeunload', (event) => {
    if (state.dirty) {
      event.preventDefault();
      event.returnValue = '';
    }
  });

  $('#modal-root').addEventListener('click', (event) => {
    if (event.target.id === 'modal-root') closeModal();
  });

  $('#file-input').addEventListener('change', async (event) => {
    const files = Array.from(event.target.files || []);
    if (files.length) await loadFromFileList(files);
    event.target.value = '';
  });

  $('#dir-input').addEventListener('change', async (event) => {
    const files = Array.from(event.target.files || []);
    if (files.length) await loadFromFileList(files);
    event.target.value = '';
  });
}


function scopeObject(scope) {
  switch (scope) {
    case 'level': return selLevel();
    case 'char': return selCharacter();
    case 'case': return selectedCase();
    case 'task': return selTask();
    case 'doc': return selTask()?.documents?.[state.selectedDoc] || null;
    case 'chapter': return state.content?.levelsDoc?.chapter || null;
    default: return null;
  }
}


function setDeep(obj, path, value) {
  if (!obj) return;
  const parts = String(path).split('.');
  let cursor = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    const key = parts[i];
    if (!cursor[key] || typeof cursor[key] !== 'object') cursor[key] = {};
    cursor = cursor[key];
  }
  cursor[parts[parts.length - 1]] = value;
}


function deleteDeep(obj, path) {
  if (!obj) return;
  const parts = String(path).split('.');
  let cursor = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    cursor = cursor?.[parts[i]];
    if (!cursor) return;
  }
  if (cursor) delete cursor[parts[parts.length - 1]];
}


function applyScopeInput(el) {
  const scope = el.dataset.scope;
  const key = el.dataset.key;
  const obj = scopeObject(scope);
  if (!obj || !key) return;
  let value;
  if (el.type === 'checkbox') value = el.checked;
  else if (el.type === 'number') value = num(el.value, 0);
  else if (el.dataset.list === 'lines') value = el.value.split('\n').map((s) => s.trim()).filter(Boolean);
  else value = el.value;
  setDeep(obj, key, value);
  if (scope === 'doc' && ['style', 'kind'].includes(key)) render();
  if (scope === 'doc') refreshPreview();
  if (scope === 'chapter') updateChrome();
  touch();
}


function applyDocList(el) {
  const doc = scopeObject('doc');
  if (!doc) return;
  const mode = el.dataset.doclist;
  if (mode === 'table') {
    const lines = el.value.split('\n').map((l) => l.trim()).filter(Boolean);
    if (!lines.length) doc.table = null;
    else {
      const columns = lines[0].split('|').map((s) => s.trim());
      const rows = lines.slice(1).map((line) => line.split('|').map((s) => s.trim()));
      doc.table = { columns, rows };
    }
  } else {
    const pairs = el.value.split('\n').filter((l) => l.trim()).map((line) => {
      const parts = line.split('|');
      return [parts[0].trim(), parts.slice(1).join('|').trim()];
    });
    doc[mode] = pairs;
  }
  refreshPreview();
  touch();
}


function applyOverride(el) {
  const cs = selectedCase();
  if (!cs) return;
  const path = el.dataset.override;
  const value = el.value.trim();
  if (!cs.cover) cs.cover = {};
  if (!cs.cover.overrides) cs.cover.overrides = {};
  if (!cs.dup) cs.dup = {};
  if (!cs.dup.overrides) cs.dup.overrides = {};
  if (!value) deleteDeep(cs, path.includes('dup') ? `dup.overrides.${path.split('.')[1]}` : `cover.overrides.${path.split('.')[1]}`);
  else setDeep(cs, path.includes('dup') ? `dup.overrides.${path.split('.')[1]}` : `cover.overrides.${path.split('.')[1]}`, value);
  touch();
}


function pairsText(rows) {
  return asArray(rows).filter(Array.isArray).map((row) => `${asText(row[0])} | ${asText(row[1])}`).join('\n');
}

function tableText(table) {
  if (!table || !asArray(table.columns).length) return '';
  return [asArray(table.columns).join(' | ')].concat(asArray(table.rows).map((r) => asArray(r).join(' | '))).join('\n');
}


async function handleAction(action, el) {
  switch (action) {
    case 'open-folder': await openProjectFolder(); break;
    case 'open-files': $('#file-input').click(); break;
    case 'load-fetch': await tryLoadFetch(true); break;
    case 'save-all': await saveAll(); break;
    case 'export-game': await exportGame(); break;
    case 'run-validation': state.validation = validateProject(); state.view = 'publish'; render(); toast('校验完成'); break;
    case 'show-help': showHelp(); break;
    case 'close-modal': closeModal(); break;
    case 'edit-chapter': editChapter(); break;
    case 'save-chapter': saveChapter(); break;
    case 'add-level': addLevel(); break;
    case 'duplicate-level': duplicateLevel(); break;
    case 'delete-level': deleteLevel(); break;
    case 'select-level': selectLevel(num(el.dataset.index, 0)); break;
    case 'add-slot': openCharacterPicker(); break;
    case 'pick-character': pickCharacter(el.dataset.char || ''); break;
    case 'move-slot-up': moveSlot(num(el.dataset.index, 0), -1); break;
    case 'move-slot-down': moveSlot(num(el.dataset.index, 0), 1); break;
    case 'duplicate-slot': duplicateSlot(num(el.dataset.index, 0)); break;
    case 'delete-slot': deleteSlot(num(el.dataset.index, 0)); break;
    case 'add-character': addCharacter(); break;
    case 'duplicate-character': duplicateCharacter(); break;
    case 'delete-character': deleteCharacter(); break;
    case 'select-character': state.selectedCharacter = num(el.dataset.index, 0); state.selectedDoc = 0; state.view = 'characters'; render(); break;
    case 'create-case': createCaseForCharacter(); break;
    case 'edit-case-json': editCaseJson(); break;
    case 'save-case-json': saveCaseJson(); break;
    case 'dialogue-create': {
      const cs = selectedCase();
      if (cs) { cs.dialogue = newDialogue(); touch(); render(); }
      break;
    }
    case 'dialogue-from-auto': {
      const cs = selectedCase();
      if (cs) {
        if (cs.dialogue && !confirm('覆盖当前对话树？')) break;
        cs.dialogue = dialogueFromAuto(cs);
        touch();
        render();
      }
      break;
    }
    case 'dialogue-delete': {
      const cs = selectedCase();
      if (cs?.dialogue && confirm('清空自定义对话树？')) {
        delete cs.dialogue;
        touch();
        render();
      }
      break;
    }
    case 'dialogue-add-node': addDialogueNode(); break;
    case 'dialogue-del-node': deleteDialogueNode(el.dataset.node || ''); break;
    case 'dialogue-add-choice': {
      const cs = selectedCase();
      const node = dialogueNodeById(cs?.dialogue, el.dataset.node);
      if (node) {
        if (!Array.isArray(node.choices)) node.choices = [];
        if (node.choices.length >= 4) { toast('一个节点最多 4 个回复选项', 'warn'); break; }
        node.choices.push({ label: '新回复选项', next: '', style: '', timeSaved: 0 });
        touch();
        render();
      }
      break;
    }
    case 'dialogue-del-choice': {
      const cs = selectedCase();
      const node = dialogueNodeById(cs?.dialogue, el.dataset.node);
      if (node) {
        node.choices = asArray(node.choices).filter((_, i) => i !== num(el.dataset.choice, 0));
        touch();
        render();
      }
      break;
    }
    case 'add-task': addTask(); break;
    case 'duplicate-task': duplicateTask(); break;
    case 'delete-task': deleteTask(); break;
    case 'select-task': state.selectedTask = num(el.dataset.index, 0); state.selectedDoc = 0; state.view = 'tasks'; render(); break;
    case 'add-doc': addDoc(); break;
    case 'delete-doc': deleteDoc(); break;
    case 'move-doc-up': moveDoc(-1); break;
    case 'move-doc-down': moveDoc(1); break;
    case 'select-doc': state.selectedDoc = num(el.dataset.index, 0); render(); break;
    case 'pick-doc-style': {
      const doc = selTask()?.documents?.[state.selectedDoc];
      if (doc && STYLE_DEFS[el.dataset.style]) {
        doc.style = el.dataset.style;
        touch();
        render();
      }
      break;
    }
    case 'goto-issue': gotoIssue(el.dataset.path || ''); break;
    case 'goto-character': state.view = 'characters'; state.selectedCharacter = num(el.dataset.index, 0); render(); break;
    case 'goto-task': state.view = 'tasks'; state.selectedTask = num(el.dataset.index, 0); render(); break;
    case 'goto-level': state.view = 'levels'; state.selectedLevel = num(el.dataset.index, 0); render(); break;
    case 'logic-add-chain': logicAddChain(); break;
    case 'logic-del-chain': logicDeleteChain(); break;
    case 'logic-add-node': logicAddNode(el.dataset.type || 'condition'); break;
    case 'logic-del-node': logicDeleteNode(); break;
    case 'logic-undo': logicUndoStep(); break;
    case 'logic-redo': logicRedoStep(); break;
    case 'logic-copy': logicCopySelection(); break;
    case 'logic-paste': logicPasteSelection(); break;
    case 'logic-delete-selection': logicDeleteSelection(); break;
    case 'logic-autolayout': logicAutoLayout(); break;
    case 'logic-zoom-in': logicZoomBy(0.1); break;
    case 'logic-zoom-out': logicZoomBy(-0.1); break;
    case 'logic-fit': logicFitView(); break;
    case 'logic-jump': logicJumpToNode(el.dataset.node || ''); break;
    case 'logic-search-node': logicRunNodeSearch(); break;
    case 'logic-search-chain': logicRunChainSearch(); break;
    case 'logic-add-condition': logicAddCondition(); break;
    case 'logic-del-condition': logicDeleteCondition(num(el.dataset.condIndex, 0)); break;
    case 'logic-run': logicRun(); break;
    case 'logic-clear-sim': logicClearSim(); break;
    case 'logic-center': logicCenter(); break;
    case 'confirm-save': if (state.pendingSave) commitSave(state.pendingSave); break;
    case 'cancel-save': state.pendingSave = null; closeModal(); break;
    case 'restore-autosave': restoreAutosave(); break;
    default: break;
  }
}


function selectLevel(index) {
  state.selectedLevel = Math.max(0, Math.min(index, levels().length - 1));
  state.view = 'levels';
  render();
}


function addLevel() {
  const last = levels()[levels().length - 1] || {};
  const day = Math.max(0, ...levels().map((l) => num(l.day, 0))) + 1;
  const lv = {
    id: `level-${day}`,
    day,
    date: '',
    weekday: '',
    shortDate: '',
    theme: '新关卡',
    notice: '',
    queue: [],
  };
  levels().push(lv);
  state.selectedLevel = levels().length - 1;
  state.view = 'levels';
  touch();
  render();
  toast(`已新增第 ${day} 天`);
}


function duplicateLevel() {
  const lv = selLevel();
  if (!lv) return;
  const copy = clone(lv);
  const day = Math.max(0, ...levels().map((l) => num(l.day, 0))) + 1;
  copy.id = `level-${day}`;
  copy.day = day;
  copy.theme = `${lv.theme || '关卡'}（副本）`;
  asArray(copy.queue).forEach((slot) => { slot.taskId = null; });
  levels().splice(state.selectedLevel + 1, 0, copy);
  state.selectedLevel += 1;
  touch();
  render();
  toast('已复制关卡；为避免重复挂接，副本里的待办已清空');
}


function deleteLevel() {
  if (levels().length <= 1) { toast('至少保留一个关卡', 'warn'); return; }
  const lv = selLevel();
  if (!lv || !confirm(`删除「${lv.theme || lv.id}」？`)) return;
  levels().splice(state.selectedLevel, 1);
  state.selectedLevel = Math.max(0, state.selectedLevel - 1);
  touch();
  render();
}


function moveSlot(index, delta) {
  const queue = asArray(selLevel()?.queue);
  const to = index + delta;
  if (to < 0 || to >= queue.length) return;
  const [item] = queue.splice(index, 1);
  queue.splice(to, 0, item);
  touch();
  render();
}


function duplicateSlot(index) {
  const queue = asArray(selLevel()?.queue);
  const slot = queue[index];
  if (!slot) return;
  const copy = clone(slot);
  copy.taskId = null;
  queue.splice(index + 1, 0, copy);
  touch();
  render();
  toast('已复制队列位置；待办挂接已清空');
}


function deleteSlot(index) {
  const queue = asArray(selLevel()?.queue);
  const slot = queue[index];
  if (!slot) return;
  if (!confirm(`移除第 ${index + 1} 位（${characterForSlot(slot)?.name || '未知'}）？`)) return;
  queue.splice(index, 1);
  touch();
  render();
}


function changeSlotCharacter(index, charId) {
  const slot = selLevel()?.queue?.[index];
  if (!slot) return;
  slot.characterId = charId;
  const ch = findChar(charId);
  const matching = findCase(`case-${ch?.studentNo}`);
  if (matching) slot.caseId = matching.id;
  touch();
  render();
}


function openCharacterPicker() {
  const rows = characters().map((ch, index) => `
    <button class="picker-item" data-action="pick-character" data-char="${esc(ch.id)}">
      <img src="${portraitPath(ch)}" alt="" onerror="this.style.visibility='hidden'" />
      <span>${esc(ch.name)}<small>${esc(ch.studentNo)} · ${esc(ch.major)}</small></span>
    </button>`).join('');
  openModal(`<h3>把人物加入队列</h3><div class="modal-sub">选择一个人物；如果已有同学生号对应的案例，会自动绑定。</div>
    <div class="picker-list">${rows}</div>
    <div class="modal-actions"><button class="btn ghost" data-action="close-modal">取消</button></div>`);
}


function pickCharacter(charId) {
  const ch = findChar(charId);
  const lv = selLevel();
  if (!ch || !lv) return;
  if (asArray(lv.queue).some((s) => s.characterId === charId)) {
    toast(`${ch.name} 已经在这个队列里`, 'warn');
    return;
  }
  let cs = findCase(`case-${ch.studentNo}`);
  if (!cs) cs = cases().find((c) => !asArray(lv.queue).some((s) => s.caseId === c.id)) || cases()[0];
  lv.queue.push({ characterId: ch.id, caseId: cs?.id || '', taskId: null });
  closeModal();
  touch();
  render();
}


function addCharacter() {
  const suffix = uidSuffix();
  const ch = {
    id: `char-${suffix}`,
    studentNo: `2026${suffix.slice(-6)}`,
    name: '新同学',
    major: '',
    college: '',
    clazz: '',
    grade: '2022级',
    advisor: '',
    portrait: 'd1s1',
    look: {},
  };
  characters().push(ch);
  const cs = {
    id: `case-${ch.studentNo}`,
    title: '未命名论文题目',
    abstractTitle: '未命名论文题目',
    abstractChars: 360,
    excerpt: '',
    keywords: [],
    refs: [],
    body: { pages: 20, wordCount: 8000, gap: null, heading: '', excerpt: '' },
    form: { signatures: { advisor: '', chair: '', dean: '' }, human: false, ethicsNo: null, credits: 160, tuition: 'paid', tuitionOwed: 0 },
    line: '',
    cover: { overrides: {} },
    dup: { rate: 10.0, reportNo: '', seal: true, date: '', system: '', overrides: {} },
  };
  cases().push(cs);
  state.selectedCharacter = characters().length - 1;
  state.view = 'characters';
  touch();
  render();
  toast('已新增人物与空白案例；名字、学号记得改');
}


function duplicateCharacter() {
  const ch = selCharacter();
  if (!ch) return;
  const suffix = uidSuffix();
  const copy = clone(ch);
  copy.id = `char-${suffix}`;
  copy.studentNo = `2026${suffix.slice(-6)}`;
  copy.name = `${ch.name}（副本）`;
  characters().push(copy);
  const cs = caseForCharacter(ch);
  if (cs) {
    const cc = clone(cs);
    cc.id = `case-${copy.studentNo}`;
    cc.title = `${cs.title}（副本）`;
    cc.abstractTitle = cc.title;
    cases().push(cc);
  }
  state.selectedCharacter = characters().length - 1;
  touch();
  render();
  toast('已复制人物与案例');
}


function deleteCharacter() {
  const ch = selCharacter();
  if (!ch) return;
  const usage = characterUsage(ch.id);
  if (usage.length) { toast('该人物仍在关卡队列中，先移除或替换', 'warn'); return; }
  if (!confirm(`删除人物「${ch.name}」及其未使用的案例？`)) return;
  const cs = caseForCharacter(ch);
  state.content.charactersDoc.characters = characters().filter((c) => c.id !== ch.id);
  if (cs && !characterUsage(ch.id).length) {
    state.content.casesDoc.cases = cases().filter((c) => c.id !== cs.id);
  }
  state.selectedCharacter = Math.max(0, state.selectedCharacter - 1);
  touch();
  render();
}


function createCaseForCharacter() {
  const ch = selCharacter();
  if (!ch) return;
  if (findCase(`case-${ch.studentNo}`)) { toast('同学生号的案例已存在', 'warn'); return; }
  cases().push({
    id: `case-${ch.studentNo}`,
    title: '未命名论文题目',
    abstractTitle: '未命名论文题目',
    abstractChars: 360,
    excerpt: '',
    keywords: [],
    refs: [],
    body: { pages: 20, wordCount: 8000, gap: null, heading: '', excerpt: '' },
    form: { signatures: { advisor: '', chair: '', dean: '' }, human: false, ethicsNo: null, credits: 160, tuition: 'paid', tuitionOwed: 0 },
    line: '',
    cover: { overrides: {} },
    dup: { rate: 10.0, reportNo: '', seal: true, date: '', system: '', overrides: {} },
  });
  touch();
  render();
}


function editCaseJson() {
  const cs = selectedCase();
  if (!cs) return;
  openModal(`<h3>案例高级 JSON</h3><div class="modal-sub">参考文献、正文节选、关键词等完整结构。保存前会做 JSON 解析。</div>
    <textarea id="case-json" style="min-height:380px;width:100%">${esc(JSON.stringify(cs, null, 2))}</textarea>
    <div class="modal-actions"><button class="btn ghost" data-action="close-modal">取消</button><button class="btn primary" data-action="save-case-json">保存 JSON</button></div>`);
}


function saveCaseJson() {
  try {
    const parsed = JSON.parse($('#case-json').value);
    const cs = selectedCase();
    if (!cs) return;
    Object.keys(cs).forEach((key) => delete cs[key]);
    Object.assign(cs, parsed);
    closeModal();
    touch();
    render();
    toast('案例 JSON 已更新', 'good');
  } catch (error) {
    toast(`JSON 解析失败：${error.message}`, 'err');
  }
}


function addTask() {
  const id = nextId('task-new-', tasks().map((t) => t.id));
  const tk = {
    id,
    kind: 'scholarship',
    variant: '新待办',
    material: 'certificate',
    title: '新待办材料包',
    subtitle: 'ADMIN PACKET / NEW',
    header: '行政待办',
    summary: '',
    criteria: ['办理依据一', '办理依据二'],
    documents: [{
      id: 'application',
      tab: '申请表',
      icon: '申',
      kind: 'application',
      style: 'certificate',
      org: '明州大学',
      title: '新申请表',
      subtitle: 'APPLICATION / 2026',
      ref: '',
      fields: [['姓名', '{{name}}'], ['学号', '{{studentId}}']],
      paragraphs: [{ label: '申请理由', text: '' }],
      signature: [['申请人签字', '{{name}}'], ['日期', '{{dayDate}}']],
      seal: { top: '明州大学', bottom: '学生工作处', date: '' },
      note: '',
    }],
    checks: [],
    expected: 'approve',
    approveText: '材料齐全，批准。',
    returnText: '材料不齐，退回。',
  };
  tasks().push(tk);
  state.selectedTask = tasks().length - 1;
  state.selectedDoc = 0;
  state.view = 'tasks';
  touch();
  render();
}


function duplicateTask() {
  const tk = selTask();
  if (!tk) return;
  const copy = clone(tk);
  copy.id = nextId('task-copy-', tasks().map((t) => t.id));
  copy.title = `${tk.title}（副本）`;
  tasks().push(copy);
  state.selectedTask = tasks().length - 1;
  state.selectedDoc = 0;
  touch();
  render();
}


function deleteTask() {
  const tk = selTask();
  if (!tk) return;
  if (taskUsage(tk.id).length) { toast('该待办仍挂在关卡上，先解除挂接', 'warn'); return; }
  if (!confirm(`删除待办包「${tk.title}」？`)) return;
  state.content.tasksDoc.tasks = tasks().filter((t) => t.id !== tk.id);
  state.selectedTask = Math.max(0, state.selectedTask - 1);
  touch();
  render();
}


function addDoc() {
  const tk = selTask();
  if (!tk) return;
  const id = nextId('doc-', asArray(tk.documents).map((d) => d.id));
  tk.documents.push({
    id,
    tab: '新材料',
    icon: '文',
    kind: 'generic',
    style: 'certificate',
    org: '明州大学',
    title: '新材料',
    subtitle: 'SUPPORTING DOCUMENT',
    ref: '',
    fields: [['姓名', '{{name}}'], ['学号', '{{studentId}}']],
    paragraphs: [{ label: '说明', text: '' }],
    note: '',
  });
  state.selectedDoc = tk.documents.length - 1;
  touch();
  render();
}


function deleteDoc() {
  const tk = selTask();
  if (!tk) return;
  const docs = asArray(tk.documents);
  if (docs.length <= 1) { toast('待办包至少保留一份材料', 'warn'); return; }
  if (!confirm('删除这份材料？')) return;
  docs.splice(state.selectedDoc, 1);
  state.selectedDoc = Math.max(0, state.selectedDoc - 1);
  touch();
  render();
}


function moveDoc(delta) {
  const tk = selTask();
  if (!tk) return;
  const docs = asArray(tk.documents);
  const to = state.selectedDoc + delta;
  if (to < 0 || to >= docs.length) return;
  const [doc] = docs.splice(state.selectedDoc, 1);
  docs.splice(to, 0, doc);
  state.selectedDoc = to;
  touch();
  render();
}


function gotoIssue(path) {
  const parts = String(path).split(':');
  const kind = parts[0];
  const index = num(parts[1], 0);
  if (kind === 'levels') { state.view = 'levels'; state.selectedLevel = Math.max(0, Math.min(index, levels().length - 1)); }
  else if (kind === 'characters') { state.view = 'characters'; state.selectedCharacter = Math.max(0, Math.min(index, characters().length - 1)); }
  else if (kind === 'tasks') { state.view = 'tasks'; state.selectedTask = Math.max(0, Math.min(index, tasks().length - 1)); state.selectedDoc = 0; }
  else if (kind === 'logic') {
    state.view = 'logic';
    state.selectedChain = Math.max(0, Math.min(index, chains().length - 1));
    const nodeIndex = Number(parts[2]);
    const nodes = asArray(selChain()?.nodes);
    const node = Number.isInteger(nodeIndex) ? nodes[nodeIndex] : nodes[0];
    state.selectedLogicNode = node?.id || '';
    state.logicSelection = state.selectedLogicNode ? [state.selectedLogicNode] : [];
  } else { state.view = 'publish'; }
  render();
}


function editChapter() {
  if (!state.loaded) {
    toast('先载入项目', 'warn');
    return;
  }
  const ch = state.content.levelsDoc.chapter || {};
  openModal(`<h3>章节信息</h3><div class="modal-sub">这组关卡共享的标题与起始日期。</div>
    <div class="grid two">
      <div class="field"><label>章节 ID</label><input id="chapter-id" type="text" value="${esc(ch.id || 'chapter-1')}" /></div>
      <div class="field"><label>章节标题</label><input id="chapter-title-input" type="text" value="${esc(ch.title || '第一周')}" /></div>
      <div class="field"><label>起始日期</label><input id="chapter-date" type="text" value="${esc(ch.startDate || '')}" placeholder="2026.05.11" /></div>
    </div>
    <div class="modal-actions"><button class="btn ghost" data-action="close-modal">取消</button><button class="btn primary" data-action="save-chapter">保存</button></div>`);
}


function saveChapter() {
  const ch = state.content.levelsDoc.chapter;
  ch.id = $('#chapter-id').value.trim() || 'chapter-1';
  ch.title = $('#chapter-title-input').value.trim() || '第一周';
  ch.startDate = $('#chapter-date').value.trim();
  closeModal();
  touch();
  render();
}


Object.assign(env.api, { boot, bindGlobalEvents, scopeObject, setDeep, deleteDeep, applyScopeInput, applyDocList, applyOverride, pairsText, tableText, handleAction, selectLevel, addLevel, duplicateLevel, deleteLevel, moveSlot, duplicateSlot, deleteSlot, changeSlotCharacter, openCharacterPicker, pickCharacter, addCharacter, duplicateCharacter, deleteCharacter, createCaseForCharacter, editCaseJson, saveCaseJson, addTask, duplicateTask, deleteTask, addDoc, deleteDoc, moveDoc, gotoIssue, editChapter, saveChapter });
};
