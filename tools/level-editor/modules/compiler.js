/* compiler: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['compiler'] = function (env) {
'use strict';
const { $, clone, asArray, asText, num, STYLE_DEFS, WORLD_MAP, state } = env.model;
const cases = (...args) => env.api.cases(...args);
const characters = (...args) => env.api.characters(...args);
const content = (...args) => env.api.content(...args);
const findCase = (...args) => env.api.findCase(...args);
const findChar = (...args) => env.api.findChar(...args);
const findTask = (...args) => env.api.findTask(...args);
const levels = (...args) => env.api.levels(...args);
const tasks = (...args) => env.api.tasks(...args);
const validateDialogue = (...args) => env.api.validateDialogue(...args);
const validateLogic = (...args) => env.api.validateLogic(...args);

function validateProject() {
  const errors = [];
  const warnings = [];
  if (!state.loaded) return { errors, warnings };
  const c = state.content;
  const shape = env.api.shapeErrors({world:c.world, characters:c.charactersDoc?.characters,
    cases:c.casesDoc?.cases, tasks:c.tasksDoc?.tasks, levels_doc:c.levelsDoc});
  if (shape.length) return {errors:shape.map(text => ({severity:'error',text,path:'publish'})),warnings};
  const charIds = new Set();
  characters().forEach((ch, index) => {
    const path = `characters:${index}`;
    if (!ch.id) errors.push({ severity: 'error', text: '人物缺少 id', path });
    if (charIds.has(ch.id)) errors.push({ severity: 'error', text: `人物 id 重复：${ch.id}`, path });
    charIds.add(ch.id);
    if (!ch.name) errors.push({ severity: 'error', text: `人物 ${ch.id || '?'} 缺少姓名`, path });
    if (!ch.studentNo) warnings.push({ severity: 'warning', text: `人物 ${ch.name || ch.id} 缺少学号`, path });
  });
  const caseIds = new Set();
  cases().forEach((cs, index) => {
    const path = `characters:${index}`;
    if (!cs.id) errors.push({ severity: 'error', text: '案例缺少 id', path });
    if (caseIds.has(cs.id)) errors.push({ severity: 'error', text: `案例 id 重复：${cs.id}`, path });
    caseIds.add(cs.id);
    if (!cs.title) warnings.push({ severity: 'warning', text: `案例 ${cs.id || '?'} 缺少论文题目`, path });
    validateDialogue(cs, path, errors, warnings);
  });
  const taskIds = new Set();
  tasks().forEach((tk, index) => {
    if (!tk.id) errors.push({ severity: 'error', text: '待办包缺少 id', path: `tasks:${index}` });
    if (taskIds.has(tk.id)) errors.push({ severity: 'error', text: `待办包 id 重复：${tk.id}`, path: `tasks:${index}` });
    taskIds.add(tk.id);
    if (!['approve', 'return'].includes(tk.expected)) {
      errors.push({ severity: 'error', text: `待办 ${tk.id} 的结论必须是批准/退回`, path: `tasks:${index}` });
    }
    const strings = (value) => typeof value === 'string' ? [value] :
      value && typeof value === 'object' ? Object.values(value).flatMap(strings) : [];
    for (const text of strings(tk)) {
      if (text.includes('{{') && !text.includes('}}')) errors.push({severity:'error', text:`${tk.id}: malformed placeholder`, path:`tasks:${index}`});
    }
    const docs = asArray(tk.documents);
    if (!docs.length) errors.push({ severity: 'error', text: `待办 ${tk.id} 没有材料`, path: `tasks:${index}` });
    const docIds = new Set();
    docs.forEach((doc, di) => {
      if (!doc.id) errors.push({ severity: 'error', text: `待办 ${tk.id} 第 ${di + 1} 份材料缺少 id`, path: `tasks:${index}` });
      if (docIds.has(doc.id)) errors.push({ severity: 'error', text: `待办 ${tk.id} 材料 id 重复：${doc.id}`, path: `tasks:${index}` });
      docIds.add(doc.id);
      if (!STYLE_DEFS[doc.style]) errors.push({ severity: 'error', text: `材料 ${doc.id || '?'} 的纸张样式无效：${doc.style}`, path: `tasks:${index}` });
      if (!doc.title) warnings.push({ severity: 'warning', text: `材料 ${doc.id || '?'} 缺少标题`, path: `tasks:${index}` });
    });
    asArray(tk.checks).forEach((check) => {
      if (check.source && !docIds.has(check.source)) {
        errors.push({ severity: 'error', text: `待办 ${tk.id} 的核对项指向不存在的材料：${check.source}`, path: `tasks:${index}` });
      }
    });
  });

  const levelIds = new Set();
  const taskSlots = new Map();
  levels().forEach((lv, li) => {
    if (!lv.id) errors.push({ severity: 'error', text: `第 ${li + 1} 关缺少 id`, path: `levels:${li}` });
    if (levelIds.has(lv.id)) errors.push({ severity: 'error', text: `关卡 id 重复：${lv.id}`, path: `levels:${li}` });
    levelIds.add(lv.id);
    if (!asArray(lv.queue).length) errors.push({ severity: 'error', text: `${lv.id || '关卡'} 的队列为空`, path: `levels:${li}` });
    asArray(lv.queue).forEach((slot, si) => {
      if (!charIds.has(slot.characterId)) errors.push({ severity: 'error', text: `${lv.id} 第 ${si + 1} 位引用了不存在的人物：${slot.characterId}`, path: `levels:${li}` });
      if (!caseIds.has(slot.caseId)) errors.push({ severity: 'error', text: `${lv.id} 第 ${si + 1} 位引用了不存在的案例：${slot.caseId}`, path: `levels:${li}` });
      if (slot.taskId) {
        if (!taskIds.has(slot.taskId)) {
          errors.push({ severity: 'error', text: `${lv.id} 第 ${si + 1} 位引用了不存在的待办：${slot.taskId}`, path: `levels:${li}` });
        }
        if (taskSlots.has(slot.taskId)) {
          errors.push({ severity: 'error', text: `待办 ${slot.taskId} 被挂到多个队列位置`, path: `tasks:${tasks().findIndex((t) => t.id === slot.taskId)}` });
        } else {
          taskSlots.set(slot.taskId, `${lv.id}#${si + 1}`);
        }
      }
    });
  });
  tasks().forEach((tk, index) => {
    if (!taskSlots.has(tk.id) && !errors.some((e) => e.text.includes(tk.id) && e.text.includes('不存在'))) {
      errors.push({ severity: 'error', text: `待办 ${tk.id} 没有挂到任何关卡`, path: `tasks:${index}` });
    }
  });
  if (document.title && state.source) {
    // no-op, keeps the lint quiet about state.source
  }
  validateLogic(errors, warnings);
  return { errors, warnings };
}


function mergeStudent(ch, cs) {
  const official = {
    name: ch.name || '',
    id: ch.studentNo || '',
    major: ch.major || '',
    college: ch.college || '',
    clazz: ch.clazz || '',
    grade: ch.grade || '',
    advisor: ch.advisor || '',
    advisorTitle: ch.advisorTitle || '',
    advisorOffice: ch.advisorOffice || '',
    director: ch.director || '',
    directorTitle: ch.directorTitle || '',
    collegeGroup: ch.collegeGroup || '',
  };
  const cover = {
    title: cs.title || '',
    name: official.name,
    id: official.id,
    major: official.major,
    college: official.college,
    clazz: official.clazz,
  };
  Object.assign(cover, asObj(cs.cover?.overrides));
  const dupSrc = asObj(cs.dup);
  const dup = {
    rate: num(dupSrc.rate, 0),
    name: official.name,
    id: official.id,
    reportNo: asText(dupSrc.reportNo),
    seal: dupSrc.seal !== false,
    date: asText(dupSrc.date),
    system: asText(dupSrc.system),
  };
  Object.assign(dup, asObj(dupSrc.overrides));
  const student = {
    name: official.name,
    id: official.id,
    title: cs.title || '',
    abstractTitle: cs.abstractTitle || '',
    abstractChars: num(cs.abstractChars, 0),
    excerpt: cs.excerpt || '',
    keywords: asArray(cs.keywords),
    line: cs.line || '',
    look: asObj(ch.look),
    official,
    cover,
    refs: asArray(cs.refs),
    body: asObj(cs.body),
    dup,
    form: asObj(cs.form),
  };
  if (cs.chat !== undefined && cs.chat !== null) student.chat = cs.chat;
  if (cs.dialogue !== undefined && cs.dialogue !== null) student.dialogue = cs.dialogue;
  return student;
}


function asObj(v) { return v && typeof v === 'object' && !Array.isArray(v) ? v : {}; }

function compileProject() {
  const validation = validateProject();
  if (validation.errors.length) return { errors: validation.errors, data: null, requests: null };
  const data = {};
  const world = state.content.world || {};
  Object.entries(WORLD_MAP).forEach(([modern, legacy]) => {
    if (world[modern] !== undefined) data[legacy] = clone(world[modern]);
  });
  const days = [];
  const requests = [];
  levels().forEach((lv) => {
    const students = [];
    asArray(lv.queue).forEach((slot, index) => {
      const ch = findChar(slot.characterId);
      const cs = findCase(slot.caseId);
      if (!ch || !cs) return;
      students.push(mergeStudent(ch, cs));
      if (slot.taskId) {
        const task = findTask(slot.taskId);
        if (!task) return;
        const row = clone(task);
        row.day = num(lv.day, 1);
        row.applicantIndex = index;
        row.applicantId = ch.studentNo || '';
        requests.push(row);
      }
    });
    days.push({
      weekday: lv.weekday || '',
      date: lv.date || '',
      shortDate: lv.shortDate || '',
      theme: lv.theme || '',
      notice: lv.notice || '',
      students,
    });
  });
  data.DAYS = days;
  return { errors: [], data, requests: { requests } };
}


Object.assign(env.api, { validateProject, mergeStudent, asObj, compileProject });
};
