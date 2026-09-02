class_name ProjectManifestLoader
extends RefCounted

## File/text loading boundary for ProjectManifest data.
##
## This class owns I/O and JSON parsing only. Schema/semantic validation belongs
## to ProjectManifestValidator, and content-reference resolution belongs to P5.


static func load_file(path: String) -> ProjectLoadResult:
    if not FileAccess.file_exists(path):
        var missing := ProjectLoadResult.new()
        missing.source_path = path
        missing.validation.add_error(
            &"project.manifest.file_missing",
            "Project manifest file does not exist: %s" % path,
            path,
            &"manifest",
            "Check the project path and manifest filename."
        )
        return missing

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        var failed := ProjectLoadResult.new()
        failed.source_path = path
        failed.validation.add_error(
            &"project.manifest.file_open",
            "Project manifest could not be opened: %s" % path,
            path,
            &"manifest",
            "Check file permissions and path accessibility."
        )
        return failed

    return load_text(file.get_as_text(), path)


static func load_text(text: String, source: String = "<memory>") -> ProjectLoadResult:
    var json := JSON.new()
    var parse_error := json.parse(text)
    if parse_error != OK:
        var failed := ProjectLoadResult.new()
        failed.source_path = source
        failed.validation.add_error(
            &"project.manifest.json",
            "Invalid project manifest JSON at line %d: %s"
                % [json.get_error_line(), json.get_error_message()],
            source,
            &"manifest",
            "Fix the JSON syntax before loading the project."
        )
        return failed

    return ProjectManifestValidator.decode(json.data, source)
