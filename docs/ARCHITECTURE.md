# 项目结构与维护入口

本轮在 v1.13 内容基础上整理结构。现有学生、关卡、任务与纸张数据保持不变。

> **v1.16 追加**：`AllocationView` 的项目框同时处理左键放入/右键取回，硬币托盘只读；`Modals._skin_card()` 是弹框材料层（通知/表单/账本/档案/打卡/便签/黑底），内容仍由各弹框的 `VBox` 负责；`Ui.F_FALLBACK_*` 给六个文本族挂上 291 个补字，字体覆盖扫描为 0 uncovered。存档仍是 v5，没有新增字段。
>
> **v1.17 追加**：`AllocationView` 改为“上排班板 + 下桌子”；`DeskItem` 负责道具纸卡的拖动/展开/收起，`RunState.items` 进入 `day_snapshot()` / `restore_day()`（v5 可选字段，旧档自动补三份基础文件）；`VisitorPortrait` 是来访者占位肖像，`Modals._visitor_items` 提供随附文件选择，`Main._visitor_opt_with_item()` 把递交效果合并进所选拟办。
>
> **v1.18 重排**：`AllocationView` 不再画整块排班板，而是复用主游戏坐标：左上规则书改项目书、中上学籍档案改排班档案、中央卷宗改文件卡、右架改文件目录、右肖像/微信改来访者。`VisitorPortrait` 按控件尺寸比例绘制；`ChatPanel` 增加 `set_header/clear_messages/add_message/add_system`；`Modals.visitor`/`visitor_result` 增加 `compact` 模式，由 `Main._show_modal_left()` 放在左侧，右侧微信/肖像保持可见。
>
> **v1.19 材料化**：新增 `PropMaterial.gd`，为 `favor/college/schedule/letter/pass` 提供纸样（LEDGER/SEALED/CARDSTOCK/CARBONLESS/MIMEO）、`MaterialIcon` 图标、材料编号、色条与材料签。`DeskItem` 的小卡/展开抬头、`AllocationView._refresh_rail` 的目录横卡统一使用这些 trait；老存档缺字段时按 kind 回退，不升存档版本。
>
> **v1.20 去提示/人像**：`AllocationView` 删除“今晚流程”和所有常驻操作提示，底部只留夜次；`DeskView.set_allocation_chrome()` 在排班期间隐藏主游戏队列/印章托盘/裁决条/批注板。`VisitorPortrait` 不再程序绘制纸片人，改为复用 `assets/portraits` 的手绘肖像，做相框/暖色/角贴/来访章/角色印的登记照；`Modals.visitor` 的 compact 表单改为 470 高滚动区。
>
> **v1.21 无弹窗来访**：新增 `scripts/ui/VisitorChat.gd`（741×274），把陈述、来意、拟办行、附件栏、回执都放进同一块面板；选项 hover 用左侧 320px 自定义后果卡，不再使用系统 tooltip。`DeskItem` 增加 `drag_moved/drag_finished` 与 `restore_origin()`，`AllocationView` 把拖入消息面板的坐标转成附件；`Main` 不再调用 `Modals.visitor/visitor_result`，附件/×取消通过 `visitor_item_attached/cleared` 信号同步。
>
> **v1.22 材料外形**：新增 `MaterialShell.gd`，按 `shape` 绘制卡纸（切角/装订孔/日期格）、账本（书脊/标签/松紧带）、票据（缺口/虚线/存根）、信封（翻盖/火漆/邮票）。`PropMaterial` 增加 `shape/short`；`DeskItem` 未展开态只保留外形+图标+两字短名，材料类型/编号等细节移到展开抬头和正文；`AllocationView` 重排人情簿/院系账本/明日安排/感谢函/通行条的正文行距与横线。**材料不再放进自定义文件夹/小桌面**：`AllocationView` 直接把 `DeskItem` 铺在主游戏原木桌区域 `(268,375,760,396)`，`DeskView.set_allocation_chrome()` 在排班时隐藏主游戏中央卷宗，结束后恢复。
>
> **v1.23 纸质来访/可拖动**：`VisitorChat` 改为纸质来访登记单（无微信头/头像气泡），陈述是带红色左线的纸面段落，拟办/附件/回执均为纸面控件；标题左侧 `⋮` 和标题栏可拖动整张窗（`_on_head_input` 用事件坐标，限制在屏幕内）。`AllocationView` 删除访客 `ChatPanel`，无访客时显示纸质“来访登记/暂无来访”小卡；`DeskView.set_allocation_chrome()` 额外隐藏 `official_card`/`chat_panel`，拖动窗口后露出木桌而不是学生档案。
>
> **v1.25 纸质窗口/后账**：新增 `scripts/ui/PaperWindow.gd`，在 `_show_modal` 的 CenterContainer 卡片上挂拖动控制器（首次拖动才移到 `modal_loose`），支持 `⋮` 把手、边缘吸附、静态位置记忆；`modal_top` 用于值班日志这类必须压过 dim 图层的纸窗。`RunState` 增加 `duty_log`/`visitor_history` 并进入存档；`DeskItem` 增加 `note`/`stamp`/`archived` 与底部工具条；`AllocationView` 增加值班日志/卷宗入口；`Modals.duty_log()` 与 `Modals.ending()` 的“七天人账”；`FlowController._rank()` 增加停职/学院清算/人情网分支。`DesktopWindowManager` 增加请求窗置顶压暗与松手吸附。
>
> **v1.26 开局按钮修复**：`PaperGrip` 不能作为 `PanelContainer` 弹窗卡片的子节点（容器会把 20×22 拉伸到整张卡，`mouse_filter=STOP` 会吞掉“开始值班/开始审查”的点击）。现在把手挂在外层 `modal_loose`/`modal_top`，用 `card.item_rect_changed` 同步，仅占纸角；新增 `startcheck` 覆盖标题→每日通告→review。

## 运行时职责

```text
Main → FlowController → RequestDesk → DeskView → Control
  │                         │             │
  ├── RunState              │             ├── scenes/ui/ChatPanel.tscn
  │   ├── 当前进度、决定     │             └── scenes/ui/MaterialCard.tscn
  │   ├── 任务完成状态       │
  │   └── 剧情标记与统计     └── scenes/ui/DocumentWindow.tscn
  ├── GameState                         │ archive_requested
  │   └── UserData                      ▼
  └── DesktopWindowManager ← 窗口注册 / 拖动 / 关闭
```

| 位置 | 负责的内容 | 增加功能时怎么改 |
|---|---|---|
| `scripts/RunState.gd` | 进度、审核记录、任务完成、剧情状态、每天快照 | 新增状态、默认值、重置和快照放在一起 |
| `scripts/GameState.gd` | 存档读写、备份、版本迁移 | 新存档字段需要兼容旧版本 |
| `scripts/UserData.gd` | 存档、设置、统计的目录边界 | 新的持久化文件必须通过 `UserData.file()` |
| `scripts/DesktopWindowManager.gd` | 注册、层级、命中、位置、滚动、固定与并排 API | 窗口行为在这里实现，避免混入任务判定 |
| `scripts/ui/DocumentWindow.gd` | 文件窗口的标题栏、正文滚动区、页脚与归档信号 | 修改窗口外观；正文由调用方提供 |
| `scripts/ui/ChatPanel.gd` | 聊天面板外壳与回复信号 | 对话推进仍由 ChatController / Main 处理 |
| `scripts/ui/MaterialCard.gd` | 常驻材料与任务材料卡展示 | 卡片只接收显示数据，不直接读取游戏状态 |
| `scripts/RequestDesk.gd` | 任务文件内容、批准/退回、任务流程限制 | 复用文件窗口场景，不重新实现窗口管理 |
| `scripts/AllocationModel.gd` | 灯灭之前的预算、项目收益、人情档位与加成（纯数据/规则） | 新项目、来访、人情加成都写 `content/world.json → allocation` |
| `scripts/AllocationView.gd` | 排班板、硬币托盘、人情速览、结算按钮 | 只渲染和修改 `RunState` 的 `energy/money/alloc_placed`，不判定业务 |
| `scripts/Coin.gd` | 程序化像素硬币与空位 | 精力/金钱配色与点击信号 |
| `scripts/CollegeModel.gd` | 学部/学院映射、导师与主任、通过回礼文案 | 新学部、导师、回礼都在 `content/world.json → collegeGroups` |
| `scripts/FlowController.gd` | 每天、学生、夜班、分配、结局转换 | 新流程读取同一个 `run_state` |
| `scripts/Main.gd` | 控制器连接、渲染、输入和动画协调 | 逐步把独立功能下沉到组件 |

旧的 `day`、`perf` 等属性仍保留为 `run_state` 的转发属性，兼容现有控制器与测试；
它们不再保存第二份状态。继承链仍然存在，这次没有一次性重写整套输入与流程。

`GameState` 存档版本为 5，兼容版本 1、2、3、4。新增审核决定、任务决定、剧情标记、人情、分配日志与学院关系字段。
继续游戏仍从当天早晨开始；逐案恢复、正在进行的聊天与拖拽并未加入存档；分配阶段本身不做中途存档。

夜班结束后 `FlowController._start_allocation()` 打开 `AllocationView`，来访卡由 `Modals.visitor()` 提供；
`AllocationModel` 从 `GameData.allocation` 读取预算/项目/角色，`RunState.favor` 保存 0—10 的人情，
`favor_log` 记录来源，`_finish_allocation()` 统一结算项目收益后再进入次日通告。
盖“通过”时 `Main._college_pass()` 读取 `CollegeModel` 的学部数据，写入 `RunState.college_favor` 与
`college_log`；满 2 位规范通过把学部加入 `college_letters`，夜班 `NightController.college_letters()` 生成感谢函。

窗口管理器会在同一案件内保留关闭窗口的位置与滚动量，切换案件时清空。
`set_pinned()`、`arrange_pair()` 已提供并测试，可供后续工具栏接入；当前没有新增固定/并排按钮。
三个 `.tscn` 可以直接在 Godot 编辑器打开。稳定外壳已经场景化，动态文本、文件正文和部分装饰仍由脚本生成。

## 内容与发布校验

```text
content/{world,characters,cases,levels,tasks}.json
       ├── 浏览器编辑器：编辑、保存前校验、编译预览
       └── tools/content_tools.py：发布校验与构建
                         ↓
             assets/data.json + assets/requests.json
```

Python 是发布入口。共同字段结构定义在 `tools/content_schema.json`；
`python tools/sync_content_schema.py` 生成浏览器可直接加载的 `modules/content-schema.js`，
因此使用 `file://` 打开编辑器也不需要联网读取 schema。
共享 schema 支持类型、必填字段、对象属性和数组元素；它检查数据结构，不把故意设计的论文缺陷判为作者错误。

对话树、条件链的语义规则在 `content_contract.py` 与编辑器 `modules/contract.js` 中对应实现。
覆盖节点标识、起点、引用、说话人、选项、时间、自动循环、条件链类型、结果与可达性。
玩家选择触发的对话循环允许存在，自动推进的循环会被拒绝。
保存与导出都会拦截错误；浏览器自动保存继续保留草稿。

`tests/fixtures/content-contract.json` 的有效/无效样例同时运行在 Python 和 Node.js。
`tests/test_content_contract.py` 还比较完整项目的校验结果及编译产物，并检查生成的 schema 是否过期。
新增规则时先加有效/无效样例，再修改两端实现，最后运行一致性检查。

`content/logic.json` 仍用于编辑器设计与模拟，**尚未接入游戏判定**。
`content/world.json → allocation` 是 v1.14 分配阶段（角色、项目、预算、来访、人情档位）的唯一内容源；
编译后写入 `assets/data.json → ALLOCATION`，`allocation_errors()` 在发布前校验角色/项目/预算/选项/容量。
`content/world.json → collegeGroups` 是 v1.15 学院关系的唯一内容源；编译到 `assets/data.json → COLLEGE_GROUPS`，
`college_errors()` 校验 24 个学院的覆盖、学生导师/主任字段与 28 份资格审查表签字。

## 编辑器模块

`tools/level-editor/app.js` 仅负责组合和启动。各文件通过显式工厂与 `env.api` 连接，
保持普通脚本加载方式，无 npm 构建步骤，也保留本地 HTML 的文件夹选择模式。

| 模块 | 职责 |
|---|---|
| `model.js` | 常量与编辑器数据状态 |
| `store.js` | 查询、选择、修改标记 |
| `io.js` | 加载、保存、差异预览、浏览器草稿与导出 |
| `contract.js` / `content-schema.js` | 共享结构与语义校验 |
| `compiler.js` | 项目校验与运行时数据编译 |
| `controller.js` | UI 事件与编辑命令 |
| `logic-engine.js` | 条件链求值与校验适配 |
| `views-overview.js` | 概览与关卡队列 |
| `views-characters.js` | 人物、论文、对话树 |
| `views-tasks.js` | 待办、文档、纸张展示 |
| `views-logic.js` | 条件链画布与交互 |
| `views-publish.js` / `views-shell.js` | 发布页、外壳、弹窗和提示 |

## 统一开发命令

要求 Python 3.12、Node.js，以及 `tools/toolchain.json` 指定的 Godot 4.7.2。
Node.js 用于两端一致性测试，不要求安装 npm 包。

```powershell
# 首次配置 Windows 便携引擎与导出模板（从 Godot 官方发布页下载）
python -X utf8 tools/project.py setup
python -X utf8 tools/project.py doctor

# 内容变更后重新生成 assets
python -X utf8 tools/project.py build

# 日常完整测试；包含 7 个截图场景和新 PCK 冒烟
python -X utf8 tools/project.py test

# 只检查某一模块；有意跳过截图时会在报告中注明
python -X utf8 tools/project.py test --state architecturecheck --state savecheck
python -X utf8 tools/project.py test --skip-shots

# 单独打包；都必须生成新文件并运行冒烟检查
python -X utf8 tools/project.py pack
python -X utf8 tools/project.py export

# 发布前：内容构建、完整测试、截图、PCK 和 Windows exe
python -X utf8 tools/project.py release
```

`release` 不接受缩减测试的选项。缺模板、导出失败或包内错误都会失败，不会拿旧 exe 或 PCK 替代成功。
兼容原有 `run_tests.ps1`、`smoke_pack.ps1`、`smoke_export.ps1`，它们均转发到上述入口。
CI 也使用同一配置和入口；CI 的日常检查明确跳过截图，本地发布命令保留截图检查。

引擎查找顺序：`--godot` → `GODOT_BIN` → 忽略提交的 `tools/toolchain.local.json` → 项目内 `.tools/godot` / `_tools/godot` → PATH。
不再隐式依赖项目外的 `../_tools`。`setup` 使用 Godot 的
[self-contained mode](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#self-contained-mode)，
把引擎编辑器缓存、设置与模板保存在 `.tools/godot/editor_data/`。

每次检查生成独立的 `build/check-时间-随机值/`：

- `results.json`：检查结果与主动跳过的项目。
- `*.log` / `*.engine.log`：各项检查的输出。
- `user-data/<检查名>/`：隔离的存档、设置、统计与截图。
- `temp/<检查名>/`：构建临时文件。
- `THESIS_PLEASE.pck` / `THESIS_PLEASE.exe`：本次新产物。
- `artifact.json`：产物名称、大小、引擎版本和 SHA-256。

正式游戏继续使用原来的 `user://`。测试通过 `THESIS_USER_DIR` 定向到隔离目录，
手动运行 `TestMain` 或 `--state` 开发状态也会使用独立缓存目录。
成功标记与 stderr 一起检查；仅对本机已知的证书存储报错作明确例外，脚本、资源、导出错误不会被忽略。
截图基线缺失会失败，只有显式 `--update-baselines` 才能创建或更新。

## 后续增量顺序

1. 新增返修/回访：在 RunState 定义记录，补迁移与跨日测试，再接入 FlowController。
2. 新增窗口工具栏：使用管理器的固定/并排 API，沿用现有正文组件。
3. 调整布局：先编辑三个独立场景，后续逐步迁移稳定的子控件。
4. 增加逐案存档：另立版本与恢复契约，不直接把界面节点或聊天计时器序列化。
5. 继续削减 Main：按功能迁移输入与显示协调，逐步减少继承层之间的调用。
