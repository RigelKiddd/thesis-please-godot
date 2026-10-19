/* views-tasks: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-tasks'] = function (env) {
'use strict';
const { $, clone, esc, asArray, num, STYLE_DEFS, STYLE_ORDER, STYLE_TEXTURE, STYLE_BAND, TASK_KINDS, DOC_KINDS, DOC_KIND_LABEL, state } = env.model;
const caseForCharacter = (...args) => env.api.caseForCharacter(...args);
const caseForSlot = (...args) => env.api.caseForSlot(...args);
const cases = (...args) => env.api.cases(...args);
const characterForSlot = (...args) => env.api.characterForSlot(...args);
const characters = (...args) => env.api.characters(...args);
const content = (...args) => env.api.content(...args);
const pairsText = (...args) => env.api.pairsText(...args);
const selTask = (...args) => env.api.selTask(...args);
const tableText = (...args) => env.api.tableText(...args);
const taskUsage = (...args) => env.api.taskUsage(...args);
const tasks = (...args) => env.api.tasks(...args);

function viewTasks() {
  const list = tasks().map((tk, index) => {
    const usage = taskUsage(tk.id);
    const docs = asArray(tk.documents).length;
    return `<button class="task-row ${index === state.selectedTask ? 'active' : ''}" data-action="select-task" data-index="${index}">
      <div class="tr-top"><span class="badge ${tk.expected === 'approve' ? 'green' : 'red'}">${tk.expected === 'approve' ? '批准' : '退回'}</span><span class="badge">${esc(TASK_KINDS[tk.kind]?.label || tk.kind || '待办')}</span><span class="tr-id">${esc(tk.id)}</span></div>
      <div class="tr-title">${esc(tk.title || '未命名待办')}</div>
      <div class="tr-sub"><span>${esc(tk.variant || '')}</span><span>·</span><span>${docs} 份材料</span><span>·</span><span>${usage.length ? `第 ${usage[0].level.day} 天 #${usage[0].si + 1}` : '未挂接'}</span></div>
    </button>`;
  }).join('');
  const tk = selTask();
  if (!tk) return '<div class="empty"><b>还没有待办包</b>新增一个，挂到关卡队列上。</div>';
  const usage = taskUsage(tk.id);
  const docs = asArray(tk.documents);
  state.selectedDoc = Math.min(state.selectedDoc, Math.max(0, docs.length - 1));
  const doc = docs[state.selectedDoc] || null;
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">ADMIN PACKETS / FACE TO FACE</div>
        <h1 class="view-title">当面待办包</h1>
        <div class="view-sub">一个待办包 = 学生当面递来的一组材料 + 办理依据 + 正确结论。挂到关卡队列后，只有该学生轮到窗口时才会出现。</div>
      </div>
      <div class="view-actions">
        <button class="btn" data-action="add-task">新增待办包</button>
        <button class="btn ghost" data-action="duplicate-task">复制</button>
        <button class="btn warn small" data-action="delete-task" ${usage.length ? 'disabled title="先解除关卡挂接"' : ''}>删除</button>
      </div>
    </div>
    <div class="task-layout">
      <div class="panel" style="padding:8px">
        <div class="task-list">${list}</div>
      </div>
      <div>
        <div class="panel">
          <div class="panel-head"><h3>${esc(tk.title || '待办包')}</h3><span class="badge">${esc(tk.id)}</span>${usage.length ? `<span class="badge amber">第 ${usage[0].level.day} 天 · 第 ${usage[0].si + 1} 位</span>` : '<span class="badge red">未挂接</span>'}</div>
          <div class="grid four">
            <div class="field span-2"><label>标题</label><input type="text" data-scope="task" data-key="title" value="${esc(tk.title)}" /></div>
            <div class="field"><label>ID</label><input type="text" data-scope="task" data-key="id" value="${esc(tk.id)}" /></div>
            <div class="field"><label>类型</label><select data-scope="task" data-key="kind">${Object.entries(TASK_KINDS).map(([id, def]) => `<option value="${id}" ${tk.kind === id ? 'selected' : ''}>${def.label}</option>`).join('')}</select></div>
            <div class="field"><label>变体</label><input type="text" data-scope="task" data-key="variant" value="${esc(tk.variant)}" /></div>
            <div class="field"><label>正确结论</label><select data-scope="task" data-key="expected"><option value="approve" ${tk.expected === 'approve' ? 'selected' : ''}>批准</option><option value="return" ${tk.expected === 'return' ? 'selected' : ''}>退回</option></select></div>
            <div class="field"><label>材料主样式</label><select data-scope="task" data-key="material">${STYLE_ORDER.map((id) => `<option value="${id}" ${tk.material === id ? 'selected' : ''}>${STYLE_DEFS[id].label}</option>`).join('')}</select></div>
            <div class="field"><label>页面抬头</label><input type="text" data-scope="task" data-key="header" value="${esc(tk.header)}" /></div>
            <div class="field span-2"><label>一句话提示</label><input type="text" data-scope="task" data-key="summary" value="${esc(tk.summary)}" /></div>
            <div class="field span-2"><label>英文副标</label><input type="text" data-scope="task" data-key="subtitle" value="${esc(tk.subtitle)}" /></div>
            <div class="field span-2"><label>办理依据（每行一条）</label><textarea data-scope="task" data-key="criteria" data-list="lines" style="min-height:74px">${esc(asArray(tk.criteria).join('\n'))}</textarea></div>
            <div class="field span-2"><label>批准后文本</label><input type="text" data-scope="task" data-key="approveText" value="${esc(tk.approveText)}" /></div>
            <div class="field span-2"><label>退回后文本</label><input type="text" data-scope="task" data-key="returnText" value="${esc(tk.returnText)}" /></div>
          </div>
          <div class="form-note" style="margin-top:6px">${usage.length ? `已挂到 ${usage.map((u) => `第 ${u.level.day} 天 #${u.si + 1}`).join('、')}。` : '尚未挂到关卡：到“关卡”页的队列行选择这个待办包。'}</div>
        </div>
        <div class="panel">
          <div class="panel-head">
            <h3>材料包</h3>
            <span class="hint">${docs.length} 份 · 点击左侧选择，右侧编辑并实时预览</span>
            <div class="spacer"></div>
            <button class="btn small" data-action="add-doc">+ 添加材料</button>
          </div>
          <div class="doc-layout">
            <div class="doc-list">
              ${docs.map((d, i) => docCard(d, i)).join('') || '<div class="empty" style="padding:12px">还没有材料</div>'}
            </div>
            ${doc ? docEditor(doc, tk) : '<div class="empty">选择或添加一份材料。</div>'}
            ${doc ? `<div class="doc-preview-wrap"><div class="doc-preview-label">LIVE PAPER PREVIEW / 实时纸张预览 · ${esc(previewTokens(tk).name)}</div>${paperPreview(previewDoc(doc))}</div>` : ''}
          </div>
        </div>
      </div>
    </div>`;
}


function docCard(doc, index) {
  const st = STYLE_DEFS[doc.style] || STYLE_DEFS.certificate;
  return `<button class="doc-card ${index === state.selectedDoc ? 'active' : ''}" data-action="select-doc" data-index="${index}">
    <span class="dc-icon" style="background:${st.bg};color:${st.accent}">${esc(doc.icon || '文')}</span>
    <span class="dc-main"><span class="dc-tab">${esc(doc.tab || doc.title || '材料')}</span><span class="dc-kind">${esc(st.label)} · ${esc(DOC_KIND_LABEL[doc.kind] || doc.kind || '通用')}</span></span>
    <span class="badge" style="padding:0 3px">${index + 1}</span>
  </button>`;
}


function docEditor(doc, tk) {
  const st = STYLE_DEFS[doc.style] || STYLE_DEFS.certificate;
  return `<div class="doc-editor">
    <div class="row" style="margin-bottom:8px">
      <span class="badge" style="background:${st.bg};color:${st.accent};border-color:${st.border}">${esc(st.label)}</span>
      <span class="badge">${esc(doc.id)}</span>
      <div class="spacer"></div>
      <button class="btn small icon" data-action="move-doc-up" title="上移" ${state.selectedDoc === 0 ? 'disabled' : ''}>↑</button>
      <button class="btn small icon" data-action="move-doc-down" title="下移" ${state.selectedDoc === asArray(tk.documents).length - 1 ? 'disabled' : ''}>↓</button>
      <button class="btn small danger" data-action="delete-doc">删除</button>
    </div>
    <div class="grid two">
      <div class="field"><label>材料 ID</label><input type="text" data-scope="doc" data-key="id" value="${esc(doc.id)}" /></div>
      <div class="field"><label>页签</label><input type="text" data-scope="doc" data-key="tab" value="${esc(doc.tab)}" /></div>
      <div class="field"><label>纸张样式</label><select data-scope="doc" data-key="style">${STYLE_ORDER.map((id) => `<option value="${id}" ${doc.style === id ? 'selected' : ''}>${STYLE_DEFS[id].label}</option>`).join('')}</select></div>
      <div class="field"><label>材料类型</label><select data-scope="doc" data-key="kind">${DOC_KINDS.map((id) => `<option value="${id}" ${doc.kind === id ? 'selected' : ''}>${DOC_KIND_LABEL[id]}</option>`).join('')}</select></div>
      <div class="field"><label>页签图标</label><input type="text" data-scope="doc" data-key="icon" value="${esc(doc.icon)}" maxlength="2" /></div>
      <div class="field"><label>机关 / 抬头</label><input type="text" data-scope="doc" data-key="org" value="${esc(doc.org)}" /></div>
      <div class="field span-2"><label>材料标题</label><input type="text" data-scope="doc" data-key="title" value="${esc(doc.title)}" /></div>
      <div class="field span-2"><label>英文副标</label><input type="text" data-scope="doc" data-key="subtitle" value="${esc(doc.subtitle)}" /></div>
      <div class="field"><label>材料编号</label><input type="text" data-scope="doc" data-key="ref" value="${esc(doc.ref)}" /></div>
      <div class="field" style="justify-content:flex-end"><label style="display:flex;gap:6px;align-items:center;text-transform:none;letter-spacing:0"><input type="checkbox" data-scope="doc" data-key="photo" ${doc.photo ? 'checked' : ''} /> 申请表照片框</label></div>
    </div>
    <div class="style-picks">
      ${STYLE_ORDER.map((id) => `<button class="style-pick ${doc.style === id ? 'active' : ''}" data-action="pick-doc-style" data-style="${id}" title="${esc(STYLE_DEFS[id].label)}">
        <i style="background-image:url('../../assets/textures/paper_${STYLE_TEXTURE[id] || 'certificate'}.png');background-color:${STYLE_DEFS[id].bg};border-color:${STYLE_DEFS[id].border}"></i>
        <span>${esc(STYLE_DEFS[id].label)}</span>
      </button>`).join('')}
    </div>
    <div class="sec">
      <div class="sec-title">字段 / Fields（每行“标签 | 值”）</div>
      <textarea data-doclist="fields">${esc(pairsText(doc.fields))}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">指标 / Stats（每行“名称 | 数值”）</div>
      <textarea data-doclist="stats">${esc(pairsText(doc.stats))}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">表格 / Table（第一行表头，其余为数据行）</div>
      <textarea data-doclist="table">${esc(tableText(doc.table))}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">段落 / Paragraphs（每行“小标题 | 正文”）</div>
      <textarea data-doclist="paragraphs">${esc(pairsText(doc.paragraphs))}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">落款 / Signatures（每行“角色 | 姓名”）</div>
      <textarea data-doclist="signature">${esc(pairsText(doc.signature))}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">备注 / Note</div>
      <textarea data-scope="doc" data-key="note" style="min-height:48px">${esc(doc.note)}</textarea>
    </div>
    <div class="sec">
      <div class="sec-title">印章 / Seal</div>
      <div class="grid three">
        <div class="field"><label>上环文字</label><input type="text" data-scope="doc" data-key="seal.top" value="${esc(doc.seal?.top || '')}" /></div>
        <div class="field"><label>下方机构</label><input type="text" data-scope="doc" data-key="seal.bottom" value="${esc(doc.seal?.bottom || '')}" /></div>
        <div class="field"><label>日期</label><input type="text" data-scope="doc" data-key="seal.date" value="${esc(doc.seal?.date || '')}" /></div>
      </div>
    </div>
  </div>`;
}


function previewTokens(tk) {
  const usage = tk ? taskUsage(tk.id) : [];
  const use = usage[0];
  const ch = use ? characterForSlot(use.slot) : characters()[0];
  const cs = use ? caseForSlot(use.slot) : (ch ? caseForCharacter(ch) : cases()[0]);
  const rate = num(cs?.dup?.rate, 0);
  return {
    name: ch?.name || '王芷晴',
    studentId: ch?.studentNo || '2022010516',
    major: ch?.major || '会计学',
    clazz: ch?.clazz || '会计2201',
    college: ch?.college || '商学院',
    advisor: ch?.advisor || '周明远',
    cover_title: cs?.title || '论文题目',
    dup_rate: rate.toFixed(1),
    form_rate: (rate + 5.6).toFixed(1),
    dayDate: use?.level?.date || '2026.05.12',
  };
}


function fillTokens(value, tokens) {
  if (typeof value === 'string') {
    return value.replace(/\{\{(\w+)\}\}/g, (match, key) => (tokens[key] !== undefined ? String(tokens[key]) : match));
  }
  if (Array.isArray(value)) return value.map((item) => fillTokens(item, tokens));
  if (value && typeof value === 'object') {
    const out = {};
    Object.keys(value).forEach((key) => { out[key] = fillTokens(value[key], tokens); });
    return out;
  }
  return value;
}


function previewDoc(doc) {
  if (!doc) return null;
  return fillTokens(clone(doc), previewTokens(selTask()));
}


function paperPreview(doc) {
  const st = STYLE_DEFS[doc.style] || STYLE_DEFS.certificate;
  const styleClass = `paper-preview style-${doc.style || 'certificate'}`;
  const band = `<div class="pp-band"><span>${esc(STYLE_BAND[doc.style] || STYLE_BAND.certificate)}</span><span>${esc(doc.ref || '')}</span></div>`;
  const fields = asArray(doc.fields).map((row) => `<div class="pp-field"><b>${esc(row[0])}</b>${esc(row[1])}</div>`).join('');
  const stats = asArray(doc.stats).map((row) => `<div class="pp-stat"><span>${esc(row[0])}</span><b>${esc(row[1])}</b></div>`).join('');
  const table = doc.table && asArray(doc.table.columns).length ? `<table><thead><tr>${asArray(doc.table.columns).map((c) => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${asArray(doc.table.rows).map((row) => `<tr>${asArray(row).map((c) => `<td>${esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table>` : '';
  const paras = asArray(doc.paragraphs).map((p) => `<div class="pp-para"><b>${esc(p.label || '')}</b>${esc(p.text || '')}</div>`).join('');
  const signs = asArray(doc.signature).map((s) => `<div><span>${esc(s[0])}</span>${esc(s[1])}</div>`).join('');
  const seal = doc.seal && (doc.seal.top || doc.seal.bottom) ? `<div class="pp-seal"><span class="s-top">${esc(doc.seal.top || '')}</span><span class="s-star">★</span><span class="s-office">${esc(doc.seal.bottom || '')}</span><span class="s-date">${esc(doc.seal.date || '')}</span></div>` : '';
  return `<div id="doc-preview" class="${styleClass}" style="background-color:${st.bg}">
    ${band}
    ${doc.org ? `<div class="pp-org">${esc(doc.org)}</div>` : ''}
    <div class="pp-title">${esc(doc.title || '未命名材料')}</div>
    ${doc.subtitle ? `<div class="pp-sub">${esc(doc.subtitle)}</div>` : ''}
    <div class="pp-rule"></div>
    ${fields ? `<div class="pp-fields">${fields}</div>` : ''}
    ${stats ? `<div class="pp-stats">${stats}</div>` : ''}
    ${table}
    ${paras}
    ${signs ? `<div class="pp-sign">${signs}</div>` : ''}
    ${doc.note ? `<div class="pp-note">${esc(doc.note)}</div>` : ''}
    ${seal}
    <div class="pp-foot"><span>MINGZHOU UNIVERSITY · 材料存档</span><span>${esc(doc.ref || '')}</span></div>
  </div>`;
}


function refreshPreview() {
  const holder = $('#doc-preview');
  if (!holder) return;
  const doc = selTask()?.documents?.[state.selectedDoc];
  if (!doc) return;
  holder.outerHTML = paperPreview(previewDoc(doc));
}


Object.assign(env.api, { viewTasks, docCard, docEditor, previewTokens, fillTokens, previewDoc, paperPreview, refreshPreview });
};
