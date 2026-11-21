extends Node
## Thin wrapper over HTTPRequest for every backend call. Game scenes never call the
## network directly. Every call fails silently: a dead Wi-Fi at the demo table should
## cost the leaderboard, never the game.
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
func health() -> bool:
	var r: Variant = await request_json(HTTPClient.METHOD_GET, "/health")
	return r is Dictionary and bool((r as Dictionary).get("ok", false))


func _set_online(value: bool) -> void:
	if value != online:
		online = value
		online_changed.emit(online)
