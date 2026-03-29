extends Node

const SAMPLE_RATE := 44100.0
const POOL_SIZE   := 10

var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_setup_music()

# --- Pool helpers ---

func _get_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return _pool[0]

func _play(buf: PackedVector2Array, duration: float, volume_db: float) -> void:
	var player := _get_player()
	var gen    := AudioStreamGenerator.new()
	gen.mix_rate      = SAMPLE_RATE
	gen.buffer_length = duration + 0.08
	player.stream    = gen
	player.volume_db = volume_db
	player.play()
	var pb: AudioStreamGeneratorPlayback = player.get_stream_playback()
	pb.push_buffer(buf)

# --- Waveform builders ---

func _sine(freq_start: float, freq_end: float, duration: float) -> PackedVector2Array:
	var n   := int(SAMPLE_RATE * duration)
	var buf := PackedVector2Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var progress := float(i) / float(n)
		var freq     := lerpf(freq_start, freq_end, progress)
		phase        += TAU * freq / SAMPLE_RATE
		var s        := sin(phase) * (1.0 - progress)
		buf[i]        = Vector2(s, s)
	return buf

func _square(freq: float, duration: float) -> PackedVector2Array:
	var n   := int(SAMPLE_RATE * duration)
	var buf := PackedVector2Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var progress := float(i) / float(n)
		phase        += TAU * freq / SAMPLE_RATE
		var s        := (1.0 if sin(phase) > 0.0 else -1.0) * (1.0 - progress) * 0.4
		buf[i]        = Vector2(s, s)
	return buf

func _noise(duration: float, amp: float = 0.35) -> PackedVector2Array:
	var n   := int(SAMPLE_RATE * duration)
	var buf := PackedVector2Array()
	buf.resize(n)
	for i in n:
		var progress := float(i) / float(n)
		var s        := randf_range(-amp, amp) * (1.0 - progress)
		buf[i]        = Vector2(s, s)
	return buf

func _concat(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(a.size() + b.size())
	for i in a.size():
		out[i] = a[i]
	for i in b.size():
		out[a.size() + i] = b[i]
	return out

func _silence(duration: float) -> PackedVector2Array:
	var n   := int(SAMPLE_RATE * duration)
	var buf := PackedVector2Array()
	buf.resize(n)
	return buf

# --- Public API ---

func play_clone_create() -> void:
	var buf := _sine(280.0, 720.0, 0.15)
	_play(buf, 0.15, -6.0)

func play_clone_remove() -> void:
	var buf := _sine(520.0, 160.0, 0.18)
	_play(buf, 0.18, -8.0)

func play_task_complete() -> void:
	var note1 := _sine(523.25, 523.25, 0.10)
	var gap   := _silence(0.04)
	var note2 := _sine(659.25, 659.25, 0.18)
	var buf   := _concat(_concat(note1, gap), note2)
	_play(buf, 0.32, -5.0)

func play_task_fail() -> void:
	var buf := _square(110.0, 0.35)
	_play(buf, 0.35, -9.0)

func play_wave_start() -> void:
	var n1  := _sine(440.0, 440.0, 0.09)
	var g1  := _silence(0.03)
	var n2  := _sine(550.0, 550.0, 0.09)
	var g2  := _silence(0.03)
	var n3  := _sine(660.0, 660.0, 0.14)
	var buf := _concat(_concat(_concat(_concat(n1, g1), n2), g2), n3)
	_play(buf, 0.38, -7.0)

func play_interact_start() -> void:
	var buf := _noise(0.07, 0.28)
	_play(buf, 0.07, -14.0)

func play_low_efficiency() -> void:
	var buf := _sine(220.0, 180.0, 0.12)
	_play(buf, 0.12, -12.0)
	
var _music_menu: AudioStreamPlayer
var _music_game: AudioStreamPlayer

func _setup_music() -> void:
	_music_menu = AudioStreamPlayer.new()
	_music_menu.stream = load("res://audio/PaCarlosIntro.wav")
	(_music_menu.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_menu.volume_db = 0.0
	add_child(_music_menu)

	_music_game = AudioStreamPlayer.new()
	_music_game.stream = load("res://audio/PaCarlosFull.wav")
	(_music_game.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_game.volume_db = 0.0
	add_child(_music_game)

func play_menu_music() -> void:
	if _music_game:
		_music_game.stop()
	if _music_menu and not _music_menu.playing:
		_music_menu.play()

func play_game_music() -> void:
	if _music_menu:
		_music_menu.stop()
	if _music_game and not _music_game.playing:
		_music_game.play()

func stop_music() -> void:
	if _music_menu: _music_menu.stop()
	if _music_game:  _music_game.stop()
