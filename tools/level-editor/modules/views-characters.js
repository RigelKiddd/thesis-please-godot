/* views-characters: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-characters'] = function (env) {
'use strict';
const { $, esc, asArray, num, state, DIALOGUE_SPEAKERS, DIALOGUE_STYLES } = env.model;
const asObj = (...args) => env.api.asObj(...args);
const characterUsage = (...args) => env.api.characterUsage(...args);
const characters = (...args) => env.api.characters(...args);
const nextId = (...args) => env.api.nextId(...args);
const portraitPath = (...args) => env.api.portraitPath(...args);
const render = (...args) => env.api.render(...args);
const selCharacter = (...args) => env.api.selCharacter(...args);
const selectedCase = (...args) => env.api.selectedCase(...args);
const toast = (...args) => env.api.toast(...args);
const touch = (...args) => env.api.touch(...args);

function viewCharacters() {
  const filter = state.charFilter.trim().toLowerCase();
  const list = characters().map((ch, index) => ({ ch, index })).filter(({ ch }) => {
    if (!filter) return true;
    return `${ch.name} ${ch.studentNo} ${ch.major} ${ch.college}`.toLowerCase().includes(filter);
  });
  const listHtml = list.map(({ ch, index }) => {
    const usage = characterUsage(ch.id);
    return `<button class="char-row ${index === state.selectedCharacter ? 'active' : ''}" data-action="select-character" data-index="${index}">
      <img src="${portraitPath(ch)}" alt="" onerror="this.style.visibility='hidden'" />
      <div class="cr-main"><div class="cr-name">${esc(ch.name || '未命名')}</div><div class="cr-sub">${esc(ch.studentNo)} · ${esc(ch.major || '')}</div></div>
      <span class="cr-use">${usage.length ? `${usage.length} 处` : '未使用'}</span>
    </button>`;
  }).join('');
  const ch = selCharacter();
  if (!ch) return '<div class="empty"><b>还没有人物</b>新增人物后即可编排关卡。</div>';
  const cs = selectedCase();
  const usage = characterUsage(ch.id);
  const taskLike = usage.filter((u) => u.slot.taskId);
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">CHARACTER REGISTRY / ${characters().length} PEOPLE</div>
        <h1 class="view-title">人物统一管理</h1>
        <div class="view-sub">名字、学号、专业、班级、导师与立绘只在这里维护。关卡引用人物 ID；封面和查重报告身份在构建时自动派生。</div>
      </div>
      <div class="view-actions">
        <button class="btn" data-action="add-character">新增人物</button>
        <button class="btn ghost" data-action="duplicate-character">复制</button>
        <button class="btn ghost" data-action="open-files">导入 JSON</button>
      </div>
    </div>
    <div class="char-layout">
      <div class="panel" style="padding:10px">
        <div class="search-row"><input id="char-search" type="text" value="${esc(state.charFilter)}" placeholder="搜索姓名 / 学号 / 专业" /></div>
        <div class="char-list">${listHtml || '<div class="empty" style="padding:14px">没有匹配的人物</div>'}</div>
      </div>
      <div class="panel">
        <div class="panel-head">
          <h3>${esc(ch.name || '未命名人物')}</h3>
          <span class="badge">${esc(ch.studentNo)}</span>
          ${usage.length ? `<span class="badge amber">${usage.length} 处引用</span>` : '<span class="badge">未使用</span>'}
          <span class="hint">${taskLike.length ? `其中 ${taskLike.length} 处挂有待办` : '未挂待办'}</span>
        </div>
        <div class="char-detail">
          <div>
            <div class="char-portrait-wrap">
              <img class="char-portrait" src="${portraitPath(ch)}" alt="${esc(ch.name)}" onerror="this.style.display='none';this.nextElementSibling.style.display='grid'" />
              <div class="char-portrait-fallback" style="display:none">${esc((ch.name || '?').slice(0, 1))}</div>
            </div>
            <div class="char-id">${esc(ch.id)}</div>
            <div class="char-id">立绘：${esc(ch.portrait)}.png</div>
            <div class="usage-list">
              ${usage.length ? usage.map((u) => `<div class="usage-item">第 ${u.level.day} 天 · 第 ${u.si + 1} 位${u.slot.taskId ? ' · 待办' : ''}</div>`).join('') : '<div class="usage-item">尚未进入任何关卡队列</div>'}
            </div>
            <div class="row" style="margin-top:10px;flex-wrap:wrap">
              <button class="btn small" data-action="select-level" data-index="${usage[0]?.li ?? state.selectedLevel}">在关卡中查看</button>
              <button class="btn small danger" data-action="delete-character" ${usage.length ? 'disabled title="先从未使用的人物开始删除"' : ''}>删除</button>
            </div>
          </div>
          <div>
            <div class="grid three">
              <div class="field"><label>姓名</label><input type="text" data-scope="char" data-key="name" value="${esc(ch.name)}" /></div>
              <div class="field"><label>学号</label><input type="text" data-scope="char" data-key="studentNo" value="${esc(ch.studentNo)}" /></div>
              <div class="field"><label>人物 ID</label><input type="text" data-scope="char" data-key="id" value="${esc(ch.id)}" /></div>
              <div class="field"><label>学院</label><input type="text" data-scope="char" data-key="college" value="${esc(ch.college)}" /></div>
              <div class="field"><label>专业</label><input type="text" data-scope="char" data-key="major" value="${esc(ch.major)}" /></div>
              <div class="field"><label>班级</label><input type="text" data-scope="char" data-key="clazz" value="${esc(ch.clazz)}" /></div>
              <div class="field"><label>年级</label><input type="text" data-scope="char" data-key="grade" value="${esc(ch.grade)}" /></div>
              <div class="field"><label>导师</label><input type="text" data-scope="char" data-key="advisor" value="${esc(ch.advisor)}" /></div>
              <div class="field"><label>立绘键</label><input type="text" data-scope="char" data-key="portrait" value="${esc(ch.portrait)}" placeholder="d1s1" /></div>
            </div>
            <div class="form-note" style="margin-top:6px">改名会同步影响封面、查重报告与待办包里的 {{name}}；如果某个案例要故意做错，请在本页下方“个案覆盖”里固定旧值。</div>
            ${cs ? caseCard(cs, ch) : '<div class="case-card"><h4>没有关联案例</h4><button class="btn small" data-action="create-case">为该人物创建论文案例</button></div>'}
          </div>
        </div>
      </div>
    </div>`;
}


function dialogueNodeList(d) {
  return asArray(d?.nodes);
}


function dialogueNodeById(d, id) {
  return dialogueNodeList(d).find((n) => n.id === id) || null;
}


function newDialogue() {
  return {
    start: 'n1',
    nodes: [{ id: 'n1', speaker: 'student', text: '', next: '', choices: [] }],
  };
}


function dialogueTargetOptions(d, selected) {
  const rows = dialogueNodeList(d).map((n) => `<option value="${esc(n.id)}" ${n.id === selected ? 'selected' : ''}>${esc(n.id)} · ${esc((String(n.text || '') || '空节点').slice(0, 14))}</option>`).join('');
  return `<option value="" ${!selected ? 'selected' : ''}>— 结束 —</option>${rows}`;
}


function dialogueChoiceRow(choice, ci, node, d) {
  return `<div class="dlg-choice">
    <input type="text" data-dialogue-choice-field="label" data-dialogue-node="${esc(node.id)}" data-choice="${ci}" value="${esc(choice.label || '')}" placeholder="回复选项文字" />
    <select data-dialogue-choice-field="next" data-dialogue-node="${esc(node.id)}" data-choice="${ci}">${dialogueTargetOptions(d, choice.next || '')}</select>
    <select data-dialogue-choice-field="style" data-dialogue-node="${esc(node.id)}" data-choice="${ci}">${DIALOGUE_STYLES.map(([id, label]) => `<option value="${id}" ${(choice.style || '') === id ? 'selected' : ''}>${label}</option>`).join('')}</select>
    <input type="number" class="dlg-min" data-dialogue-choice-field="timeSaved" data-dialogue-node="${esc(node.id)}" data-choice="${ci}" value="${esc(choice.timeSaved ?? 0)}" title="省下的分钟数" />
    <button class="btn small danger" data-action="dialogue-del-choice" data-node="${esc(node.id)}" data-choice="${ci}" title="删除这个回复选项">×</button>
  </div>`;
}


function dialogueNodeCard(node, index, d) {
  const choices = asArray(node.choices);
  return `<div class="dlg-node" data-dlg-node="${esc(node.id)}">
    <div class="dlg-node-head">
      <span class="badge">#${index + 1}</span>
      <input class="dlg-id" type="text" data-dialogue-field="id" data-dialogue-node="${esc(node.id)}" value="${esc(node.id)}" title="节点 ID" />
      <select data-dialogue-field="speaker" data-dialogue-node="${esc(node.id)}" title="说话人">
        ${DIALOGUE_SPEAKERS.map(([id, label]) => `<option value="${id}" ${(node.speaker || 'student') === id ? 'selected' : ''}>${label}</option>`).join('')}
      </select>
      <select data-dialogue-field="next" data-dialogue-node="${esc(node.id)}" title="本节点没有回复选项时的下一节点">${dialogueTargetOptions(d, node.next || '')}</select>
      <input class="dlg-delay" type="number" step="0.1" min="0" data-dialogue-field="delay" data-dialogue-node="${esc(node.id)}" value="${esc(node.delay ?? 0.55)}" title="出现延迟（秒）" />
      <button class="btn small danger" data-action="dialogue-del-node" data-node="${esc(node.id)}" title="删除节点">删除</button>
    </div>
    <textarea rows="2" data-dialogue-field="text" data-dialogue-node="${esc(node.id)}" placeholder="气泡文字。留空表示只显示选项。">${esc(node.text || '')}</textarea>
    <div class="dlg-choices">
      <div class="dlg-choice-head"><span>回复选项</span><button class="btn small" data-action="dialogue-add-choice" data-node="${esc(node.id)}">+ 回复</button></div>
      ${choices.length ? choices.map((ch, ci) => dialogueChoiceRow(ch, ci, node, d)).join('') : '<div class="hint">没有回复选项时，沿“下一节点”继续；有选项时，玩家必须选一个。</div>'}
    </div>
  </div>`;
}


function dialoguePreview(d) {
  if (!d || !dialogueNodeList(d).length) return '';
  let id = d.start;
  const seen = new Set();
  const rows = [];
  while (id && !seen.has(id) && rows.length < 6) {
    seen.add(id);
    const node = dialogueNodeById(d, id);
    if (!node) {
      rows.push(`<div class="dlg-preview-missing">缺少节点 ${esc(id)}</div>`);
      break;
    }
    const speaker = DIALOGUE_SPEAKERS.find(([sid]) => sid === (node.speaker || 'student'))?.[1] || '学生';
    rows.push(`<div class="dlg-preview-bubble speaker-${esc(node.speaker || 'student')}"><b>${esc(speaker)}</b><span>${esc(node.text || '（空）')}</span></div>`);
    if (asArray(node.choices).length) {
      rows.push(`<div class="dlg-preview-choices">${asArray(node.choices).map((ch) => `<span>${esc(ch.label || '未命名')} → ${esc(ch.next || '结束')}</span>`).join('')}</div>`);
      break;
    }
    id = node.next;
  }
  return `<div class="dlg-preview">${rows.join('')}</div>`;
}


function dialogueEditor(d) {
  if (!d) {
    return `<div class="dlg-empty">
      <div class="form-note">还没有自定义对话树。自定义后会完全覆盖自动生成的 3 条消息；可编辑说话人、回复选项和每个选项的后续分支。</div>
      <div class="row" style="margin-top:6px"><button class="btn" data-action="dialogue-create">新建空白对话树</button><button class="btn ghost" data-action="dialogue-from-auto">从自动消息生成</button></div>
    </div>`;
  }
  return `<div class="dlg-tools">
    <span class="badge">START</span>
    <select data-dialogue-start>${dialogueNodeList(d).map((n) => `<option value="${esc(n.id)}" ${n.id === d.start ? 'selected' : ''}>${esc(n.id)} · ${esc((n.text || '空').slice(0, 16))}</option>`).join('')}</select>
    <button class="btn small" data-action="dialogue-add-node">+ 节点</button>
    <button class="btn small ghost" data-action="dialogue-from-auto">从自动消息生成</button>
    <button class="btn small danger" data-action="dialogue-delete">清空对话树</button>
  </div>
  <div class="dlg-nodes">${dialogueNodeList(d).map((n, i) => dialogueNodeCard(n, i, d)).join('')}</div>
  ${dialoguePreview(d)}`;
}


function ensureDialogue(cs) {
  if (!cs.dialogue || !Array.isArray(cs.dialogue.nodes) || !cs.dialogue.nodes.length) {
    cs.dialogue = newDialogue();
  }
  if (!cs.dialogue.start) cs.dialogue.start = cs.dialogue.nodes[0].id;
  return cs.dialogue;
}


function dialogueFromAuto(cs) {
  const line = String(cs.line || '').trim() || '老师好，材料我放到 03 窗口了。';
  const extra = asArray(cs.chat).filter(Boolean);
  const nodes = [];
  const n1 = { id: 'n1', speaker: 'student', text: line, next: 'n2', choices: [] };
  const prompts = extra.length ? extra : ['有一处我不太确定，您能帮我看一下吗？'];
  let cursor = 2;
  let prev = 'n1';
  prompts.forEach((text, i) => {
    const id = `n${cursor}`;
    nodes.push({ id, speaker: 'student', text, next: '', choices: [] });
    const prevNode = nodes.find((n) => n.id === prev) || n1;
    prevNode.next = id;
    prev = id;
    cursor += 1;
  });
  nodes.unshift(n1);
  const choiceNode = nodes.find((n) => n.id === prev);
  choiceNode.choices = [
    { label: '按清单核对', next: `n${cursor}`, style: 'checklist', timeSaved: 0 },
    { label: '最担心哪项？', next: `n${cursor + 1}`, style: 'concern', timeSaved: 0 },
    { label: '先放桌上', next: `n${cursor + 2}`, style: 'desk', timeSaved: 10 },
  ];
  nodes.push({ id: `n${cursor}`, speaker: 'student', text: '好的，我按清单再核一遍，谢谢老师。', next: '', choices: [] });
  nodes.push({ id: `n${cursor + 1}`, speaker: 'student', text: '可能是材料里我拿不准的那一项，麻烦您帮我看看。', next: '', choices: [] });
  nodes.push({ id: `n${cursor + 2}`, speaker: 'student', text: '好，那我先放桌上。', next: '', choices: [] });
  return { start: 'n1', nodes };
}


function addDialogueNode() {
  const cs = selectedCase();
  if (!cs) return;
  const d = ensureDialogue(cs);
  let n = d.nodes.length + 1;
  while (dialogueNodeById(d, `n${n}`)) n += 1;
  d.nodes.push({ id: `n${n}`, speaker: 'student', text: '', next: '', choices: [] });
  touch();
  render();
}


function deleteDialogueNode(nodeId) {
  const cs = selectedCase();
  const d = cs?.dialogue;
  if (!d) return;
  const node = dialogueNodeById(d, nodeId);
  if (!node) return;
  if (!confirm(`删除对话节点「${nodeId}」？引用它的连接会变成结束。`)) return;
  d.nodes = d.nodes.filter((n) => n.id !== nodeId);
  d.nodes.forEach((n) => {
    if (n.next === nodeId) n.next = '';
    asArray(n.choices).forEach((ch) => { if (ch.next === nodeId) ch.next = ''; });
  });
  if (d.start === nodeId) d.start = d.nodes[0]?.id || '';
  touch();
  render();
}


function applyDialogueField(el) {
  const cs = selectedCase();
  const d = cs?.dialogue;
  if (!d) return;
  const node = dialogueNodeById(d, el.dataset.dialogueNode);
  if (!node) return;
  const key = el.dataset.dialogueField;
  if (key === 'id') {
    const nextId = String(el.value || '').trim();
    if (!nextId || nextId === node.id) return;
    if (dialogueNodeById(d, nextId)) { toast('节点 ID 已存在', 'warn'); return; }
    const old = node.id;
    node.id = nextId;
    d.nodes.forEach((n) => {
      if (n.next === old) n.next = nextId;
      asArray(n.choices).forEach((ch) => { if (ch.next === old) ch.next = nextId; });
    });
    if (d.start === old) d.start = nextId;
    touch();
    render();
    return;
  }
  if (key === 'delay') node.delay = num(el.value, 0.55);
  else node[key] = el.value;
  touch();
}


function applyDialogueChoiceField(el) {
  const cs = selectedCase();
  const d = cs?.dialogue;
  const node = dialogueNodeById(d, el.dataset.dialogueNode);
  const ci = num(el.dataset.choice, 0);
  const choice = node?.choices?.[ci];
  if (!choice) return;
  const key = el.dataset.dialogueChoiceField;
  if (key === 'timeSaved') choice.timeSaved = num(el.value, 0);
  else choice[key] = el.value;
  touch();
}


function validateDialogue(cs, path, errors, warnings) {
  for (const code of env.api.dialogueErrors(cs.dialogue)) errors.push({severity: "error", code, text: `案例 ${cs.id}: ${env.api.contractMessage(code)}`, path});
}


function caseCard(cs, ch) {
  const cover = asObj(cs.cover?.overrides);
  const dup = asObj(cs.dup?.overrides);
  return `<div class="case-card">
    <div class="row" style="margin-bottom:6px">
      <h4 style="margin:0">论文案例 · ${esc(cs.id)}</h4>
      <span class="badge">${esc(cs.abstractChars || 0)} 字摘要</span>
      <span class="badge ${num(cs.dup?.rate) > 20 ? 'red' : 'green'}">查重 ${esc(cs.dup?.rate ?? 0)}%</span>
      <div class="spacer"></div>
      <button class="btn small ghost" data-action="edit-case-json">高级 JSON</button>
    </div>
    <div class="grid three">
      <div class="field span-2"><label>论文题目</label><input type="text" data-scope="case" data-key="title" value="${esc(cs.title)}" /></div>
      <div class="field"><label>摘要字数</label><input type="number" data-scope="case" data-key="abstractChars" value="${esc(cs.abstractChars)}" /></div>
      <div class="field span-2"><label>摘要页题目（可与封面不同，故意做错时使用）</label><input type="text" data-scope="case" data-key="abstractTitle" value="${esc(cs.abstractTitle)}" /></div>
      <div class="field"><label>查重率 %</label><input type="number" step="0.1" data-scope="case" data-key="dup.rate" value="${esc(cs.dup?.rate ?? 0)}" /></div>
      <div class="field"><label>查重报告编号</label><input type="text" data-scope="case" data-key="dup.reportNo" value="${esc(cs.dup?.reportNo)}" /></div>
      <div class="field"><label>检测系统</label><input type="text" data-scope="case" data-key="dup.system" value="${esc(cs.dup?.system)}" /></div>
      <div class="field"><label>已修学分</label><input type="number" data-scope="case" data-key="form.credits" value="${esc(cs.form?.credits ?? 0)}" /></div>
      <div class="field"><label>学费状态</label><select data-scope="case" data-key="form.tuition"><option value="paid" ${cs.form?.tuition === 'paid' ? 'selected' : ''}>已缴清</option><option value="owed" ${cs.form?.tuition !== 'paid' ? 'selected' : ''}>欠缴</option></select></div>
      <div class="field"><label>导师签字</label><input type="text" data-scope="case" data-key="form.signatures.advisor" value="${esc(cs.form?.signatures?.advisor)}" /></div>
      <div class="field"><label>系主任签字</label><input type="text" data-scope="case" data-key="form.signatures.chair" value="${esc(cs.form?.signatures?.chair)}" /></div>
      <div class="field"><label>教学院长签字</label><input type="text" data-scope="case" data-key="form.signatures.dean" value="${esc(cs.form?.signatures?.dean)}" /></div>
      <div class="field"><label>正文页数</label><input type="number" data-scope="case" data-key="body.pages" value="${esc(cs.body?.pages ?? 0)}" /></div>
      <div class="field"><label>正文字数</label><input type="number" data-scope="case" data-key="body.wordCount" value="${esc(cs.body?.wordCount ?? 0)}" /></div>
    </div>
    <div class="sec">
      <div class="sec-title">学生消息 / WECHAT</div>
      <div class="field"><label>主消息（学生递材料时说的第一句）</label><textarea data-scope="case" data-key="line" rows="2">${esc(cs.line || '')}</textarea></div>
      <div class="field" style="margin-top:7px"><label>自定义消息序列（每行一条；留空则按缺陷自动生成）</label><textarea data-scope="case" data-key="chat" data-list="lines" rows="3" placeholder="老师好…&#10;材料我放窗口了…">${esc(asArray(cs.chat).join('\n'))}</textarea></div>
      <div class="form-note" style="margin-top:5px">消息会进入学生微信窗口；有缺陷时，玩家仍会出现三选一回复。自定义序列会覆盖自动生成的 3 条消息，但不会改变缺陷与回复判定。</div>
    </div>
    <div class="sec dialogue-sec">
      <div class="sec-title">对话树 / WECHAT DIALOGUE <span class="hint">自定义后优先于上面的快捷消息</span></div>
      ${dialogueEditor(cs.dialogue)}
    </div>
    <div class="form-note" style="margin-top:8px">个案覆盖（留空表示使用人物主档）：封面 / 报告里故意写错的姓名、学号、专业。</div>
    <div class="override-grid">
      <div class="field"><label>封面学号</label><input type="text" data-override="cover.id" value="${esc(cover.id || '')}" placeholder="使用人物学号" /></div>
      <div class="field"><label>封面专业</label><input type="text" data-override="cover.major" value="${esc(cover.major || '')}" placeholder="使用人物专业" /></div>
      <div class="field"><label>报告学号</label><input type="text" data-override="dup.id" value="${esc(dup.id || '')}" placeholder="使用人物学号" /></div>
    </div>
  </div>`;
}


Object.assign(env.api, { viewCharacters, dialogueNodeList, dialogueNodeById, newDialogue, dialogueTargetOptions, dialogueChoiceRow, dialogueNodeCard, dialoguePreview, dialogueEditor, ensureDialogue, dialogueFromAuto, addDialogueNode, deleteDialogueNode, applyDialogueField, applyDialogueChoiceField, validateDialogue, caseCard });
};
