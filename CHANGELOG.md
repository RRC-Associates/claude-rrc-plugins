# Changelog

All notable changes to the `rrc-R-tools` plugin are documented in this file. Documentation-only changes (README, setup guide) are not tracked here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: a skill is renamed or removed (existing references break)
- **MINOR**: a new skill is added
- **PATCH**: an existing skill's content is updated

Each entry lists the contributor in parentheses.

## [1.0.0] — 2026-05-05

### Added
- `r-style`: tidyverse coding style, pipe-based workflows, `here::here()` for repo paths (Cathy)
- `diagnose-before-fixing`: explains errors and identifies root causes before proposing fixes (Cathy)
- `quarto-render-sync`: post-render hook for syncing output to network drives (Cathy)
- `quarto-scaffold`: scaffolds a new Quarto project with RRC conventions (Cathy)
