# 《论文审批处》音乐生成提示词 / MUSIC PROMPTS

> 给 Suno / Udio / Stable Audio / 本地音乐模型使用。所有曲目都要求**纯器乐、无人声、可无缝循环**。
> 目标不是“电影配乐”，而是**一间 1990 年代中国大学教务处窗口的声音**：日光灯、纸张、印章、雨、远处的走廊。
> 音乐必须给对白、音效和玩家思考让路；它应该像暖气管道一样持续存在，而不是抢戏。

---

## 0. 全局声音设定（先读这一段）

| 项目 | 设定 |
|---|---|
| 类型 | 官僚黑色幽默 / 室内乐 / 磁带环境 / 极简配乐 |
| 年代 | 1990 年代末—2000 年代初的中国大学 |
| 调性 | 以 D 小调、A 小调、C 小调为主；温暖结局转 F 大调 |
| 速度 | 58–84 BPM，不要快于 90 |
| 主奏 | 毡音钢琴（felt piano）、大提琴、低音提琴、弱音小号、钢片琴、音乐盒 |
| 质感 | 磁带底噪、房间混响、日光灯 50Hz 嗡鸣、远处雨声、翻纸声 |
| 动态 | 极低。整曲 −20 至 −16 LUFS；不要渐强到“高潮” |
| 结构 | 4–8 小节动机循环，允许 2–3 层配器逐步加入；结尾必须能接回开头 |
| 禁止 | 人声、歌词、说唱、鼓组大混响、史诗铜管、预告片鼓、抖音热梗、lo-fi 鼓点、爵士即兴独奏、任何真实艺术家/乐队名字 |

### 核心动机：纸张三音

```
D4 – F4 – E4     （长—短—长，像盖章前的一次呼吸）
```

- 白天：钢琴中音区，每 4 小节出现一次。
- 夜班：大提琴低八度演奏，尾音不解决。
- 投诉：把 E4 改成 Eb4，变成不协和的小二度。
- 结局：上行到 F4–A4–G4，落在 F 大三和弦。

### 生成时的通用负面词

```
vocals, lyrics, singing, choir, rap, spoken word, epic drums, trailer hit,
brass fanfare, dubstep, EDM, trap, lo-fi hip hop beat, saxophone solo,
Orchestral crescendo, loud cymbals, excessive reverb, melody hook,
copyrighted melody, artist name, band name
```

### 无缝循环写法（Suno/Udio 都适用）

1. 先生成 60–120 秒完整段落；
2. 用“loop”提示再生成一版，或把最后 2 秒交叉淡化到开头；
3. 导出时保留 48kHz/24bit WAV，循环点放在**乐句结束后的半拍**，不要切在混响尾巴上；
4. 进 Godot 后统一转 Ogg Vorbis（质量 0.7），在导入面板勾选 Loop。

---

## 1. 标题 / 继续值班 `title_theme`

**用途**：标题页、继续值班、设置页背景。
**长度**：90 秒无缝循环。
**情绪**：一天还没开始，窗口还没开；有一点疲惫，但不悲伤。

**Suno prompt**

```
[Instrumental] [Slow chamber ambient] [Bureaucratic noir]
A sparse felt piano plays a three-note motif D4-F4-E4 in a small tiled office
at dawn. Soft cello enters underneath, bowed long tones, no vibrato. Tape hiss,
distant rain against a window, faint 50Hz fluorescent hum. 68 BPM, D minor.
The piece stays quiet and circular, like a clock nobody is watching.
No drums, no vocals, no melody climax. Seamless loop, 90 seconds.
```

**Udio prompt**

```
instrumental, chamber ambient, felt piano, solo cello, tape hiss, room tone,
rain on window, 68 bpm, D minor, minimal, circular, no percussion, no vocals,
bureaucratic, quiet, loopable
```

**编排建议**

| 时间 | 事件 |
|---|---|
| 0–8s | 磁带底噪 + 日光灯嗡鸣 + 雨声 |
| 8–24s | 钢琴三音动机，每 4 小节一次 |
| 24–48s | 大提琴低八度长音进入 |
| 48–72s | 钢片琴在高音区点两下，像盖章的回声 |
| 72–90s | 逐层撤走，回到只有底噪，接回 0s |

---

## 2. 白天审查 `day_theme`

**用途**：主审查界面。玩家看论文、翻标签、圈注、盖章。
**长度**：120 秒循环，建议做 **3 个分层**（base / tension / overtime），游戏内交叉淡化。
**情绪**：重复、克制、略有荒诞；不能让人烦躁。

**Suno prompt（base 层）**

```
[Instrumental] [Minimal chamber groove] [Bureaucratic office]
72 BPM, A minor. Upright bass plays a two-bar walking figure with no swing.
Brushed snare and a soft woodblock keep time like a wall clock. Felt piano
plays short, dry chords; muted trumpet answers once every eight bars. Typewriter
clicks and paper shuffles sit low in the mix, treated as percussion. No vocals,
no solos, no build-up. The loop should feel like a queue that does not move.
```

**Suno prompt（tension 层，叠加用）**

```
[Instrumental] [Same tempo 72 BPM, A minor] [Sparse tension]
Low cello tremolo and a single repeated piano note A3, slightly detuned.
A high harmonic faintly rings. No drums. Designed to sit under the base layer
when a student has a critical defect. Very low dynamics, loopable, 60 seconds.
```

**Suno prompt（overtime 层）**

```
[Instrumental] [Same 72 BPM, A minor] [Tired overtime]
Add a distant elevator hum, a clock tick, and a muted trumpet fragment.
The bass drops out; only piano and room tone remain. 60 seconds, loopable.
```

**Udio prompt**

```
instrumental, minimal chamber jazz, upright bass, brushed drums, felt piano,
muted trumpet, typewriter percussion, 72 bpm, A minor, repetitive, low dynamics,
no vocals, no solo, loopable
```

**游戏内混音**

- base 常驻 −18 LUFS；
- tension 仅在“本份材料有 critical 缺陷”时淡入 +2dB；
- overtime 在当天最后一名学生时淡入，base 降到 −4dB；
- 盖章、投诉、圈注音效出现时，音乐 bus duck −6dB，持续 0.4s。

---

## 3. 夜班 `night_theme`

**用途**：下班后、灯灭之后、夜班文件阅读。
**长度**：90 秒循环。
**情绪**：空楼、灯管、雨；不是恐怖，是“所有人都走了”。

**Suno prompt**

```
[Instrumental] [Night chamber ambient] [Empty university office]
58 BPM, D minor. Solo cello plays a slow descending line; prepared piano
occasionally answers with a muted thud. Room tone, clock tick, rain on glass,
a distant door. No percussion, no melody resolution. The music should feel
like reading someone else's mail at 9 p.m. Very sparse, 90-second seamless loop.
```

**Udio prompt**

```
instrumental, night ambient, solo cello, prepared piano, room tone, clock tick,
rain, 58 bpm, D minor, sparse, no percussion, no vocals, loopable, melancholy
but not sad
```

**编排建议**：每 30 秒只加一个元素；大提琴不要连续演奏超过 8 秒；留大量空白给翻纸声。

---

## 4. 投诉 / 误判 `complaint_theme`

**用途**：盖错章、投诉单弹出、声誉下降。
**长度**：45 秒循环（或 12 秒 sting + 30 秒循环）。
**情绪**：不是惊吓，是“胃往下沉”。

**Suno prompt**

```
[Instrumental] [Dissonant chamber sting] [Bureaucratic dread]
C minor. A low string cluster (C2-Db2-G2) swells slowly; a single piano note
Eb5 repeats unevenly, like a pen tapping. Paper crumples once. No drums.
The harmony does not resolve. 84 BPM pulse implied but not played.
12-second intro sting, then a 30-second loop, very low dynamics.
```

**Udio prompt**

```
instrumental, dissonant chamber, low string cluster, repeated piano note,
paper crumple, 84 bpm implied, C minor, tense, unresolved, no drums, no vocals,
loopable
```

---

## 5. 证据链闭合 / 圈注命中 `evidence_sting`

**用途**：圈注命中、微信提示与报告对上、证据链完整。
**长度**：6–8 秒，不循环。
**情绪**：一个小而确定的“对上了”。

**Suno prompt**

```
[Instrumental] [Short warm sting] [Case closed]
D major. Felt piano plays D4-F#4-A4, a soft cello joins on the last note,
one small chime. 6 seconds, gentle attack, no drums, no big reverb.
Feels like a file being closed, not a victory fanfare.
```

**Udio prompt**

```
instrumental, short warm sting, felt piano, soft cello, chime, D major,
6 seconds, gentle, no drums, no vocals
```

---

## 6. 学生来信 `student_mail`

**用途**：夜班生成的“下班后收到的一封邮件”。
**长度**：25 秒循环。
**情绪**：私人的、稍微笨拙的善意。

**Suno prompt**

```
[Instrumental] [Intimate miniature] [Student letter]
Music box plays a simple five-note phrase in F major; pencil scratches on paper,
a chair creaks, rain is softer here. 64 BPM. No cello, no bass, no drums.
The phrase repeats with one wrong note the second time, then corrects itself.
25-second loop.
```

**Udio prompt**

```
instrumental, music box, pencil on paper, chair creak, soft rain, 64 bpm,
F major, intimate, naive, loopable, no vocals, no drums
```

---

## 7. 结局 · 温暖 `ending_warm`

**用途**：长聘 / 续聘 / 留用结局。
**长度**：60 秒，不循环（或尾奏可循环）。
**情绪**：不是庆祝，是“明天还要上班，但窗开着”。

**Suno prompt**

```
[Instrumental] [Warm chamber epilogue] [Morning office]
F major. Felt piano carries the paper motif D-F-E transformed to F-A-G,
cello plays a long warm line, faint birds outside, paper box being closed.
70 BPM. No drums, no triumph, no choir. Ends on an open F chord with the
sustain pedal down. 60 seconds.
```

**Udio prompt**

```
instrumental, warm chamber, felt piano, cello, morning birds, paper, 70 bpm,
F major, gentle, resolved but open, no drums, no vocals
```

---

## 8. 结局 · 冷 `ending_cold`

**用途**：不续聘 / 停职结局。
**长度**：60 秒。
**情绪**：灯关了，桌子空了；不控诉。

**Suno prompt**

```
[Instrumental] [Cold chamber epilogue] [Empty office]
D minor. Detuned upright piano plays the paper motif with the last note missing.
Fluorescent hum, a chair rolling away, a stamp being put down. No cello,
no resolution. 60 BPM. Ends on a single D2 with room tone. 60 seconds.
```

**Udio prompt**

```
instrumental, cold chamber, detuned piano, fluorescent hum, chair, room tone,
60 bpm, D minor, empty, unresolved, no drums, no vocals
```

---

## 9. 印章 / 圈注 / 翻页（短音效，不是音乐）

这三条可以只用程序合成（项目已有 `Sfx.gd`），不需要模型生成。若要用模型：

| 名称 | 时长 | 提示词 |
|---|---|---|
| `stamp_hit` | 1.2s | `single heavy rubber stamp on paper, wood desk, short room reverb, no music` |
| `pen_circle` | 1.4s | `red pen drawing a slow circle on paper, faint paper fiber, close microphone` |
| `page_turn` | 0.6s | `single sheet of thin paper turned, close, dry, no music` |

---

## 10. 生成与验收清单

- [ ] 无人声、无歌词、无真实艺术家风格。
- [ ] 循环点无爆音、无淡出；首尾各留 50ms 静音余量。
- [ ] 整曲动态不超过 6dB；没有突然的鼓或铜管。
- [ ] 在游戏里以 −18 至 −20 LUFS 播放，音效出现时 duck −6dB。
- [ ] 每首导出 48kHz/24bit WAV + Ogg Vorbis 两版。
- [ ] Ogg 导入 Godot 后勾选 Loop，循环点与 WAV 试听一致。
- [ ] 用耳机与笔记本扬声器各听一遍：笔记本上不能只剩低频嗡鸣。
- [ ] 连续循环 10 分钟不烦；如果烦，删掉一层配器再生成。

---

## 11. 一次性“整张 OST”提示词（给支持长音频的模型）

```
[Instrumental] [46 minutes] [Bureaucratic chamber noir OST]
A concept album for a game set in a 1990s Chinese university thesis review
office. Recurring three-note paper motif D-F-E. Palette: felt piano, cello,
upright bass, brushed drums, muted trumpet, music box, tape hiss, room tone,
rain, fluorescent hum, typewriter, paper, stamps. Tempo 58-84 BPM. Keys D minor,
A minor, C minor, F major for the ending. No vocals, no lyrics, no epic drums,
no trailer hits, no jazz solos, no lo-fi hip hop. Dynamics stay low and patient;
the music is furniture, not a performance. Track list: title, day loop (3 layers),
night loop, complaint, evidence sting, student mail, warm ending, cold ending.
Seamless loops, 48kHz, subtle tape saturation.
```

---

## 12. 版权与来源

- 以上提示词为原创声音方向描述；生成结果请自行确认模型条款。
- 不要在提示词里写真实作曲家、乐队或现有作品名。
- 若使用参考曲，只提取“配器密度、混响长度、动态范围”，不要复刻旋律。
