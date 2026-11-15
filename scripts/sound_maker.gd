extends SceneTree
## Sound maker: creates all the game's sounds and music as .wav files in audio/.
## Like level_builder.gd, it's a tool, not part of the game. Run it from a terminal:
##   Godot_console.exe --headless --path . --script res://scripts/sound_maker.gd
## Every sound is built from simple waves (no samples), so it's all our own.
## You can replace any .wav in audio/ with a better sound later; just keep the name.

const RATE := 22050  # samples per second (enough for retro-style sounds)


func _initialize() -> void:
	save("sfx_launch", sweep(220, 880, 0.18, "sine", 0.6))          # boing up
	save("sfx_bounce", sweep(520, 160, 0.13, "triangle", 0.8))      # boing down
	save("sfx_ready", concat([note(1318.5, 0.07, "sine", 0.5), note(1760, 0.22, "sine", 0.5)]))
	save("sfx_click", note(1000, 0.04, "square", 0.25))
	save("sfx_win", concat([note(523.3, 0.11, "square", 0.3), note(659.3, 0.11, "square", 0.3),
		note(784, 0.11, "square", 0.3), note(1046.5, 0.5, "square", 0.3)]))
	save("music_loop", make_music())
	print("Sounds saved in audio/")
	quit()


# --- Building blocks ---------------------------------------------------------

## One wave sample. t = position in the wave cycle (0..1).
func wave(kind: String, t: float) -> float:
	match kind:
		"sine": return sin(t * TAU)
		"square": return 1.0 if t < 0.25 else -1.0  # 25% "duty" = classic chiptune sound
		"triangle": return 4.0 * absf(t - 0.5) - 1.0
		_: return randf() * 2.0 - 1.0  # noise


## A tone that slides from one pitch to another and fades out.
func sweep(f_start: float, f_end: float, seconds: float, kind: String, volume: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var phase := 0.0
	var n := int(seconds * RATE)
	for i in n:
		var k := float(i) / n
		phase = fmod(phase + lerpf(f_start, f_end, k) / RATE, 1.0)
		var envelope := minf(1.0, i / 60.0) * (1.0 - k) * (1.0 - k)  # quick start, fade out
		out.append(wave(kind, phase) * envelope * volume)
	return out


func note(freq: float, seconds: float, kind: String, volume: float) -> PackedFloat32Array:
	return sweep(freq, freq, seconds, kind, volume)


func concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func midi_to_hz(m: int) -> float:
	return 440.0 * pow(2.0, (m - 69) / 12.0)


# --- Music: a short original chiptune loop (120 BPM, 8 bars, C-Am-F-G) -------

func make_music() -> PackedFloat32Array:
	var eighth := 0.25  # seconds per eighth note at 120 BPM
	# Melody: 8 eighth notes per bar, MIDI note numbers (-1 = silence)
	var melody := [
		[64, 67, 72, 67, 64, -1, 67, -1],
		[69, 72, 76, 72, 69, -1, 64, -1],
		[65, 69, 72, 69, 77, 76, 72, -1],
		[67, 71, 74, 71, 67, -1, 62, -1],
		[64, 67, 72, 67, 76, -1, 72, -1],
		[69, 72, 76, 79, 76, -1, 72, -1],
		[77, 76, 74, 72, 69, -1, 65, -1],
		[67, -1, 71, -1, 74, 72, 71, -1],
	]
	var bass_roots := [48, 45, 41, 43, 48, 45, 41, 43]  # C, A, F, G
	var total := int(8 * 8 * eighth * RATE)
	var mix := PackedFloat32Array()
	mix.resize(total)

	for bar in 8:
		for step in 8:
			var start := int((bar * 8 + step) * eighth * RATE)
			# lead
			var m: int = melody[bar][step]
			if m >= 0:
				_add(mix, start, note(midi_to_hz(m), eighth * 0.9, "square", 0.16))
			# bass on every quarter note, jumping between low and high octave
			if step % 2 == 0:
				var b: int = bass_roots[bar] + (12 if step % 4 == 2 else 0)
				_add(mix, start, note(midi_to_hz(b), eighth * 1.8, "triangle", 0.35))
			# soft hi-hat on the off-beats
			if step % 2 == 1:
				_add(mix, start, note(0, 0.03, "noise", 0.05))
	return mix


func _add(mix: PackedFloat32Array, start: int, sound: PackedFloat32Array) -> void:
	for i in sound.size():
		if start + i < mix.size():
			mix[start + i] += sound[i]


# --- Saving ------------------------------------------------------------------

func save(name: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav("res://audio/%s.wav" % name)
