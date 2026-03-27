extends RefCounted
class_name Observability

static func log_debug(category: String, message: String) -> void:
	print("[%s][DEBUG] %s" % [category, message])


static func log_info(category: String, message: String) -> void:
	print("[%s][INFO] %s" % [category, message])


static func log_warning(category: String, message: String) -> void:
	push_warning("[%s][WARN] %s" % [category, message])


static func log_error(category: String, message: String) -> void:
	push_error("[%s][ERROR] %s" % [category, message])


static func connect_once_safe(signal_ref: Signal, callable_ref: Callable, context_name: String) -> bool:
	if callable_ref.is_null():
		log_error("Signal", "%s attempted to connect a null callable." % context_name)
		return false

	if signal_ref.is_connected(callable_ref):
		log_warning("Signal", "%s duplicate signal connection skipped for %s." % [context_name, callable_ref])
		return false

	var err := signal_ref.connect(callable_ref)
	if err != OK:
		log_error("Signal", "%s failed to connect signal to %s (code=%d)." % [context_name, callable_ref, err])
		return false

	return true
