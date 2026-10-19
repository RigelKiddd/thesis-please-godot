/* Composition root. Feature modules own their state transitions and views. */
'use strict';
const editorEnv = { model: globalThis.ThesisEditor.model, api: {} };
for (const create of Object.values(globalThis.ThesisEditor.factories)) create(editorEnv);
const editor = editorEnv.api;
document.addEventListener('DOMContentLoaded', () => {
  editor.bindGlobalEvents();
  editor.boot();
});
document.addEventListener('input', (event) => {
  if (event.target.matches('[data-override]')) editor.applyOverride(event.target);
});
window.__editor = { ...editor, state: editorEnv.model.state };
if (location.protocol === 'file:') {
  document.addEventListener('DOMContentLoaded', () => {
    setTimeout(() => {
      if (!editorEnv.model.state.loaded) editor.toast('直接打开 HTML 时，请用“选择项目文件夹”载入 content/', 'warn');
    }, 500);
  });
}
