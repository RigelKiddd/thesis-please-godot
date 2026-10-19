# 关卡编辑器 / Content Workbench

《论文审批处》的本地内容工具。用来统一管理人物、论文案例、每日队列、“当面待办包”，
以及可视化条件链；并把内容编译成游戏运行时读取的 `assets/data.json` 与 `assets/requests.json`。

- 纯 HTML / CSS / JS，无第三方依赖，不上传任何内容。
- 数据源：项目根目录的 `content/` 五个构建模块 + `logic.json`（编辑器侧条件链，暂不编译进游戏）。
- 运行时产物：`assets/data.json`、`assets/requests.json`。
- 推荐浏览器：Chrome / Edge 最新版（需要文件夹读写时使用 File System Access API）。

## 打开方式

### 1. 本地服务器（最稳定）

在项目根目录运行：

```powershell
python -m http.server 8899
```

然后打开：

```text
http://127.0.0.1:8899/tools/level-editor/
```

页面会自动读取 `content/*.json`。这种模式下“保存全部”会下载 JSON 文件，
“导出游戏数据”会下载 `data.json` / `requests.json`；把下载文件覆盖回对应目录即可。

也可以直接运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/open_level_editor.ps1
```

脚本会在本机 8899 端口启动服务并打开浏览器。

### 2. 选择项目文件夹（可直接写回）

用 Chrome / Edge 打开 `tools/level-editor/index.html`，点击“打开项目”，
选择项目根目录（包含 `content/` 与 `assets/`）。浏览器授权后：

- “保存全部”直接写回 `content/` 五个构建文件 + `logic.json`；
- “导出游戏数据”直接写回 `assets/data.json`、`assets/requests.json`。

如果浏览器不支持文件夹选择，工具会退回“选择 content 文件”或下载模式。

## 内容模块

| 文件 | 内容 | 谁在读取 |
|---|---|---|
| `content/world.json` | 审查条例、页签、额外材料、结局、夜班、历史审计 | 构建器 |
| `content/characters.json` | 人物姓名、学号、学院、专业、班级、导师、立绘、外观 | 构建器 + 关卡 |
| `content/cases.json` | 论文题目、摘要、关键词、参考文献、查重、审查表、正文 | 构建器 + 关卡 |
| `content/levels.json` | 每日元数据 + 有序队列（人物 + 案例 + 待办） | 构建器 |
| `content/tasks.json` | 待办包：办理依据、材料文档、正确结论、批准/退回文本 | 构建器 |
| `content/logic.json` | 条件链：节点、比较、ALL/ANY/NOT、结果 | 仅编辑器（暂不接入游戏） |

运行时仍读取 `assets/`，所以编辑完 content 后必须构建：

```powershell
python tools/content_tools.py check
python tools/content_tools.py build
```

`check` 会校验 content 并确认 `assets/` 不是旧版本；`build` 才会真正写入。

## 核心概念

### 人物（Character）

人物的身份字段是唯一来源。构建时：

- `official` 由人物生成；
- `cover` 使用人物身份 + 案例题目；
- `dup`（查重报告）使用人物姓名/学号。

如果某个案例需要故意写错（审查缺陷），在人物页“个案覆盖”里固定旧值。
这样改名不会破坏原本设计好的错误。

### 案例（Case）

一个案例对应一套论文审查数据：题目、摘要字数、关键词、参考文献、查重率、
签字、学分、学费、正文页数等。关卡位置通过 `caseId` 引用案例。

### 学生消息（微信）

在“人物 → 论文案例”底部：

- **主消息**写学生递材料时的第一句；
- **自定义消息序列**每行一条；留空则由缺陷自动生成 3 条；
- 自定义序列只覆盖聊天内容，不改变缺陷、固定三选一回复和批准/退回判定；
- 有缺陷时仍会出现一次手动回复；消息会进入夜班来信的摘要。

#### 对话树（自定义分支）

对话树存在时**完全优先于**上面的快捷消息：

- 节点字段：`id`、`speaker`、`text`、`next`、`choices`；
- 说话人：学生 / 我（老师）/ 自动回复 / 系统旁白；
- 每个节点最多 4 个回复选项，选项有文字、下一节点、夜信样式、省时分钟；
- `next` 可以指向任意节点，因此支持“选项 → 后续选项 → 再分支”；
- 右侧有当前路径预览；支持新建、从自动消息生成、增删节点/选项、START 选择、说话人/目标/延迟编辑；
- 发布前校验 START、重复 ID、悬空引用、空选项、超过 4 项；
- 游戏内到达选项节点才显示回复按钮，选完沿分支继续，结束后提示可盖章。
- 截图：`screenshots/81-editor-dialogue.png`、`79-chat-dialogue-choices.png`、`80-chat-dialogue-followup.png`。

### 关卡（Level）

一天 = 一个关卡，包含：

```json
{
  "id": "level-2",
  "day": 2,
  "date": "2026.05.12",
  "weekday": "周二",
  "theme": "摘要规格",
  "notice": "……",
  "queue": [
    { "characterId": "char-2022010516", "caseId": "case-2022010516", "taskId": "scholarship-d2-incentive" }
  ]
}
```

`queue` 的顺序就是学生进入窗口的顺序。拖动左侧 `⋮⋮` 手柄可以重排。
`taskId` 挂上待办包后，游戏里这位学生轮到窗口时会当面递材料；办结前不能盖下一位。

### 待办包（Task Packet）

```json
{
  "id": "scholarship-d2-incentive",
  "kind": "scholarship",
  "variant": "国家励志",
  "expected": "return",
  "criteria": ["学年绩点不低于 3.5", "班级公示满 3 个工作日"],
  "documents": [
    { "id": "transcript", "style": "sealed", "kind": "transcript", "tab": "成绩单", "title": "……" }
  ],
  "approveText": "……",
  "returnText": "……"
}
```

材料文档的 `style` 决定纸张与排版：

| style | 样式 | 适用 |
|---|---|---|
| `certificate` | 棉纸证书、金色双线 | 申请表、认定表、名额核定 |
| `sealed` | 密封存档、红色双线、圆章 | 成绩单、查重报告 |
| `mimeo` | 油印公示、黑灰、无装饰边 | 班级公示、课程冲突核查 |
| `carbonless` | 蓝色复写纸、虚线撕口 | 请假条、困难认定、家长记录 |
| `cardstock` | 牛皮卡纸、深红抬头带 | 优毕推荐表、预约单 |
| `student_id` | 学生证、冷青证件带 | 校园卡、学生证、考试证 |
| `id_card` | 身份证/证件卡、浅蓝底 | 身份证、临时通行证 |
| `scholarship` | 奖学金证书、金线 | 国家/校级奖学金、荣誉证书 |
| `admission` | 录取通知、绿色信头 | 国内外大学 offer / 录取通知 |
| `ledger` | 财务/助学金台账 | 学费、住宿费、助学金发放 |
| `index_card` | 档案/图书馆索引卡 | 学籍档案、图书借阅 |
| `passport` | 护照/签证页、深蓝证件带 | 护照资料页、签证、出入境 |
| `boarding` | 登机牌/凭证、虚线撕口 | 登机牌、车票、预约凭证 |

`documents` 的文本支持占位符，构建后按当天学生填充：

`{{name}}` `{{studentId}}` `{{major}}` `{{clazz}}` `{{college}}` `{{advisor}}`
`{{cover_title}}` `{{dup_rate}}` `{{form_rate}}` `{{dayDate}}`

### 条件链（Logic Chain，编辑器侧）

`content/logic.json` 保存可视化判断链。当前**不编译进游戏**，只用于先把分支逻辑做出来。

- 节点：`start` / `condition` / `all` / `any` / `not` / `set` / `result`。
- 比较：`== != > >= < <= contains startsWith in truthy`。
- 组合：ALL（全部满足）、ANY（任一满足）、NOT（取反），每组可加多条条件。
- 结果：approve / return / reject / flag。
- 编辑：拖动节点；点节点在右侧改字段、比较值、TRUE/FALSE 连接；也可以点输出口再点目标节点直接连线。
- 画布：滚轮滚动，`Ctrl+滚轮` 缩放；拖空白平移；右下 minimap 点击跳节点。
- 批量：`Shift/Ctrl` 点选多个节点，复制/粘贴/删除；`Ctrl+Z` 撤销、`Ctrl+Y` 重做。
- 布局：自动布局按链深度排节点；
- 搜索：顶部可按链名或节点/字段定位；
- 校验：错误节点红框 + `!` 角标；发布页点错误会跳到对应链/节点。
- 试算：顶部上下文填字段值，点“运行判断链”查看经过的节点与结果；这仅是编辑器预览。

```json
{
  "id": "scholarship-basic",
  "entry": "start",
  "nodes": [
    { "id": "start", "type": "start", "x": 60, "y": 180, "next": "gpa" },
    { "id": "gpa", "type": "condition", "x": 270, "y": 180,
      "field": "gpa", "op": ">=", "value": "3.5", "true": "rank", "false": "reject" },
    { "id": "rank", "type": "all", "x": 500, "y": 180,
      "conditions": [{ "field": "rank", "op": "<=", "value": "10" }],
      "true": "approve", "false": "reject" },
    { "id": "approve", "type": "result", "x": 760, "y": 120, "result": "approve", "label": "通过" },
    { "id": "reject", "type": "result", "x": 760, "y": 260, "result": "return", "label": "退回" }
  ]
}
```

## 校验规则

发布前会检查：

- 人物 / 案例 / 待办 / 关卡 ID 重复；
- 关卡队列引用不存在的人物、案例或待办；
- 一个待办被挂到多个队列位置；
- 待办没有材料、材料缺少 ID、纸张样式无效；
- 待办正确结论不是 `approve` / `return`；
- 核对项指向不存在的材料；
- 条件链节点 ID 重复、连接指向不存在节点、条件为空、循环、不可达、缺少 START/结果；
- 队列为空、人物缺学号等提醒。

## 发布流程

1. 在编辑器里修改并“保存全部”。
2. 运行 `python tools/content_tools.py check`。
3. 运行 `python tools/content_tools.py build`。
4. 运行 `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`。
5. 需要发布包时再执行 Windows 导出。

编辑器里的“导出游戏数据”与 Python 构建使用同一套合并规则；已有内容在两边编译结果一致。

### 保存前 diff 与自动保存

- “保存全部”先弹出 diff：列出变化的文件、行数增删；确认后才写入目录或下载。
- 没有变化的文件不会重复写出。
- 编辑过程中改动后约 1.4 秒把当前内容写入浏览器 `localStorage`（best-effort）。
- 重新打开后，可在“校验 / 发布”页点“恢复自动保存”；恢复前会确认，且不会自动覆盖当前内容。
- 自动保存只存在本机浏览器，不会上传。

### 纸张缩略图与真实预览

材料编辑区的“纸张样式”下方新增 13 个缩略图按钮；点击即切换样式并刷新右侧真实字段/表格/落款/印章预览。

## 文件

```text
tools/level-editor/
  index.html        页面骨架
  style.css         纸张 / 墨色 / 像素边框的编辑器视觉
  app.js            数据模型、表单、校验、编译、预览
  README.md         本文件
tools/open_level_editor.ps1   本地服务器启动脚本
tools/content_tools.py        content <-> assets 的构建与校验
```

## 已知限制

- 浏览器预览是结构预览，不等同于 Godot 的最终排版；以游戏内截图为准。
- 参考文献、摘要节选等长文本通过“高级 JSON”编辑，没有逐条表格。
- 文件夹写入需要浏览器支持 File System Access API；Firefox 只能下载。
- 直接双击 HTML 不会自动读取本地文件，必须选择文件夹或使用本地服务器。

## 模块维护与校验（2026-10-19）

`app.js` 为组合入口；`modules/` 按状态、文件读写、语义校验、编译和编辑页面分工。
结构图和完整模块表见 `docs/ARCHITECTURE.md`。

结构规则以 `tools/content_schema.json` 为源，变更后运行 `python tools/sync_content_schema.py`。
语义规则变更必须同时更新 `tools/content_contract.py` 与 `modules/contract.js`，并增加共用样例。
运行 `python tests/test_content_contract.py` 比较 Python/编辑器的接受或拒绝结果及编译输出。
保存、导出都会拦截错误；未通过的草稿仍可由浏览器自动保存。
