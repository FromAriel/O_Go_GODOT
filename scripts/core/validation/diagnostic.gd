class_name Diagnostic
extends RefCounted

## One structured validation or runtime diagnostic.
##
## Diagnostics are intentionally data-like so the same information can later
## appear in logs, tests, inspectors, map/project validation UIs, or CI output.

enum Severity {
    INFO,
    WARNING,
    ERROR,
}

var severity: int = Severity.INFO
var code: StringName = &""
var message: String = ""
var source: String = ""
var field_name: StringName = &""
var suggested_fix: String = ""


func _init(
    p_severity: int = Severity.INFO,
    p_code: StringName = &"",
    p_message: String = "",
    p_source: String = "",
    p_field_name: StringName = &"",
    p_suggested_fix: String = ""
) -> void:
    severity = p_severity
    code = p_code
    message = p_message
    source = p_source
    field_name = p_field_name
    suggested_fix = p_suggested_fix


func is_error() -> bool:
    return severity == Severity.ERROR


func is_warning() -> bool:
    return severity == Severity.WARNING
