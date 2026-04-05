# CLAUDE.md

## Purpose

This repository is for producing math/statistics study materials that combine:

- Japanese LaTeX PDF generation with `LuaLaTeX`
- Python-based plots and helper scripts
- Statistical Test Grade Pre-1 study workflows implemented as local skills

## Core Rules

- Use `uv` for all Python execution in this repository.
- Prefer the project-local environment and locked dependencies under `python_env/`.
- Do not assume external OCR tooling is available or required for the statistics skills unless a skill explicitly instructs it.

## Environment Expectations

- TeX engine: `lualatex`
- Python environment: `uv` with local `.venv`
- Common plotting stack: `matplotlib`, `seaborn`, `numpy`, `scipy`, `pandas`
- Japanese plotting support: `matplotlib_fontja`

## Python Conventions

- Run scripts as `uv run python <script>.py ...` unless the script is directly invoked by a repository wrapper that already uses `uv`.
- When generating plots that include Japanese text, ensure `matplotlib_fontja` is imported.
- Respect the locked dependency set in `python_env/requirements.lock` when changing Python dependencies.

## TeX Conventions

- Default to `LuaLaTeX` for compilation.
- Assume Japanese support is required unless the task clearly does not need it.
- Keep generated materials compatible with the repository's existing LaTeX workflow and smoke test assumptions.

## Skills In This Repository

### `stats-workbook-builder`

Use for building a workbook PDF from textbook/problem images.

Typical fit:

- chapter- or topic-level material from image folders
- detailed solutions plus review points
- extraction of figures from source images

### `stats-past-exam-explainer`

Use for a thorough explanation of one specific past-exam problem.

Typical fit:

- a request tied to a concrete exam and problem number
- explanation of reasoning, derivation flow, and related practice

### `stats-weakness-analyzer`

Use for a dedicated weakness-remediation handout focused on one concept or failure pattern.

Typical fit:

- follow-up remediation after a workbook or past-exam explanation
- focused reinforcement on one topic, concept, or mistake pattern

Do not invoke this skill for small follow-up questions that can be answered directly in chat.

## Skill Selection

- Use `stats-workbook-builder` for image-to-workbook tasks.
- Use `stats-past-exam-explainer` for a single past-exam problem explanation.
- Use `stats-weakness-analyzer` only when the user wants a dedicated weakness-focused document.
- For lightweight Q&A or one-step clarification, answer directly without starting a document-generation workflow.
