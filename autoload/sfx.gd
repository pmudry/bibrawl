extends Node

## Sons générés en code au démarrage (placeholders, zéro asset).
## Usage : `Sfx.play("shoot")`. Les sons seront remplacés par de vrais
## samples quand l'audio deviendra un sujet.

const MIX_RATE := 22050
const POOL_SIZE := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_streams["shoot"] = _sweep(0.12, 900.0, 350.0, 0.05)
	_streams["hit"] = _sweep(0.07, 500.0, 200.0, 0.8)
	_streams["destroy"] = _sweep(0.45, 220.0, 40.0, 0.5)
	_streams["levelup"] = _sweep(0.3, 400.0, 1000.0, 0.0)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Joue un son sur le premier lecteur libre, avec une légère variation de hauteur
## pour que les tirs répétés ne sonnent pas comme une boucle.
func play(sound: String, volume_db: float = 0.0) -> void:
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		push_warning("Sfx: son inconnu '%s'" % sound)
		return
	for player in _players:
		if player.playing:
			continue
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = randf_range(0.92, 1.08)
		player.play()
		return


## Balayage de fréquence f0 → f1 avec enveloppe décroissante, mélangé à du bruit blanc.
func _sweep(duration: float, f0: float, f1: float, noise_mix: float) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in count:
		var progress := float(i) / count
		var frequency := lerpf(f0, f1, progress)
		phase += TAU * frequency / MIX_RATE
		var envelope := (1.0 - progress) * (1.0 - progress)
		var tone := sin(phase)
		var noise := randf_range(-1.0, 1.0)
		var sample := lerpf(tone, noise, noise_mix) * envelope
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
