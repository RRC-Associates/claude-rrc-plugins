# RRC Claude Code Plugins

Claude Code plugins for RRC analysts. Plugins are packages of skills and behaviors that load automatically in every Claude Code session.

## Plugins

### rrc-R-tools

R and Quarto workflow skills for RRC analysts.

| Skill | Behavior |
|---|---|
| `r-style` | Tidyverse coding style, pipe-based workflows, `here::here()` for repo paths. Auto-loads on any R work. |
| `diagnose-before-fixing` | Explains errors and identifies root causes before proposing fixes. Auto-loads for all debugging. |
| `quarto-render-sync` | Sets up a post-render hook to copy output to a network drive. Invoke on demand. |
| `quarto-scaffold` | Scaffolds a new Quarto project with RRC conventions. Invoke on demand. |
| `quarto-word` | Build Quarto reports that render to Word (.docx) — table patterns, captions, page numbers, and the `fix_docx.R` post-render patch. Invoke on demand. |

## Setup

See the **[setup guide](https://rrc-associates.github.io/claude-rrc-plugins/rrc-R-tools-setup.html)** for step-by-step installation instructions.

## Updating a Skill

Edit the relevant `SKILL.md` in `rrc-R-tools/skills/`, commit, and push. Claude Code picks up the changes on the next plugin update.

When changing a skill, also:

1. Bump the `version` field in `rrc-R-tools/.claude-plugin/plugin.json` following [semver](https://semver.org/) (MAJOR for renames or removals, MINOR for added skills, PATCH for content updates).
2. Add an entry to [`CHANGELOG.md`](CHANGELOG.md) with your name in parentheses.
3. Tag the release: `git tag v1.2.0 && git push origin v1.2.0`.
