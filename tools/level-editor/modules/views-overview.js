/* views-overview: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-overview'] = function (env) {
'use strict';
const { $, $$, esc, asArray, num, STYLE_ORDER, TASK_KINDS, state } = env.model;
const bindLogicCanvas = (...args) => env.api.bindLogicCanvas(...args);
const cases = (...args) => env.api.cases(...args);
const chains = (...args) => env.api.chains(...args);
const characterForSlot = (...args) => env.api.characterForSlot(...args);
const characters = (...args) => env.api.characters(...args);
const content = (...args) => env.api.content(...args);
const levels = (...args) => env.api.levels(...args);
const portraitPath = (...args) => env.api.portraitPath(...args);
const selLevel = (...args) => env.api.selLevel(...args);
const taskForSlot = (...args) => env.api.taskForSlot(...args);
const tasks = (...args) => env.api.tasks(...args);
const touch = (...args) => env.api.touch(...args);
const validateProject = (...args) => env.api.validateProject(...args);
const viewCharacters = (...args) => env.api.viewCharacters(...args);
const viewLogic = (...args) => env.api.viewLogic(...args);
const viewPublish = (...args) => env.api.viewPublish(...args);
const viewStyles = (...args) => env.api.viewStyles(...args);
const viewTasks = (...args) => env.api.viewTasks(...args);

function render() {
  if (!state.loaded) {
    renderWelcome();
    updateChrome();
    return;
  }
  state.validation = validateProject();
  updateChrome();
  const view = $('#view');
  switch (state.view) {
    case 'levels': view.innerHTML = viewLevels(); bindSlotDrag(); break;
    case 'characters': view.innerHTML = viewCharacters(); break;
    case 'tasks': view.innerHTML = viewTasks(); break;
    case 'logic': view.innerHTML = viewLogic(); bindLogicCanvas(); break;
    case 'styles': view.innerHTML = viewStyles(); break;
    case 'publish': view.innerHTML = viewPublish(); break;
    default: view.innerHTML = viewOverview(); break;
  }
  refreshHealth();
  window.scrollTo({ top: 0 });
}


function renderWelcome() {
  $('#view').innerHTML = `
    <div class="empty" style="margin-top:8vh;padding:48px 32px">
      <b>还没有载入内容</b>
      浏览器不会自动读取本地目录。请选择项目根目录（含 <code>content/</code> 与 <code>assets/</code>），
      或者用本地服务器打开这个页面。<br />
      直接双击 HTML 时，也可以用“选择 content 文件”手动载入 content JSON（logic.json 可选）。
      <div class="row" style="justify-content:center;margin-top:18px">
        <button class="btn primary" data-action="open-folder">选择项目文件夹</button>
        <button class="btn" data-action="open-files">选择 content 文件</button>
        <button class="btn ghost" data-action="load-fetch">从 content/ 读取</button>
        <button class="btn ghost" data-action="show-help">使用说明</button>
      </div>
    </div>`;
}


function updateChrome() {
  $$('.nav-item').forEach((el) => el.classList.toggle('active', el.dataset.nav === state.view));
  $('#nav-level-count').textContent = state.loaded ? levels().length : '—';
  $('#nav-character-count').textContent = state.loaded ? characters().length : '—';
  $('#nav-task-count').textContent = state.loaded ? tasks().length : '—';
  $('#nav-logic-count').textContent = state.loaded ? chains().length : '—';
  $('#nav-style-count').textContent = STYLE_ORDER.length;
  $('#nav-overview-count').textContent = state.loaded ? levels().length : '';
  $('#side-chars').textContent = state.loaded ? characters().length : '—';
  $('#side-cases').textContent = state.loaded ? cases().length : '—';
  $('#side-levels').textContent = state.loaded ? levels().length : '—';
  $('#side-tasks').textContent = state.loaded ? tasks().length : '—';
  $('#side-logic').textContent = state.loaded ? chains().length : '—';
  const issueCount = state.validation.errors.length + state.validation.warnings.length;
  $('#nav-issue-count').textContent = state.loaded ? (issueCount || '0') : '—';
  const sideIssues = $('#side-issues');
  sideIssues.textContent = state.loaded ? (issueCount ? `${state.validation.errors.length} 错 / ${state.validation.warnings.length} 警` : '通过') : '—';
  sideIssues.className = issueCount ? 'bad' : 'ok';
  const title = state.loaded ? (state.content.levelsDoc.chapter?.title || '未命名章节') : '未载入';
  $('#project-title').textContent = title;
  $('#save-state').textContent = state.loaded ? (state.dirty ? `未保存 · ${state.source}` : `已保存 · ${state.source}`) : '未载入';
  $('#dirty-dot').classList.toggle('on', state.dirty);
  if (state.loaded) document.title = `${title} · 论文审批处关卡编辑器`;
}


function refreshHealth() {
  const issueCount = state.validation.errors.length + state.validation.warnings.length;
  const sideIssues = $('#side-issues');
  if (sideIssues) {
    sideIssues.textContent = issueCount ? `${state.validation.errors.length} 错 / ${state.validation.warnings.length} 警` : '通过';
    sideIssues.className = issueCount ? 'bad' : 'ok';
  }
  const navIssues = $('#nav-issue-count');
  if (navIssues) navIssues.textContent = issueCount || '0';
  $('#side-chars').textContent = state.loaded ? characters().length : '—';
  $('#side-cases').textContent = state.loaded ? cases().length : '—';
  $('#side-levels').textContent = state.loaded ? levels().length : '—';
  $('#side-tasks').textContent = state.loaded ? tasks().length : '—';
  $('#side-logic').textContent = state.loaded ? chains().length : '—';
}


function daysWithTasks() {
  return levels().reduce((acc, lv) => acc + asArray(lv.queue).filter((s) => s.taskId).length, 0);
}


function dayIssues(index) {
  const path = `levels:${index}`;
  return [...state.validation.errors, ...state.validation.warnings].filter((issue) => issue.path === path);
}


function viewOverview() {
  const totalDocs = tasks().reduce((acc, tk) => acc + asArray(tk.documents).length, 0);
  const taskSlots = daysWithTasks();
  const issueCount = state.validation.errors.length + state.validation.warnings.length;
  const dayCards = levels().map((lv, index) => {
    const queue = asArray(lv.queue);
    const taskCount = queue.filter((s) => s.taskId).length;
    return `
      <button class="day-card" data-action="select-level" data-index="${index}">
        <div class="dc-top">
          <span class="dc-day">DAY ${String(lv.day || index + 1).padStart(2, '0')}</span>
          <span class="dc-date">${esc(lv.date)}</span>
        </div>
        <div class="dc-theme">${esc(lv.theme || lv.weekday || '未命名')}</div>
        <div class="dc-queue">
          ${queue.map((slot) => {
            const ch = characterForSlot(slot);
            const task = taskForSlot(slot);
            return `<span class="dc-student ${task ? 'has-task' : ''}"><i></i>${esc(ch?.name || '—')}</span>`;
          }).join('')}
        </div>
        <div class="dc-task">${taskCount ? `<span class="lock">待办</span>${taskCount} 份当面材料` : '无待办'}</div>
      </button>`;
  }).join('');
  const issues = [...state.validation.errors, ...state.validation.warnings].slice(0, 6);
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">CONTENT WORKBENCH / WEEK 01</div>
        <h1 class="view-title">内容总览</h1>
        <div class="view-sub">人物、论文案例、每日队列和当面待办统一放在这里。先看流程，再逐项编辑；所有内容都可回到 content/ 的模块文件。</div>
      </div>
      <div class="view-actions">
        <button class="btn" data-action="edit-chapter">章节信息</button>
        <button class="btn ghost" data-action="save-all">保存全部</button>
        <button class="btn primary" data-action="export-game">导出游戏数据</button>
      </div>
    </div>

    <div class="overview-hero">
      <div class="hero-copy">
        <h2>${esc(state.content.levelsDoc.chapter?.title || '第一周')} · 模块化关卡</h2>
        <p>一关是一天的队列，队列位置绑定人物、论文案例和一个可选的待办包。待办包只在对应学生轮到窗口时出现，材料会进入“其他材料”，办结后才能往下一位。</p>
        <div class="hero-actions">
          <button class="btn primary" data-action="select-level" data-index="${state.selectedLevel}">打开当前关卡</button>
          <button class="btn" data-action="add-level">新增关卡</button>
          <button class="btn ghost" data-action="show-help">字段说明</button>
        </div>
      </div>
      <div class="stat-grid">
        <div class="stat"><b>${levels().length}</b><span>关卡 / DAYS</span><em>队列与元数据</em></div>
        <div class="stat"><b>${characters().length}</b><span>人物 / CHARACTERS</span><em>名字与学籍统一</em></div>
        <div class="stat"><b>${cases().length}</b><span>案例 / CASES</span><em>论文与审查数据</em></div>
        <div class="stat"><b>${tasks().length}</b><span>待办包 / PACKETS</span><em>${totalDocs} 份材料 · ${taskSlots} 个挂接</em></div>
      </div>
    </div>

    <div class="panel">
      <div class="panel-head">
        <h3>七日流程</h3>
        <span class="hint">点击某一天进入关卡编辑 · 红色圆点表示该位置有待办</span>
      </div>
      <div class="timeline">${dayCards}</div>
    </div>

    <div class="content-split">
      <div class="panel">
        <div class="panel-head">
          <h3>内容健康</h3>
          <span class="hint">${issueCount ? '先处理阻断项' : '没有发现问题'}</span>
          <button class="link-btn" data-action="run-validation" style="margin-left:auto">重新校验 →</button>
        </div>
        <div class="issue-list">
          ${issues.length ? issues.map(issueRow).join('') : '<div class="check-row">所有模块通过基础校验。</div>'}
        </div>
      </div>
      <div class="panel">
        <div class="panel-head"><h3>制作节奏</h3></div>
        <ol class="publish-steps">
          <li>人物页改名字、学号、专业与立绘；封面和查重报告身份由构建自动派生。</li>
          <li>关卡页调整队列顺序，给某一位学生挂上待办包。</li>
          <li>待办包页编排材料顺序与纸张样式，写清办理依据。</li>
          <li>保存后运行 <code>content_tools.py build</code>，游戏读取 assets。</li>
        </ol>
      </div>
    </div>`;
}


function issueRow(issue, index) {
  const sev = issue.severity === 'error' ? 'err' : 'warn';
  return `<button class="issue ${sev}" data-action="goto-issue" data-path="${esc(issue.path || '')}">
    <b>${issue.severity === 'error' ? '阻断' : '提醒'}</b><span>${esc(issue.text)}</span><em>${esc(issue.path || '')}</em>
  </button>`;
}


function viewLevels() {
  const lv = selLevel();
  if (!lv) return '<div class="empty"><b>还没有关卡</b>从“新增关卡”开始。</div>';
  const list = levels().map((day, index) => {
    const taskCount = asArray(day.queue).filter((s) => s.taskId).length;
    const bad = dayIssues(index).length;
    return `<button class="level-tab ${index === state.selectedLevel ? 'active' : ''}" data-action="select-level" data-index="${index}">
      <div class="lt-day">${String(day.day || index + 1).padStart(2, '0')}</div>
      <div class="lt-main">
        <div class="lt-date">${esc(day.date)} · ${esc(day.weekday || '')}</div>
        <div class="lt-theme">${esc(day.theme || '未命名关卡')}</div>
        <div class="lt-meta">${asArray(day.queue).length} 位学生 · ${taskCount} 份待办</div>
      </div>
      ${bad ? '<i class="lt-bad"></i>' : ''}
    </button>`;
  }).join('');

  const queue = asArray(lv.queue).map((slot, index) => slotRow(slot, index)).join('');
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">LEVEL / DAY ${String(lv.day || state.selectedLevel + 1).padStart(2, '0')}</div>
        <h1 class="view-title">${esc(lv.theme || '关卡')}</h1>
        <div class="view-sub">${esc(lv.date)} · ${esc(lv.weekday)} · 队列 ${asArray(lv.queue).length} 位。拖动左侧手柄可重排；待办会锁定该学生，直到当面办结。</div>
      </div>
      <div class="view-actions">
        <button class="btn ghost" data-action="duplicate-level">复制关卡</button>
        <button class="btn ghost" data-action="add-level">新增关卡</button>
        <button class="btn warn small" data-action="delete-level">删除</button>
      </div>
    </div>
    <div class="level-layout">
      <div class="level-list">${list}</div>
      <div>
        <div class="panel level-meta">
          <div class="panel-head"><h3>关卡元数据</h3><span class="hint">day / notice 会进入每日通报与存档</span></div>
          <div class="grid four">
            <div class="field"><label>ID</label><input type="text" data-scope="level" data-key="id" value="${esc(lv.id)}" /></div>
            <div class="field"><label>第几天</label><input type="number" min="1" data-scope="level" data-key="day" value="${num(lv.day, 1)}" /></div>
            <div class="field"><label>日期</label><input type="text" data-scope="level" data-key="date" value="${esc(lv.date)}" placeholder="2026.05.11" /></div>
            <div class="field"><label>星期</label><input type="text" data-scope="level" data-key="weekday" value="${esc(lv.weekday)}" /></div>
            <div class="field"><label>短日期</label><input type="text" data-scope="level" data-key="shortDate" value="${esc(lv.shortDate)}" placeholder="5月11日" /></div>
            <div class="field"><label>主题</label><input type="text" data-scope="level" data-key="theme" value="${esc(lv.theme)}" placeholder="摘要审查" /></div>
            <div class="field span-2"><label>当日通报</label><input type="text" data-scope="level" data-key="notice" value="${esc(lv.notice)}" /></div>
          </div>
        </div>
        <div class="panel">
          <div class="queue-head">
            <h3>队列模块</h3>
            <span class="badge">${asArray(lv.queue).length} 位</span>
            <span class="badge red">${asArray(lv.queue).filter((s) => s.taskId).length} 份待办</span>
            <div class="spacer"></div>
            <button class="btn" data-action="add-slot">+ 添加学生</button>
          </div>
          <div class="slot-list" id="slot-list">
            ${queue || '<div class="empty" style="padding:18px">队列为空。添加人物后会在这里形成当天的顺序。</div>'}
          </div>
          <div class="flow-preview">
            <div class="section-title" style="font-size:13px">当日流程预览 <small>红色 ✋ 表示该位置有当面待办</small></div>
            <div class="flow-strip">
              ${asArray(lv.queue).map((slot, index) => {
                const ch = characterForSlot(slot);
                const task = taskForSlot(slot);
                return `${index ? '<span class="flow-arrow">→</span>' : ''}<span class="flow-node ${task ? 'task' : ''}"><span class="n">${String(index + 1).padStart(2, '0')}</span>${esc(ch?.name || '—')}${task ? ' ✋' : ''}</span>`;
              }).join('') || '<span class="muted">空队列</span>'}
            </div>
          </div>
        </div>
      </div>
    </div>`;
}


function slotRow(slot, index) {
  const ch = characterForSlot(slot);
  const task = taskForSlot(slot);
  const usedChars = new Set(asArray(selLevel().queue).map((s) => s.characterId));
  const charOptions = characters().map((c) => `<option value="${esc(c.id)}" ${c.id === slot.characterId ? 'selected' : ''}>${esc(c.name)}${usedChars.has(c.id) && c.id !== slot.characterId ? '（已在队列）' : ''}</option>`).join('');
  const caseOptions = cases().map((c) => `<option value="${esc(c.id)}" ${c.id === slot.caseId ? 'selected' : ''}>${esc(c.title || c.id)}</option>`).join('');
  const taskOptions = [`<option value="">— 无待办 —</option>`].concat(tasks().map((t) => `<option value="${esc(t.id)}" ${t.id === slot.taskId ? 'selected' : ''}>${esc(t.title)}（${esc(TASK_KINDS[t.kind]?.label || t.kind)}）</option>`)).join('');
  return `<div class="slot ${task ? 'has-task' : ''}" data-slot-index="${index}">
    ${task ? '<span class="slot-flag">待办</span>' : ''}
    <span class="drag-handle" draggable="true" data-drag-handle="${index}" title="拖动排序">⋮⋮</span>
    <img class="portrait" src="${portraitPath(ch)}" alt="" onerror="this.style.visibility='hidden'" />
    <div>
      <div class="slot-name">${String(index + 1).padStart(2, '0')} · ${esc(ch?.name || '未知人物')}</div>
      <div class="slot-sub">${esc(ch?.studentNo || '')} · ${esc(ch?.major || '')}</div>
      <div class="slot-sub">${esc(ch?.clazz || '')}</div>
    </div>
    <div>
      <div class="slot-field-cap">人物</div>
      <select data-slot-character="${index}" title="更换该位置的人物">${charOptions}</select>
      <div class="slot-field-cap" style="margin-top:3px">案例</div>
      <select data-slot-case="${index}" title="更换该位置的论文案例">${caseOptions}</select>
    </div>
    <div class="slot-task">
      <div class="slot-field-cap">待办</div>
      <select data-slot-task="${index}" title="挂接一个当面待办包">${taskOptions}</select>
    </div>
    <div class="slot-actions">
      <button class="btn icon" data-action="move-slot-up" data-index="${index}" title="上移" ${index === 0 ? 'disabled' : ''}>↑</button>
      <button class="btn icon" data-action="move-slot-down" data-index="${index}" title="下移" ${index === asArray(selLevel().queue).length - 1 ? 'disabled' : ''}>↓</button>
      <button class="btn icon" data-action="duplicate-slot" data-index="${index}" title="复制">⧉</button>
      <button class="btn icon" data-action="delete-slot" data-index="${index}" title="删除">×</button>
    </div>
  </div>`;
}


function bindSlotDrag() {
  $$('#slot-list .drag-handle').forEach((handle) => {
    handle.addEventListener('dragstart', (event) => {
      state.dragSlot = num(handle.dataset.dragHandle, 0);
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', String(state.dragSlot));
    });
  });
  $$('#slot-list .slot').forEach((slot) => {
    slot.addEventListener('dragover', (event) => {
      event.preventDefault();
      slot.classList.add('drag-over');
    });
    slot.addEventListener('dragleave', () => slot.classList.remove('drag-over'));
    slot.addEventListener('drop', (event) => {
      event.preventDefault();
      slot.classList.remove('drag-over');
      const to = num(slot.dataset.slotIndex, 0);
      reorderSlot(state.dragSlot, to);
      state.dragSlot = -1;
    });
  });
}


function reorderSlot(from, to) {
  const queue = asArray(selLevel().queue);
  if (from < 0 || to < 0 || from >= queue.length || to >= queue.length || from === to) return;
  const [item] = queue.splice(from, 1);
  queue.splice(to, 0, item);
  touch();
  render();
}


Object.assign(env.api, { render, renderWelcome, updateChrome, refreshHealth, daysWithTasks, dayIssues, viewOverview, issueRow, viewLevels, slotRow, bindSlotDrag, reorderSlot });
};
