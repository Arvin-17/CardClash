extends Node
## Thin wrapper over HTTPRequest for every backend call. Game scenes never call the
## network directly. Every call fails silently: a dead Wi-Fi at the demo table should
## cost the leaderboard, never the game.
##
## Scenes pass a `done` Callable instead of awaiting, so a scene that changes before the
## reply arrives is simply skipped (a freed object's Callable is no longer valid).
##
## Base URL: project setting cardclash/api/base_url, overridable with `-- --api=URL`.

signal online_changed(is_online: bool)

var base_url: String = "http://127.0.0.1:8000"
var timeout_seconds: float = 6.0
var online: bool = false


func _ready() -> void:
	base_url = str(ProjectSettings.get_setting("cardclash/api/base_url", base_url))
	timeout_seconds = float(ProjectSettings.get_setting("cardclash/api/timeout_seconds", timeout_seconds))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--api="):
			base_url = arg.trim_prefix("--api=")
	base_url = base_url.trim_suffix("/")


## Returns the parsed JSON body (Dictionary or Array), or null on any failure.
func request_json(method: HTTPClient.Method, path: String, body: Variant = null) -> Variant:
	var req := HTTPRequest.new()
	req.timeout = timeout_seconds
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var payload := "" if body == null else JSON.stringify(body)
	var err := req.request(base_url + path, headers, method, payload)
	if err != OK:
		req.queue_free()
		_set_online(false)
		return null
	var response: Array = await req.request_completed
	req.queue_free()
	var result: int = response[0]
	var code: int = response[1]
	var raw: PackedByteArray = response[3]
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_online(false)
		return null
	_set_online(true)
	if code < 200 or code >= 300:
		return null
	return JSON.parse_string(raw.get_string_from_utf8())


## GET /health: is the server up? Shown as online/offline on the menu.
func health(done: Callable = Callable()) -> bool:
	var r: Variant = await request_json(HTTPClient.METHOD_GET, "/health")
	var ok := r is Dictionary and bool((r as Dictionary).get("ok", false))
	_finish(done, ok)
	return ok


## GET /daily-seed -> {"date", "seed"} or null.
func daily_seed(done: Callable = Callable()) -> Variant:
	var r: Variant = await request_json(HTTPClient.METHOD_GET, "/daily-seed")
	var out: Variant = r if r is Dictionary and (r as Dictionary).has("seed") else null
	_finish(done, out)
	return out


## GET /cards: newer card data from the server. Falls back to the bundled copy when offline.
func refresh_cards() -> void:
	var r: Variant = await request_json(HTTPClient.METHOD_GET, "/cards")
	if r is Dictionary and int((r as Dictionary).get("version", 0)) >= GameData.cards_version:
		GameData.apply_cards(r)


## POST /run -> {"id", "rank"}, or null when offline / rejected.
func submit_run(payload: Dictionary, done: Callable = Callable()) -> Variant:
	var r: Variant = await request_json(HTTPClient.METHOD_POST, "/run", payload)
	var out: Variant = r if r is Dictionary and (r as Dictionary).has("rank") else null
	_finish(done, out)
	return out


## GET /leaderboard -> Array of {rank, player_name, won, battles_won, time_ms}, or null.
func leaderboard(daily: bool = false, limit: int = 10, done: Callable = Callable()) -> Variant:
	var path := "/leaderboard?daily=%s&limit=%d" % ["true" if daily else "false", limit]
	var r: Variant = await request_json(HTTPClient.METHOD_GET, path)
	var out: Variant = r if r is Array else null
	_finish(done, out)
	return out


func _finish(done: Callable, value: Variant) -> void:
	if done.is_valid():
		done.call(value)


func _set_online(value: bool) -> void:
	if value != online:
		online = value
		online_changed.emit(online)
