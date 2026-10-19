/* store: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['store'] = function (env) {
'use strict';
const { $, esc, asArray, state } = env.model;
const scheduleAutosave = (...args) => env.api.scheduleAutosave(...args);
const scheduleValidate = (...args) => env.api.scheduleValidate(...args);
const updateChrome = (...args) => env.api.updateChrome(...args);

function content() { return state.content; }

function levels() { return asArray(state.content?.levelsDoc?.levels); }

function characters() { return asArray(state.content?.charactersDoc?.characters); }

function cases() { return asArray(state.content?.casesDoc?.cases); }

function tasks() { return asArray(state.content?.tasksDoc?.tasks); }

function selLevel() { return levels()[state.selectedLevel] || null; }

function selCharacter() { return characters()[state.selectedCharacter] || null; }

function selTask() { return tasks()[state.selectedTask] || null; }

function logicDoc() { return state.content?.logicDoc || { schema: 1, chains: [] }; }

function chains() { return asArray(logicDoc().chains); }

function selChain() { return chains()[state.selectedChain] || null; }

function selLogicNode() {
  const chain = selChain();
  if (!chain) return null;
  return asArray(chain.nodes).find((n) => n.id === state.selectedLogicNode) || null;
}

function findChar(id) { return characters().find((c) => c.id === id) || null; }

function findCase(id) { return cases().find((c) => c.id === id) || null; }

function findTask(id) { return tasks().find((t) => t.id === id) || null; }

function findLevel(id) { return levels().find((l) => l.id === id) || null; }

function characterUsage(charId) {
  const out = [];
  levels().forEach((lv, li) => {
    asArray(lv.queue).forEach((slot, si) => {
      if (slot.characterId === charId) out.push({ level: lv, li, slot, si });
    });
  });
  return out;
}


function taskUsage(taskId) {
  const out = [];
  levels().forEach((lv, li) => {
    asArray(lv.queue).forEach((slot, si) => {
      if (slot.taskId === taskId) out.push({ level: lv, li, slot, si });
    });
  });
  return out;
}


function caseForCharacter(ch) {
  if (!ch) return null;
  const usage = characterUsage(ch.id);
  for (const u of usage) {
    const c = findCase(u.slot.caseId);
    if (c) return c;
  }
  return findCase(`case-${ch.studentNo}`);
}


function selectedCase() { return caseForCharacter(selCharacter()); }

function characterForSlot(slot) { return findChar(slot.characterId); }

function caseForSlot(slot) { return findCase(slot.caseId); }

function taskForSlot(slot) { return slot.taskId ? findTask(slot.taskId) : null; }

function portraitPath(ch) {
  return `../../assets/portraits/${esc(ch?.portrait || 'd1s1')}.png`;
}


function nextId(prefix, existing) {
  let i = 1;
  while (existing.includes(`${prefix}${String(i).padStart(2, '0')}`)) i++;
  return `${prefix}${String(i).padStart(2, '0')}`;
}


function uidSuffix() {
  return String(Date.now()).slice(-6) + String(Math.floor(Math.random() * 90 + 10));
}


function touch() {
  state.dirty = true;
  updateChrome();
  scheduleValidate();
  scheduleAutosave();
}


Object.assign(env.api, { content, levels, characters, cases, tasks, selLevel, selCharacter, selTask, logicDoc, chains, selChain, selLogicNode, findChar, findCase, findTask, findLevel, characterUsage, taskUsage, caseForCharacter, selectedCase, characterForSlot, caseForSlot, taskForSlot, portraitPath, nextId, uidSuffix, touch });
};
