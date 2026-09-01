# O Go Godot

A clean Godot 4.7.2 starter repository for building a game from the Godot editor, ChatGPT, or a coding agent.

This repo intentionally starts almost empty. It keeps only the project shell and the tooling needed to validate Godot work in headless Linux environments.

## Start here

### Godot editor

Open this repository as a Godot project. The placeholder main scene is `scenes/main.tscn`.

### ChatGPT Linux sandbox

Use the lightweight sandbox bootstrap:

```bash
bash .chatgpt/setup.sh
export PATH="/mnt/data/.chatgpt-tools/bin:$PATH"
godot --headless --editor --import --quit --path .
godot --headless --check-only --quit --path .
```

The ChatGPT bootstrap prefers an existing or pre-staged Godot 4.7.2 binary and keeps its cache under `/mnt/data`.

### Codex / general Linux workspace

Use the fuller bootstrap when Mono/.NET and the wider linting toolchain are useful:

```bash
bash .codex/setup.sh
godot --headless --editor --import --quit --path .
godot --headless --check-only --quit --path .
```

## Layout

```text
assets/         Source game assets
scenes/         Godot scenes
scripts/        GDScript/C# source
tests/          Automated game tests
.chatgpt/       Lightweight ChatGPT sandbox bootstrap
.codex/         Full Codex/Linux bootstrap helpers
```

There are deliberately no inherited CODEXVault demos, hosted tools, blog files, output artifacts, or game systems in this repository.
