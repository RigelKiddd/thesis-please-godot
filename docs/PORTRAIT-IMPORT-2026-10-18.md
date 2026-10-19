# 立绘导入记录 · 2026-10-18 23:42

> **2026-10-18 23:57 已回退**：当前游戏使用导入前的原始 144×192 立绘。本文保留新画风 180×220 的导入历史，供以后切换。

## 来源

- Workbench 批次：`D:\dex\pixel-workbench\output\batch-20261018-232413-24ed87`
- 冻结交付：`D:\dex\pixel-workbench\deliveries\20261018-232413_v3-bayer4-136`
- 原始批次 29 张（28 名角色 + 1 张 UUID 测试图）；游戏只使用 28 名角色的 `dXsY`。

## 参数

| 项 | 值 |
| --- | --- |
| preset | `v3_painted`（本次改参，不是默认值） |
| 原生 | 136×181 |
| 交付 | 408×543（3× nearest） |
| 原游戏批次 | 144×192 |
| 实际导入 | **180×220（1:1）** |
| 色盘 | `none`（不量化） |
| 抖动 | `bayer4` / 14 |
| 刻点 | 0.13 |
| 饱和 / 对比 | 0.89 / 1.03 |
| 皮肤保护 | 0.50 |
| Alpha | 112 |
| 画幅 / 留白 | 3:4 / 5.5% |

完整机器可读参数：交付目录的 `params-lock.json`、`source/preset.json`、`frame-export.json`。

## 180×220 重导出

原 144×192 进 180×220 框会留下 7.5px 透明边，并且 144/180、192/220 都是非整数缩放，脸部像素容易不均匀。

- 从 raw 1024×1536 重新取 content bbox，**cover** 到 180×220，肩膀/衣领贴住左右框
- 清除 2px baked 浅色轮廓（`strip_game_180.py`）
- `DeskView` 的 `portrait_shadow.scale` 改为 1.0，不再向外扩边
- shader `virtual_size` 改为 180×220
- `ca_strength=0.0`、`scanline_strength=0.0`，去掉脸部彩色边/扫描线
- 原 144×192 资产保留在交付的 `game/`；导入版在 `game_180x220/`

> cover 会裁掉约 20px 底部，c26 秒表、c28 笔电、c23 听诊器等最底部道具会比 144 版少一截。这是为了让肩膀贴框、脸更大的取舍。

## 导入

- 目标：`assets/portraits/`
- `dXsY.png` × 28：180×220
- `dXsY-blink.png` × 28：同图占位（项目原本就是同图占位）
- 备份：
  - 144 版：`D:\dex\portrait-import-backups\20261018-2338_before_180x220`
  - 最初旧版：`D:\dex\portrait-import-backups\20261018-232413_before`
- 未改 `SettingsStore`；`grimoire_bust` shader 仍在，只调了上述参数。

## 验证

- Godot 4.7.2 `--import`：通过
- `--state=portraitcheck`：`PORTRAITCHECK ok portraits=28`
- `build/THESIS_PLEASE.pck`：4,440,248 B
- `--main-pack build/THESIS_PLEASE.pck -- --state=smoke`：`SMOKE ok docs=168 students=28`
- 游戏内截图：交付目录 `ingame-180-style-off.png`、`ingame-180-shader-soft.png`

## 回滚

把 144 版备份复制回 `assets/portraits/`，同时把 `DeskView.gd` 的 `virtual_size`、`ca_strength`、`scanline_strength`、`portrait_shadow.scale` 和 `TestMain.gd` 的 180×220 断言还原，再执行 `--import`。

```powershell
Copy-Item 'D:\dex\portrait-import-backups\20261018-2338_before_180x220\*.png' 'D:\dex\thesis-please-godot\assets\portraits\' -Force
& 'D:\dex\_tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\dex\thesis-please-godot' --import
```
