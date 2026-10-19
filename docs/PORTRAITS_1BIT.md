# 1-BIT 学生胸像 · 接入说明

这套资产是 **THESIS, PLEASE** 的 28 位学生胸像，按游戏的 **深绿 / 纸奶油 / 橄榄 / 印章红** 重新调的 1-bit 像素版。

## 规格

- **游戏尺寸**：`144×192`（3:4，透明 PNG）
- **原生像素**：`72×96`
- **预览**：`864×1152`（12× nearest）
- **色盘**：`#14110f` ink / `#efe3c8` paper / `#223b2d` pine / `#6c7a55` olive / `#a33a32` stamp red / `#c9a97c` tan / `#f7f0df` pale
- **路径**：`res://assets/portraits_1bit/dXsY.png`

## 切换

`scripts/Main.gd` 的 `_load_portrait()` 目前是：

```gdscript
portrait_normal = load("res://assets/portraits/%s.png" % key)
portrait_blink = load("res://assets/portraits/%s-blink.png" % key)
```

改成：

```gdscript
const PORTRAIT_DIR := "res://assets/portraits_1bit/"
...
portrait_normal = load(PORTRAIT_DIR + "%s.png" % key)
portrait_blink = null   # 这一批没有眨眼图；null 时 _blink_loop 会自动跳过
```

如果只是想在某个界面/存档里试，不必改全局路径，单独 `load("res://assets/portraits_1bit/d1s1.png")` 即可。

## 挂 Shader

材质已经放在：

```text
res://assets/portraits_1bit/thesis_portrait_material.tres
```

给 `Main.tscn` 里的 `Portrait`（TextureRect 或 Sprite2D）挂上：

```gdscript
portrait.material = load("res://assets/portraits_1bit/thesis_portrait_material.tres")
```

或者在编辑器里：Portrait → Material → Load → 选 `thesis_portrait_material.tres`。

## Shader 参数

| 参数 | 作用 |
| --- | --- |
| `virtual_size` | `(72, 96)`，和原生像素一致 |
| `grain` | 纸面颗粒；0.04–0.08 比较克制 |
| `rim_strength` | 奶油色轮廓光；0.10–0.20 让黑发从深绿底上分离 |
| `outline_strength` | 额外墨线；烘焙图已经有 1px ink 边，默认 0 |
| `flash` | 盖错章/受击时闪印章红，0–1 |
| `dissolve` | 退场/换人溶解，0–1 |
| `tint` + `tint_strength` | 夜班/回忆的偏色（例如 `Color(0.78,0.88,0.92)` + 0.25） |

## 说明

- 这批 **没有 `-blink.png`**；把 `portrait_blink` 设为 `null` 即可，游戏会跳过眨眼，不会报错。
- 原 `assets/portraits/` 旧图没有被覆盖，随时可以切回去对比。
- 28 人的姓名/专业/编号见交付包的 `README.md` 或 `gallery.html`；`dXsY` 与现有 `Main.gd` 的 `d%ds%d` 命名一致。
