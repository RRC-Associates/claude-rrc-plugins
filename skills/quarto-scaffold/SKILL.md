---
name: quarto-scaffold
description: Scaffold a new Quarto project with the right folder structure, _quarto.yml, template .qmd, setup chunk, and .gitignore. Use this skill when the user wants to start a new Quarto project, create a new .qmd report, set up a Quarto analysis, or initialize a project folder for R/Quarto work.
disable-model-invocation: true
argument-hint: [project-name]
---

# Quarto Project Scaffolding

Set up a new Quarto project following RRC team conventions. Ask the user the questions below, then generate the files.

## Step 1: Gather Requirements

Ask the user (skip anything they've already answered):

1. **Project name** — Used for the folder name (snake_case or kebab-case).
2. **Output format** — HTML report, Word document (.docx), or both?
3. **Is this parameterized?** — Will the same report be run for multiple sites/parks/datasets? If yes, ask what the key parameters are (e.g., park code, survey year, data file path).
4. **Network sync?** — Should rendered output be copied to a shared drive (Egnyte/Z: drive)? If yes, include post-render hook setup.

## Step 2: Create the Project Structure

### Standard folder layout

```
project-name/
├── _quarto.yml
├── project-name.Rproj
├── .gitignore
├── report.qmd               # or a descriptive name based on the project
├── output/                   # rendered output (gitignored)
└── scripts/                  # helper R scripts
```

Data typically lives on a network drive (Z: / Egnyte), not in the repo. Data paths are passed via `params` in the .qmd YAML. The repo contains only scripts and rendered output.

If the project is parameterized with site-specific runs, use the numbered-prefix pattern:

```
project-name/
├── _quarto.yml
├── project-name.Rproj
├── .gitignore
├── 00_template_scripts/
│   └── report_template.qmd  # master template
├── 01_site_scripts/
│   ├── 01_SITE1/
│   │   └── report.qmd       # site-specific overrides
│   └── 02_SITE2/
│       └── report.qmd
├── output/
└── scripts/
```

### _quarto.yml

For a standard project:

```yaml
project:
  type: default
```

If network sync is needed, add the post-render hook:

```yaml
project:
  type: default
  post-render:
    - "Rscript post_render.R"
```

Then create `post_render.R` following the pattern from the `quarto-render-sync` skill (if available), or note that the user should set it up with `/rrc-R-tools:quarto-render-sync`.

### .Rproj file

```
Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: Default

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

AutoAppendNewline: Yes
StripTrailingWhitespace: Yes
```

### .gitignore

```
# R / RStudio
.Rproj.user/
.Rhistory
.RData
.Ruserdata

# Quarto
/.quarto/
**/*.quarto_ipynb
*_files/

# Rendered output
output/
*.html
*.docx
```

## Step 3: Create the Template .qmd

### HTML format

```yaml
---
title: "Report Title"
date: today
format:
  html:
    theme: cosmo
    toc: true
    toc-depth: 3
    embed-resources: true
editor: visual
execute:
  echo: false
  warning: false
  message: false
---
```

### Word (.docx) format

```yaml
---
title: "Report Title"
format:
  docx:
    toc: false
    number-sections: true
    fig-width: 6.5
    fig-height: 4
    fig-dpi: 300
editor: visual
execute:
  echo: false
  warning: false
  message: false
---
```

If the user has a custom reference doc (`custom-reference.docx`), add `reference-doc: custom-reference.docx` under the `docx:` key.

### Parameterized version

Add a `params` block with sensible defaults. Common parameters for RRC projects:

```yaml
params:
  park: "SITE"
  year_survey: 2026
  data_path: ""
  output_path: ""
```

Use params in the title with inline R:

```yaml
title: "`r paste(params$park, params$year_survey)`"
subtitle: "`r paste0('Project Name - ', params$park)`"
date: "`r format(Sys.Date(), '%B %d, %Y')`"
```

### Setup chunk

Every .qmd should start with a setup chunk:

````markdown
```{r}
#| label: setup
#| include: false

library(tidyverse)
library(haven)
library(scales)

knitr::opts_chunk$set(
  echo = FALSE,
  include = TRUE,
  message = FALSE,
  warning = FALSE
)
```
````

Add additional libraries based on the project needs:
- **Tables:** `gt` for HTML, `flextable` for Word
- **Excel I/O:** `readxl`, `writexl`
- **Spatial/maps:** `sf`, `leaflet`
- **Interactive plots:** `plotly`
- **RRC utilities:** `RrcUtils`

## Step 4: Confirm with the User

After generating all files, summarize what was created and remind the user:

- Open the `.Rproj` file in RStudio/Positron to start working
- Update the `params` block with real values before rendering
- Render with Ctrl+Shift+K or `quarto render` from the terminal
- If post-render sync was included, set the `output_path` parameter to the network destination
