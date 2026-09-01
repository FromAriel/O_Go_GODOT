# AGENTS.md

## Scope

This repository is a clean Godot 4.7.2 game shell. Keep changes tightly scoped to the user's request. Do not perform unrelated refactors, archaeology, cleanup, or speculative work.

## Engine and language

- Target Godot 4.7.2 unless the user explicitly changes the project version.
- Prefer GDScript for new gameplay code unless the user asks for C#.
- Use 4 spaces for GDScript indentation.
- Prefer text-based `.tscn` and `.tres` resources when practical so changes remain reviewable in Git.

## Repository hygiene

- Do not commit `.godot/`, imported caches, editor state, exports, build output, logs, or temporary files.
- Source assets such as images, audio, fonts, and models are allowed when they are part of the game. Do not apply a blanket no-binaries rule to game assets.
- Do not modify `.chatgpt/` or `.codex/` tooling unless the task is specifically about the development environment.
- Preserve LF line endings for repository text files.

## Validation

After changing GDScript, scenes, resources, or project configuration, run the relevant Godot checks when the environment supports them:

```bash
godot --headless --editor --import --quit --path .
godot --headless --check-only --quit --path .
```

Use `.chatgpt/setup.sh` for the lightweight ChatGPT sandbox environment and `.codex/setup.sh` for the fuller Linux/Codex environment.

Run focused tests for the system changed. Do not spend time running unrelated test suites unless a dependency or failure makes them necessary.

## Delivery

When work is complete, report:

1. what changed,
2. which files changed,
3. what verification actually ran,
4. any remaining failure or uncertainty.

Do not claim a check passed unless it was executed successfully.
