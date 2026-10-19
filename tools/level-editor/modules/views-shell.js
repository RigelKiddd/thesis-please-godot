/* views-shell: dependencies are explicit in the factory below. */
globalThis.ThesisEditor.factories['views-shell'] = function (env) {
'use strict';
const { $ } = env.model;
const content = (...args) => env.api.content(...args);

function openModal(html) {
  const root = $('#modal-root');
  root.innerHTML = `<div class="modal">${html}</div>`;
  root.classList.add('open');
  root.setAttribute('aria-hidden', 'false');
}


function closeModal() {
  const root = $('#modal-root');
  root.classList.remove('open');
  root.setAttribute('aria-hidden', 'true');
  root.innerHTML = '';
}


function toast(text, kind = 'good') {
  const el = $('#toast');
  el.textContent = text;
  el.className = `toast show ${kind === 'good' ? '' : kind}`;
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => { el.classList.remove('show'); }, 2600);
}


function showWelcome() {
  openModal(`<h3>欢迎使用关卡编辑器</h3>
    <div class="modal-sub">这是《论文审批处》的本地内容工具。它不会上传任何东西。</div>
    <div class="grid two">
      <div class="panel dark" style="box-shadow:none">
        <h3 style="font-family:var(--serif);margin:0 0 6px">推荐：选择项目根目录</h3>
        <p class="form-note" style="color:#b8b19c">选择 <code>D:\\dex\\thesis-please-godot</code>。编辑器会读取 <code>content/</code>，保存时写回，并能导出 <code>assets/</code>。</p>
        <button class="btn primary" data-action="open-folder">选择项目文件夹</button>
      </div>
      <div class="panel dark" style="box-shadow:none">
        <h3 style="font-family:var(--serif);margin:0 0 6px">或用本地服务器</h3>
        <p class="form-note" style="color:#b8b19c">在项目根目录运行下面的命令，然后打开 <code>http://localhost:8765/tools/level-editor/</code>。这种方式只读 content/，保存会下载文件。</p>
        <div class="code-block">python -m http.server 8765</div>
      </div>
    </div>
    <div class="row" style="margin-top:12px">
      <button class="btn" data-action="open-files">选择 content 文件</button>
      <button class="btn ghost" data-action="load-fetch">从 content/ 读取</button>
      <button class="btn ghost" data-action="show-help">使用说明</button>
      <div class="spacer"></div>
      <button class="btn ghost" data-action="close-modal">先看看界面</button>
    </div>`);
}


function showHelp() {
  openModal(`<h3>字段与工作流</h3>
    <div class="modal-sub">数据源是 content/ 下的五个模块；assets/ 只是编译产物。</div>
    <div class="grid two">
      <div>
        <div class="section-title" style="font-size:14px">数据结构</div>
        <div class="kv-list">
          <div class="kv"><span>人物</span><b>姓名、学号、学院、专业、班级、导师、立绘</b></div>
          <div class="kv"><span>案例</span><b>论文题目、摘要、查重、签字、学分、参考文献</b></div>
          <div class="kv"><span>关卡</span><b>一天 + 有序队列，每人绑定人物/案例/待办</b></div>
          <div class="kv"><span>待办包</span><b>办理依据 + 多份材料 + 正确结论</b></div>
          <div class="kv"><span>材料</span><b>纸张样式 + 抬头 + 字段 + 表格 + 印章</b></div>
        </div>
      </div>
      <div>
        <div class="section-title" style="font-size:14px">快捷键</div>
        <div class="kv-list">
          <div class="kv"><span>Ctrl / Cmd + S</span><b>保存全部</b></div>
          <div class="kv"><span>Esc</span><b>关闭弹窗</b></div>
          <div class="kv"><span>队列左手柄</span><b>拖拽排序</b></div>
        </div>
        <div class="section-title" style="font-size:14px;margin-top:12px">发布顺序</div>
        <ol class="publish-steps">
          <li>先看“校验 / 发布”的阻断项。</li>
          <li>保存 content 模块文件。</li>
          <li>导出游戏数据或运行 content_tools.py build。</li>
          <li>运行 tools/run_tests.ps1，检查游戏内截图。</li>
        </ol>
      </div>
    </div>
    <div class="modal-actions"><button class="btn primary" data-action="close-modal">明白了</button></div>`);
}


function showExportModal(compiled) {
  const students = compiled.data.DAYS.reduce((a, day) => a + day.students.length, 0);
  openModal(`<h3>编译完成</h3><div class="modal-sub">运行时数据结构已生成。</div>
    <div class="grid three">
      <div class="stat" style="background:#efe2bf;color:var(--ink);border-color:#17130d"><b style="color:#7f2d26">${compiled.data.DAYS.length}</b><span>DAYS</span></div>
      <div class="stat" style="background:#efe2bf;color:var(--ink);border-color:#17130d"><b style="color:#7f2d26">${students}</b><span>STUDENTS</span></div>
      <div class="stat" style="background:#efe2bf;color:var(--ink);border-color:#17130d"><b style="color:#7f2d26">${compiled.requests.requests.length}</b><span>REQUESTS</span></div>
    </div>
    <div class="modal-actions"><button class="btn ghost" data-action="close-modal">关闭</button></div>`);
}


Object.assign(env.api, { openModal, closeModal, toast, showWelcome, showHelp, showExportModal });
};
