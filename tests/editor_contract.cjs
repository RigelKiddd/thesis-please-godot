const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const sandbox = {console, document: {title: 'contract test'}, setTimeout, clearTimeout};
vm.createContext(sandbox);
const folder = path.join(root, 'tools/level-editor');
const html = fs.readFileSync(path.join(folder, 'index.html'), 'utf8');
for (const match of html.matchAll(/<script src="(modules\/[^"]+)"/g)) {
  vm.runInContext(fs.readFileSync(path.join(folder, match[1]), 'utf8'), sandbox, {filename: match[1]});
}
const env = {model: sandbox.ThesisEditor.model, api: {}};
for (const factory of Object.values(sandbox.ThesisEditor.factories)) factory(env);
env.model.state.loaded = true;
env.model.state.content = input.project;
const result = {
  dialogue: input.fixtures.dialogue.map(f => env.api.dialogueErrors(f.value)),
  logic: input.fixtures.logic.map(f => env.api.logicErrors(f.value)),
  errors: env.api.validateProject().errors,
  compiled: env.api.compileProject(),
};
process.stdout.write(JSON.stringify(result));
