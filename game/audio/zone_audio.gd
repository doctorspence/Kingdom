class_name ZoneAudio
extends Node
## The sound of a zone: background ambience that follows the weather, the time
## of day and whether you are underground, plus slow music with long pauses
## (more like a walk through a forest than a soundtrack).
##
## DayNight creates one of these. It reads DayNight's numbers (night, rain,
## cave), so it needs no setup in the level.
##
##   Beds (loop all the time, fade in and out):
##     forest   daytime woods; quieter at night and in the rain
##     rain     follows the rain showers
##     cave     the Gullet: low rumble, plus a drip-and-echo layer
##   Music (one track at a time, with silence between): the dark forest theme by
##     day, the lament at night; stops underground.
##   Crows: now and then, by day and dry, from somewhere around you.

const AMBIENCE := "res://assets/audio/ambience/"
const MUSIC := "res://assets/audio/music/"
const SILENT_DB := -60.0
## Seconds to fade between loudness levels (the checks shorten it).
@export var fade := DEFAULT_FADE
const DEFAULT_FADE := 2.5

## Seconds of silence between music tracks (min, max).
@export var music_gap := Vector2(25.0, 70.0)
## Seconds between crow calls (min, max).
@export var crow_gap := Vector2(18.0, 50.0)
## Test scenes turn this on; headless runs skip audio otherwise to stay fast.
@export var run_headless := false

var day_night: DayNight
## Loudness each bed wants right now, 0..1 (read by the audio check).
var targets := {&"forest": 0.0, &"rain": 0.0, &"cave": 0.0, &"cave_deep": 0.0}

var _beds := {}  # name -> AudioStreamPlayer
var _levels := {&"forest": 0.0, &"rain": 0.0, &"cave": 0.0, &"cave_deep": 0.0}
var _music: AudioStreamPlayer
var _music_level := 0.0
var _music_wait := 8.0
var _crow_wait := 15.0
## Which track is playing or was last played (for the checks).
var current_track := ""


func _ready() -> void:
	if DisplayServer.get_name() == "headless" and not run_headless:
		set_process(false)
		return
	_add_bed(&"forest", AMBIENCE + "Forest_Ambience.mp3")
	_add_bed(&"rain", AMBIENCE + "Dark_Rainy_Night.ogg")
	_add_bed(&"cave", AMBIENCE + "dark_cavern_ambient_001.ogg")
	_add_bed(&"cave_deep", AMBIENCE + "dungeon002.ogg")
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = SILENT_DB
	add_child(_music)
	_music.finished.connect(func() -> void:
		current_track = ""
		_music_wait = randf_range(music_gap.x, music_gap.y))


func _add_bed(bed_name: StringName, path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if "loop" in stream:
		stream.set(&"loop", true)
	var p := AudioStreamPlayer.new()
	p.name = String(bed_name)
	p.stream = stream
	p.bus = &"Ambience"
	p.volume_db = SILENT_DB
	add_child(p)
	_beds[bed_name] = p


func _process(delta: float) -> void:
	_update_targets()
	for bed_name in _beds:
		_levels[bed_name] = move_toward(_levels[bed_name], targets[bed_name], delta / fade)
		var p: AudioStreamPlayer = _beds[bed_name]
		var lvl: float = _levels[bed_name]
		if lvl <= 0.003:
			if p.playing:
				p.stop()
			continue
		if not p.playing:
			p.play(randf() * maxf(p.stream.get_length() - 1.0, 0.0))  # start mid-way: not always the same moment
		p.volume_db = linear_to_db(lvl) + _bed_trim(bed_name)
	_update_music(delta)
	_update_crows(delta)


## How loud each bed wants to be, from the weather and where you are.
func _update_targets() -> void:
	var cave := DayNight.cave
	var night := DayNight.night
	var rain := day_night.rain_amount if day_night else 0.0
	var surface := 1.0 - cave
	targets[&"forest"] = surface * lerpf(1.0, 0.35, night) * lerpf(1.0, 0.45, rain)
	targets[&"rain"] = surface * rain
	targets[&"cave"] = cave
	targets[&"cave_deep"] = cave * 0.55


## Fixed loudness trims (dB) so the files sit together.
func _bed_trim(bed_name: StringName) -> float:
	match bed_name:
		&"forest":
			return -4.0
		&"rain":
			return -8.0
		&"cave":
			return -6.0
		_:
			return -10.0


func _update_music(delta: float) -> void:
	var allowed := 1.0 - DayNight.cave
	if not _music.playing:
		_music_wait -= delta
		if _music_wait <= 0.0 and allowed > 0.9:
			_start_track()
	# Fade with the surroundings; below ground the music stops.
	_music_level = move_toward(_music_level, allowed, delta / fade)
	_music.volume_db = linear_to_db(maxf(_music_level, 0.001)) - 6.0
	if _music.playing and _music_level <= 0.003:
		_music.stop()
		current_track = ""
		_music_wait = randf_range(music_gap.x, music_gap.y)


func _start_track() -> void:
	var file := "Lament_for_a_Warriors_Soul.mp3" if DayNight.night > 0.5 else "GameMusic_ForestTheme_24.mp3"
	var stream := load(MUSIC + file) as AudioStream
	if stream == null:
		_music_wait = 60.0
		return
	if "loop" in stream:
		stream.set(&"loop", false)
	_music.stream = stream
	_music.play()
	current_track = file


func _update_crows(delta: float) -> void:
	_crow_wait -= delta
	if _crow_wait > 0.0:
		return
	_crow_wait = randf_range(crow_gap.x, crow_gap.y)
	var rain := day_night.rain_amount if day_night else 0.0
	if DayNight.night > 0.3 or DayNight.cave > 0.05 or rain > 0.2:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var angle := randf() * TAU
	var spot := cam.global_position + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(14.0, 32.0) + Vector3.UP * randf_range(2.0, 9.0)
	Audio.sfx(&"crow", spot)
