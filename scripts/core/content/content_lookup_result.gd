class_name ContentLookupResult
extends RefCounted

## Result of resolving one stable content reference.
##
## A found definition may still accompany diagnostics (for example a kind
## mismatch), but `is_success()` is true only when the lookup is fully valid.

var definition: ContentDefinition = null
var validation: ValidationResult = ValidationResult.new()


func is_success() -> bool:
    return definition != null and validation.is_valid()
