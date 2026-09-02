class_name ProjectLoadResult
extends RefCounted

## Result of decoding/loading a project manifest.
##
## Keep the parsed manifest and diagnostics together so callers can surface useful
## validation information without relying on exceptions or log scraping.

var manifest: ProjectManifest = null
var validation: ValidationResult = ValidationResult.new()
var source_path: String = ""


func is_success() -> bool:
    return manifest != null and validation.is_valid()
