# 立绘 v2：28 张 strict-style 胸像 + Grimoire shader

来源：`D:\dex\portrait-redraw-v2`（用户提供的 v2 交付）。
这一版把游戏内 28 张 72×88 旧立绘替换为 **144×192 透明底 strict-style 胸像**，并在 03 窗口的 `TextureRect` 上挂 `grimoire_bust` 色域层。

## 文件

| 游戏内 | 来源 | 说明 |
|---|---|---|
| `assets/portraits/d1s1.png` … `d7s4.png` | `portrait-redraw-v2/game/style_144/` | 28 张，144×192 RGBA |
| `assets/portraits/dXsY-blink.png` | 同正常帧的副本 | 新交付无 blink 帧；用同图占位，避免旧眨眼帧串脸 |
| `shaders/grimoire_bust.gdshader` | `portrait-redraw-v2/shader/grimoire_bust.gdshader` | Godot 4 canvas_item shader |
| `docs/PORTRAITS-V2.md` | 本文件 | 参数、来源、限制 |

游戏键与 `dXsY` 对齐：`d1s1`…`d7s4`，共 28 人。

## 接入方式

`Main._build_booth()` 创建 `TextureRect` 后：

```gdscript
var mat := ShaderMaterial.new()
mat.shader = load("res://shaders/grimoire_bust.gdshader")
mat.set_shader_parameter("virtual_size", Vector2(144, 192))
mat.set_shader_parameter("palette_mix", 0.55)
mat.set_shader_parameter("intensity", 0.35)
mat.set_shader_parameter("dither_strength", 0.04)
mat.set_shader_parameter("ca_strength", 0.0007)
mat.set_shader_parameter("alpha_cutoff", 0.40)
mat.set_shader_parameter("grade_strength", 0.30)
mat.set_shader_parameter("rim_strength", 0.0)
mat.set_shader_parameter("scanline_strength", 0.012)
mat.set_shader_parameter("stipple_strength", 0.04)
portrait.material = mat
```

旧 `portrait_crt.gdshader` 保留作为回退：如果 `grimoire_bust` 不存在，仍使用旧 CRT 层。设置里“立绘 shader”默认开启，可切回 STYLE 原色。

## 参数为什么这样取

- `virtual_size=(144,192)`：纹理原生尺寸；shader 内部按这个网格做像素采样与 dither。
- `palette_mix=0.55`：把 16 色盘压到偏暗紫/墨绿的蚀刻色域，同时保留较多原色。
- `intensity=0.35`：graded 结果与原图的比例；0=STYLE，0.35=当前默认，1.0/1.4/1.85 是更重的实验档。
- `grade_strength=0.30`：轻强度，优先保住脸部可读性。
- `alpha_cutoff=0.40`：沿用 1-bit 硬 alpha；不会画出轮廓外背景。
- `rim_strength=0.0`：v2 原图自带 1px 亮边，shader 不再额外加白/绿轮廓；`stipple=0.07`、`scanline=0.02` 保持干墨和扫描线。
- `portrait_shadow`：在立绘下方叠一张同图、`modulate≈黑`、`scale=1.045` 的剪影，盖住剩余的浅色边缘，形成暗色轮廓而不是白边。
- `tools/strip_portrait_outline.py`：去掉原图 2px 内的 baked 亮边（最近内部色回填），并同步 `-blink.png`；已处理 28 张，约 1.7 万像素。

## 白边处理

v2 原图在头发/衣领外圈有一层 bone-white 亮边，直接进游戏会像一圈白描边。处理分三层：

1. **源图**：`tools/strip_portrait_outline.py` 把离透明边界 2px 内的像素回填为最近内部色；头发/外套边缘变成黑/深色，白衬衫和纸页内部保持白色。
2. **Shader**：`rim_strength=0.0`，并注释掉 `c += rim_color * edge * rim_strength`，不再额外加白/绿边。
3. **渲染**：`portrait_shadow` 在立绘下方叠一张暗色、放大 4.5% 的剪影，盖住抗锯齿残留；看起来是暗色轮廓，不是白边。

## 力度对比

`screenshots/shader-comparison.png` 是 5 档同一机位对照：

| 档位 | intensity | palette | 说明 |
|---|---:|---:|---|
| STYLE | — | — | 完全关闭 shader，原色 |
| 01-soft | .35 | .55 | **当前游戏默认**，接近原色，只保留一点冷色/扫描线 |
| 02-current | 1.0 | .76 | 较早的默认档，更紫更暗 |
| 03-strong | 1.4 | .92 | 更暗、更紫，轮廓更硬 |
| 04-max | 1.85 | 1.0 | 实验上限，脸部/衣料压暗明显 |

单张：`screenshots/shader-00-style-off.png` … `shader-04-max.png`；
整窗：`screenshots/shader-window-style.png` / `shader-window-current.png` / `shader-window-max.png`。
设置里“立绘 shader”开关对应 STYLE；默认使用 01-soft。

## 限制

- **无 blink 帧**：新交付只有 normal。`-blink.png` 是 normal 的副本，因此不会出现旧图串脸，但也不会有真正的闭眼动画。
- **grimoire 偏暗**：这是 v2 README 里也提到的可选项；如果觉得脸部太暗，优先降 `grade_strength`（0.35）或 `palette_mix`（0.65），不要调 `alpha_cutoff`。
- **参考图版权**：`portrait-redraw-v2` 的参考图只用于风格研究，不随游戏打包；游戏只使用生成的 28 张胸像。
- 旧立绘已被覆盖；如需回退，从 `D:\dex\portrait-redraw-v2\game\style_144` 重新取图，或恢复旧 `assets/portraits` 备份。

## 验证

- `--state=portraitcheck`：28 张全部 144×192、blink 占位存在、`portrait.material` 是 `grimoire_bust` 且 `virtual_size=(144,192)`。
- `--state=chat --shot=...` / `shotregress`：实际渲染检查色域层。
- 截图：`screenshots/50-portrait-grimoire.png`。
