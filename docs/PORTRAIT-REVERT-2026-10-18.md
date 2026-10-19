# 立绘回退记录 · 2026-10-18 23:57

游戏立绘已恢复为 **导入前的原始 144×192 版本**。

## 恢复

- 备份：`D:\dex\portrait-import-backups\20261018-232413_before`
- 28 张 normal + 28 张 blink 全部恢复，哈希与备份 `MANIFEST.json` 一致
- 当前新画风 180 版备份：`D:\dex\portrait-import-backups\20261018-2355_before_revert_180`
- 新画风完整交付仍保留在：`D:\dex\pixel-workbench\deliveries\20261018-232413_v3-bayer4-136`

## 代码

恢复为原始行为：

| 项 | 值 |
| --- | --- |
| `portrait_shadow.scale` | 1.045 |
| shader `virtual_size` | 144×192 |
| `ca_strength` | 0.0007 |
| `scanline_strength` | 0.012 |
| 尺寸断言 | 144×192 |

## 验证

```text
PORTRAITCHECK ok portraits=28
SMOKE ok docs=168 students=28
```

- PCK：`build/THESIS_PLEASE.pck`（2,875,672 B）
- 截图：`_shots/shader-01-soft.png` / `_shots/portraitstyle.png`
- 回退记录：`D:\dex\pixel-workbench\deliveries\20261018-2355_original_restored`
