class_name Sfx
extends Node

## Tiny procedural synth mirroring the original WebAudio cues.

const RATE := 22050

var streams: Dictionary = {}
var muted := false

func _ready() -> void:
	_build()

func play(name: String) -> void:
	if muted or !streams.has(name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = streams[name]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _build() -> void:
	streams["click"] = _mix([{"t": "square", "f": 420.0, "d": 0.035, "v": 0.02}])
	streams["page"] = _mix([
		{"t": "noise", "d": 0.045, "v": 0.018},
		{"t": "triangle", "f": 260.0, "d": 0.035, "v": 0.018},
	])
	streams["stamp"] = _mix([
		{"t": "noise", "d": 0.12, "v": 0.065},
		{"t": "sine", "f": 88.0, "d": 0.18, "v": 0.09, "ef": 54.0},
		{"t": "square", "f": 220.0, "d": 0.05, "v": 0.025, "delay": 0.01},
	])
	streams["correct"] = _mix([
		{"t": "triangle", "f": 540.0, "d": 0.09, "v": 0.025},
		{"t": "triangle", "f": 810.0, "d": 0.12, "v": 0.023, "delay": 0.09},
	])
	streams["wrong"] = _mix([
		{"t": "saw", "f": 210.0, "d": 0.12, "v": 0.025, "ef": 130.0},
		{"t": "noise", "d": 0.1, "v": 0.025, "delay": 0.05},
		{"t": "sine", "f": 120.0, "d": 0.22, "v": 0.035, "delay": 0.12, "ef": 72.0},
	])
	streams["approve"] = _mix([
		{"t": "noise", "d": 0.065, "v": 0.025},
		{"t": "triangle", "f": 392.0, "d": 0.1, "v": 0.024, "delay": 0.02},
		{"t": "triangle", "f": 587.0, "d": 0.14, "v": 0.022, "delay": 0.12},
		{"t": "triangle", "f": 784.0, "d": 0.18, "v": 0.018, "delay": 0.24},
	])
	streams["return"] = _mix([
		{"t": "noise", "d": 0.08, "v": 0.022},
		{"t": "triangle", "f": 330.0, "d": 0.12, "v": 0.022, "delay": 0.02, "ef": 220.0},
		{"t": "square", "f": 146.0, "d": 0.15, "v": 0.018, "delay": 0.13, "ef": 110.0},
	])
	streams["day"] = _mix([
		{"t": "triangle", "f": 392.0, "d": 0.12, "v": 0.025},
		{"t": "triangle", "f": 523.0, "d": 0.14, "v": 0.024, "delay": 0.13},
		{"t": "triangle", "f": 659.0, "d": 0.2, "v": 0.02, "delay": 0.27},
	])
	streams["select"] = _mix([{"t": "square", "f": 620.0, "d": 0.04, "v": 0.018}])
	streams["tab"] = _mix([
		{"t": "noise", "d": 0.026, "v": 0.016},
		{"t": "square", "f": 540.0, "d": 0.025, "v": 0.017, "delay": 0.01},
	])
	streams["pick"] = _mix([
		{"t": "noise", "d": 0.035, "v": 0.016},
		{"t": "triangle", "f": 190.0, "d": 0.035, "v": 0.018},
	])
	streams["drop"] = _mix([
		{"t": "sine", "f": 135.0, "d": 0.09, "v": 0.04, "ef": 78.0},
		{"t": "noise", "d": 0.045, "v": 0.022, "delay": 0.01},
	])
	streams["hover"] = _mix([{"t": "square", "f": 880.0, "d": 0.012, "v": 0.005}])

func _mix(events: Array) -> AudioStreamWAV:
	var total := 0.05
	for e in events:
		var dd: float = float(e.get("delay", 0.0)) + float(e.get("d", 0.1)) + 0.03
		total = max(total, dd)
	var n := int(total * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for e in events:
		_render(buf, e)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v: float = clamp(buf[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav

func _render(buf: PackedFloat32Array, e: Dictionary) -> void:
	var kind := str(e.get("t", "sine"))
	var dur := float(e.get("d", 0.1))
	var vol := float(e.get("v", 0.03))
	var delay := float(e.get("delay", 0.0))
	var f0 := float(e.get("f", 440.0))
	var f1 := float(e.get("ef", 0.0))
	var start := int(delay * RATE)
	var count := int(dur * RATE)
	var phase := 0.0
	var lp := 0.0
	for i in range(count):
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var env := vol
		if t < 0.008:
			env = vol * (t / 0.008)
		else:
			env = vol * pow(0.0012, (t - 0.008) / max(0.001, dur - 0.008))
		var s := 0.0
		if kind == "noise":
			var white := randf() * 2.0 - 1.0
			lp += 0.28 * (white - lp)
			s = lp
		else:
			var f := f0
			if f1 > 0.0 and dur > 0.0:
				f = f0 * pow(f1 / f0, t / dur)
			phase += TAU * f / RATE
			if kind == "square":
				s = 1.0 if sin(phase) >= 0.0 else -1.0
			elif kind == "triangle":
				s = (2.0 / PI) * asin(sin(phase))
			elif kind == "saw":
				var cyc := phase / TAU
				s = 2.0 * (cyc - floor(cyc + 0.5))
			else:
				s = sin(phase)
		buf[idx] += s * env
