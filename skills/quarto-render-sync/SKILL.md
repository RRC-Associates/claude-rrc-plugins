---
name: quarto-render-sync
description: Set up a Quarto post-render workflow that automatically renames HTML output and copies it to a network folder. Use when the user wants to render a .qmd and sync the output to Egnyte or a shared drive.
disable-model-invocation: true
---

# Quarto Render-and-Sync Workflow

This skill sets up a Quarto project with a post-render hook that automatically renames the rendered output and copies it to a network folder (e.g., Egnyte mapped drive).

## Architecture

Three files work together:

1. **`_quarto.yml`** — Declares the post-render hook
2. **`post_render.R`** — Runs automatically after render; renames output and copies to network
3. **The `.qmd` file** — Contains `params$output_path` specifying the network destination

## Reference Implementations

If you have access to the RRC repos, see:
- `<your-repos>/primers/quarto_markdown_word` — original Word/.docx version
- `<your-repos>/sem_yr5_2026/00_template_scripts` — HTML version

### `_quarto.yml`

```yaml
project:
  type: default
  post-render:
    - "Rscript post_render.R"
```

### `.qmd` YAML params

The `.qmd` file must include `output_path` in its YAML params block:

```yaml
params:
  output_path: "Z:/Shared/RRC/M/DATA/SEM/SEM (YR5) 2026/field_tracking"
```

### `post_render.R` pattern

The post-render script follows this structure:

1. **Find the rendered output** — Check `QUARTO_PROJECT_OUTPUT_FILES` env var (set by Quarto), fall back to scanning `.qmd` files for declared output
2. **Parse YAML from the source `.qmd`** — Use `yaml::yaml.load()` on the front matter to get `params$output_path`
3. **Optionally rename** — If the output should have a different name (e.g., match a dataset filename), **copy** the file rather than rename it. Quarto checks for the original output file after post-render and will error if it's been renamed/moved.
4. **Copy to network** — Use `file.copy()` with `overwrite = TRUE`, or `RrcUtils::sync_to_egnyte()` if available. Wrap in `tryCatch` so a network failure doesn't crash the render.

### Key gotcha: copy, don't rename

When renaming output in post-render, always use `file.copy()` instead of `file.rename()`. Quarto verifies its expected output file still exists after post-render completes. If the original file is gone, Quarto reports:

> ERROR: No output created by quarto render

The original file can be gitignored.

### `.gitignore` patterns

```
*_files/
00_template_scripts/*.html
```

## Packages used

- **`yaml`** — Parse YAML front matter from `.qmd` files
- **`quarto`** — `quarto::quarto_render()` if rendering from R (optional; user can also render from IDE)
- **`RrcUtils`** — `sync_to_egnyte(from, to, overwrite, verbose)` for network drive copies (optional; `file.copy()` works too)

## Workflow for the analyst

1. Open the `.qmd` and update the parameters (park name, data file path, output_path, etc.)
2. Render normally (Ctrl+Shift+K in Positron/RStudio, or `quarto render` from terminal)
3. Post-render hook runs automatically — renames and copies to network folder
