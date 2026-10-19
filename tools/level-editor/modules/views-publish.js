/* views-publish: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-publish'] = function (env) {
'use strict';
const { $, esc, asArray, STYLE_DEFS, STYLE_ORDER, STYLE_TEXTURE, state } = env.model;
const cases = (...args) => env.api.cases(...args);
const characters = (...args) => env.api.characters(...args);
const compileProject = (...args) => env.api.compileProject(...args);
const content = (...args) => env.api.content(...args);
const daysWithTasks = (...args) => env.api.daysWithTasks(...args);
const hasAutosave = (...args) => env.api.hasAutosave(...args);
const levels = (...args) => env.api.levels(...args);
const tasks = (...args) => env.api.tasks(...args);

function viewStyles() {
  const counts = {};
  tasks().forEach((tk) => asArray(tk.documents).forEach((d) => { counts[d.style] = (counts[d.style] || 0) + 1; }));
  const cards = STYLE_ORDER.map((id) => {
    const st = STYLE_DEFS[id];
    return `<div class="stock-card">
      <div class="stock-swatch" style="background-image:url('../../assets/textures/paper_${STYLE_TEXTURE[id] || 'certificate'}.png');background-color:${st.bg};color:${st.accent}">
        <b>${st.label}</b><span>${st.en}</span>
      </div>
      <div class="stock-meta">
        ${st.desc}
        <div class="row" style="margin-top:6px"><span class="badge">${counts[id] || 0} 份在用</span><span class="badge" style="border-color:${st.border};color:${st.border}">${st.accent}</span></div>
      </div>
    </div>`;
  }).join('');
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">ART DIRECTION / PAPER STOCKS</div>
        <h1 class="view-title">纸张与字体样式</h1>
        <div class="view-sub">${STYLE_ORDER.length} 种纸张共用“纸色 + 墨色 + 红章”的既有美术风格，通过纸纹、边框、抬头、字体与印章位置区分；新增学生证、身份证、奖学金、录取通知、财务台账、档案卡、护照页、登机牌。编辑器里的预览只做结构校验，最终以游戏内渲染为准。</div>
      </div>
    </div>
    <div class="stock-grid">${cards}</div>
    <div class="panel" style="margin-top:16px">
      <div class="panel-head"><h3>排版令牌</h3><span class="hint">游戏内字号会跟随玩家设置的 100% / 115% / 125% 放大</span></div>
      <div class="token-grid">
        <div class="token"><b>21 / 19</b><span>材料主标题 · 衬线粗体</span><div class="sw" style="background:#3b2d1e"></div></div>
        <div class="token"><b>16</b><span>数值 / 绩点 · 衬线</span><div class="sw" style="background:#8a6a32"></div></div>
        <div class="token"><b>9.5</b><span>正文 / 字段 · 宋体</span><div class="sw" style="background:#e7dcbc"></div></div>
        <div class="token"><b>7</b><span>编号 / 页脚 · 像素字</span><div class="sw" style="background:#a83a2f"></div></div>
      </div>
    </div>
    <div class="panel">
      <div class="panel-head"><h3>风格约束</h3></div>
      <ol class="publish-steps">
        <li>纸张沿用现有纹理与配色体系；新增证件/证书样式只改变抬头、栏线和纸色，不引入高饱和渐变或圆角卡片。</li>
        <li>标题用衬线，编号/小标签用像素感字体；正文保持深墨色。</li>
        <li>红色只用于印章、退回、关键错误；绿色只用于批准与通过。</li>
        <li>公示类材料用黑灰油印，不使用烫金边；证书类才用金色双线。</li>
        <li>印章压住签名或数据是允许的，但不要遮住玩家判断所需的绩点、公示期与排序。</li>
      </ol>
    </div>`;
}


function viewPublish() {
  const all = [...state.validation.errors, ...state.validation.warnings];
  const compiled = compileProject();
  const docs = tasks().reduce((acc, tk) => acc + asArray(tk.documents).length, 0);
  return `
    <div class="view-head">
      <div>
        <div class="view-kicker">VALIDATE / BUILD / SHIP</div>
        <h1 class="view-title">校验与发布</h1>
        <div class="view-sub">保存只写 content/ 模块文件；导出游戏数据会编译成 assets/data.json 与 assets/requests.json。两者都通过后再运行测试。</div>
      </div>
      <div class="view-actions">
        <button class="btn" data-action="run-validation">重新校验</button>
        ${hasAutosave() ? '<button class="btn ghost" data-action="restore-autosave">恢复自动保存</button>' : ''}
        <button class="btn primary" data-action="save-all">保存 content</button>
        <button class="btn" data-action="export-game" ${all.some((i) => i.severity === 'error') ? 'disabled' : ''}>导出游戏数据</button>
      </div>
    </div>
    <div class="publish-grid">
      <div class="panel">
        <div class="panel-head"><h3>校验结果</h3><span class="hint">${state.validation.errors.length} 个阻断 · ${state.validation.warnings.length} 个提醒</span></div>
        <div class="check-list">
          ${all.length ? all.map((issue) => `<button class="check-row ${issue.severity === 'error' ? 'err' : 'warn'}" data-action="goto-issue" data-path="${esc(issue.path || '')}"><span class="tag">${issue.severity === 'error' ? '阻断' : '提醒'}</span><span>${esc(issue.text)}</span><span class="path">${esc(issue.path || '')}</span></button>`).join('') : '<div class="check-row">全部通过。可以保存并构建。</div>'}
        </div>
      </div>
      <div class="panel">
        <div class="panel-head"><h3>构建摘要</h3></div>
        <div class="kv-list">
          <div class="kv"><span>章节</span><b>${esc(state.content.levelsDoc.chapter?.title || '—')}</b></div>
          <div class="kv"><span>关卡 / 学生</span><b>${levels().length} / ${levels().reduce((a, lv) => a + asArray(lv.queue).length, 0)}</b></div>
          <div class="kv"><span>人物 / 案例</span><b>${characters().length} / ${cases().length}</b></div>
          <div class="kv"><span>待办包 / 材料</span><b>${tasks().length} / ${docs}</b></div>
          <div class="kv"><span>挂接待办</span><b>${daysWithTasks()} 处</b></div>
          <div class="kv"><span>编译结果</span><b>${compiled.errors.length ? '有阻断，未编译' : '可编译'}</b></div>
        </div>
        <div style="margin-top:12px">
          <div class="section-title" style="font-size:13px">发布命令</div>
          <div class="code-block">python tools/project.py build
python tools/project.py test
python tools/project.py release</div>
        </div>
      </div>
    </div>
    <div class="panel">
      <div class="panel-head"><h3>模块文件</h3><span class="hint">content/ 是源文件；assets/ 是编译产物</span></div>
      <div class="grid two">
        <div>
          <div class="section-title" style="font-size:13px">保存 content/</div>
          <p class="form-note">保存全部会写入 5 个模块文件。如果没有选择项目文件夹，浏览器会下载它们。</p>
          <div class="code-block">content/
  world.json      规则、页签、夜班、结局
  characters.json 人物与立绘
  cases.json      论文案例与审查数据
  levels.json     每日队列与待办挂接
  tasks.json      当面材料包</div>
        </div>
        <div>
          <div class="section-title" style="font-size:13px">导出 assets/</div>
          <p class="form-note">编辑器会合并人物与案例、重算队列顺序，并输出游戏运行时读取的两个文件。</p>
          <div class="code-block">assets/
  data.json       DAYS / RULES / TABS / NIGHT
  requests.json   当日待办与材料包</div>
        </div>
      </div>
    </div>`;
}


Object.assign(env.api, { viewStyles, viewPublish });
};
