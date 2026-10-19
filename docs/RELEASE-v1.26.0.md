# 论文审批处 / THESIS, PLEASE — v1.26.0

发布日期：2026-10-19

**Windows x64 便携版**：下载 `THESIS_PLEASE-v1.26.0-windows-x64.zip`，解压后运行 `THESIS_PLEASE.exe`。免安装，不写注册表。

- 分辨率：1380 × 860，可缩放
- 引擎：Godot 4.7.2（GL Compatibility）
- 存档：`%APPDATA%\Godot\app_userdata\thesis_please`
- 系统：Windows 10/11 x64，OpenGL 3.3

## v1.26.0 重点

### 修复开局公告点不进去

`PaperWindow` 的 `⋮` 纸角把手原先挂在弹窗 `PanelContainer` 里，被容器拉伸成整张卡大小，`mouse_filter = STOP` 吞掉了“开始值班 / 开始审查 / 设置”等按钮的点击。

- 把手改挂外层 `modal_loose` / `modal_top`；
- 只占纸角 20×22，跟随卡片位置；
- 新增 `startcheck`：标题 → 每日通告 → review。

### 纸质窗口

- 设置、帮助、账本、投诉、值班日志、日结、聘期审查统一可拖；
- `⋮` 把手、屏幕内约束、边缘吸附、位置记忆；
- 拖动抬起阴影，松手回弹；
- 请求包/附件补置顶压暗与吸附。

### 值班日志 / 周报 / 多结局

- 自动记录来访批办、排班、对账异常；
- 纸质 `DutyLogCard`：红装订线、胶带、教务处章、横线纸；
- `L` 或分配界面“值班日志”打开；
- 第 7 天“七天人账”；结局：停职调查 / 学院清算 / 人情网 / 长聘 / 续聘 / 留用 / 解约。

### 材料批注 / 盖章 / 归档

- 展开材料底部：手写批注、已阅/缓办/驳回、归档/取回；
- 卷宗模式单独查看归档材料；
- 盖章有红章压纸效果；批注随存档并进入来访登记单；
- 人情簿 vs 院系账本差 ≥5 时生成“对账”日志。

### 复访

- 现有重复角色（沈知夏、系主任）再次来访会带上次回执与批注。

## 操作

| 键 | 作用 |
|---|---|
| 鼠标 | 拖材料 / 纸窗 / 盖章 |
| `F` | 人情簿 |
| `C` | 学院账本 |
| `L` | 值班日志 |
| `H` | 帮助 |
| `G` | 设置 |
| `M` | 音效 |
| `Esc` | 关闭纸窗 |

## 截图

![开局](https://raw.githubusercontent.com/RigelKiddd/thesis-please-godot/main/screenshots/106-title-dossier.png)
![纸质来访](https://raw.githubusercontent.com/RigelKiddd/thesis-please-godot/main/screenshots/146-visitor-paper.png)
![值班日志](https://raw.githubusercontent.com/RigelKiddd/thesis-please-godot/main/screenshots/152-duty-log.png)
![七天人账](https://raw.githubusercontent.com/RigelKiddd/thesis-please-godot/main/screenshots/155-week-ending.png)

## 已知问题

- 完整 9 角色复访弧线仍只有现有重复角色；更多内容会在后续版本补。
- 纸窗位置记忆只在本次运行内，跨启动保存尚未做。
- 新动画尚未全部接入“减少动效”设置。

## 校验

发布页同时提供 `THESIS_PLEASE-v1.26.0-windows-x64.zip.sha256`。

## 授权

代码 MIT；原案/剧情/角色/视觉来自项目所有者提供的 `thesis-please.html`，不随 MIT 重新授权。字体与引擎说明见 `NOTICE.md`。
