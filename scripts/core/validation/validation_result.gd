class_name ValidationResult
extends RefCounted

## Aggregate of structured diagnostics produced by validation passes.
##
## Validation is successful when no ERROR diagnostics are present. Warnings and
## informational diagnostics remain visible without preventing execution.

const DiagnosticType = preload("res://scripts/core/validation/diagnostic.gd")

var diagnostics: Array = []


func add(diagnostic) -> void:
    diagnostics.append(diagnostic)


func add_info(
    code: StringName,
    message: String,
    source: String = "",
    field_name: StringName = &"",
    suggested_fix: String = ""
) -> void:
    add(DiagnosticType.new(
        DiagnosticType.Severity.INFO,
        code,
        message,
        source,
        field_name,
        suggested_fix
    ))


func add_warning(
    code: StringName,
    message: String,
    source: String = "",
    field_name: StringName = &"",
    suggested_fix: String = ""
) -> void:
    add(DiagnosticType.new(
        DiagnosticType.Severity.WARNING,
        code,
        message,
        source,
        field_name,
        suggested_fix
    ))


func add_error(
    code: StringName,
    message: String,
    source: String = "",
    field_name: StringName = &"",
    suggested_fix: String = ""
) -> void:
    add(DiagnosticType.new(
        DiagnosticType.Severity.ERROR,
        code,
        message,
        source,
        field_name,
        suggested_fix
    ))


func merge(other) -> void:
    diagnostics.append_array(other.diagnostics)


func has_errors() -> bool:
    for diagnostic in diagnostics:
        if diagnostic.is_error():
            return true
    return false


func is_valid() -> bool:
    return not has_errors()


func count_by_severity(severity: int) -> int:
    var count := 0
    for diagnostic in diagnostics:
        if diagnostic.severity == severity:
            count += 1
    return count
