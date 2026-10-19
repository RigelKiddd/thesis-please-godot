# 结构优化交付记录 · 2026-10-19

本轮完成六项结构调整，并在现有 v1.13 内容上完成发布验证。

| 调整项 | 已落实内容 |
|---|---|
| 编辑器 / Python 校验 | 共用字段 schema；对话树与条件链使用同一批有效、无效样例；保存和导出均拦截错误 |
| 测试 / 构建 | 存档、设置、统计、日志和临时文件隔离；项目内便携 Godot；统一 setup / build / test / release 入口与 CI |
| 游戏状态 | RunState 集中进度、决定、任务完成与剧情标记；GameState 负责存储和版本迁移 |
| 文件窗口 | DocumentWindow 场景复用；DesktopWindowManager 管理层级、命中、移动、关闭及滚动恢复 |
| 编辑器结构 | 原 3762 行 app.js 拆为 20 行启动入口和按职责划分的模块 |
| UI 场景 | 文件窗口、聊天面板、材料卡可独立打开；PixelPanel 外观参数可在 Inspector 调整 |

同时修复了圈注动画在节点销毁后继续回调，以及退出时自定义光标纹理未释放的问题。

## 验证结果

- Python / JavaScript 共用 **56 个有效或无效样例**；**48 组项目变体**的接受/拒绝结果一致，有效变体的编译产物一致。
- `project.py release` **41 项检查全部通过**，包括内容构建、引擎导入、游戏契约、新架构检查、7 个截图、PCK 与 Windows exe 导出及冒烟。
- 游戏冒烟覆盖 28 个学生的 168 次基础文档渲染；另有 280 次全类型文档和 21 次夜班文档渲染检查。
- Chrome 实际打开 7 个编辑页面，通过编辑、无效内容禁止保存、条件链运行与撤销、保存差异、6 文件保存（内存模拟目录）、编译以及 `file://` 启动检查。
- 相对修改前备份：没有删除原文件；`content/`、`assets/` 和截图基线的 SHA-256 均保持一致。
- 最终验证前后，正式目录内的存档、备份、设置和统计文件 SHA-256 保持一致。

发布报告：[`results.json`](../build/check-20261019-110819-cc3c79/results.json)。
新 Windows 程序：[`THESIS_PLEASE.exe`](../build/check-20261019-110819-cc3c79/THESIS_PLEASE.exe)。
产物 SHA-256：`27e9f6c230ec86088a3641995a71ff7d4320f5f959c1ec80819af32ebb597184`。
浏览器检查：[`results.json`](../build/editor-browser/results.json)。
文件核对：[`architecture-review.json`](../build/architecture-review.json)。

构建日志里保留本机 Godot 的证书存储报错；检查器只允许这一明确例外，脚本、资源或导出错误仍会导致失败。
Windows 导出模板已安装在 `.tools/godot/editor_data/export_templates/4.7.2.stable/`。

## 使用边界

- 现有继承链保留，旧状态属性转发到同一个 RunState；后续可继续按功能减少 Main 的协调职责。
- 存档仍从当天早晨恢复，尚未增加逐案恢复。
- 固定、并排窗口已实现管理接口并测试，尚未增加面向玩家的按钮；位置与滚动记忆限定在同一案件内。
- 场景化覆盖稳定外壳；动态文案、正文和部分装饰仍由脚本生成。
- 条件链仍是编辑器的设计与模拟功能，没有接入运行时判定。
- CI 已改为共用本地入口，本轮验证在本机执行，未触发远程 CI。

开发入口与后续改动位置见 [项目结构与维护入口](ARCHITECTURE.md)。

修改前完整备份：`D:/dex/_backups/architecture-20261019-022656/before.zip`。
该备份独立于 Git，保留了任务开始时已有的未提交工作。
