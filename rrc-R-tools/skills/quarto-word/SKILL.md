---
name: quarto-word
description: Build Quarto reports that render to Word (.docx). Covers the YAML setup, reference-doc style hooks, flextable patterns that actually render in Word, page-number footers, and the fix_docx.R post-render patch for the flextable+Pandoc "unreadable content" bug. Use this skill when starting a new Quarto Word report, troubleshooting a .docx that won't open cleanly, configuring captions or tables for Word output, wiring up a custom reference doc, or porting an existing HTML/PDF Quarto report to Word.
disable-model-invocation: true
---

# Quarto → Word (.docx) Reports

End-to-end recipe for producing reliable, well-formatted `.docx` output from a Quarto `.qmd`. Most of these patterns are subtle gotchas that bite when you switch from HTML/PDF to Word — they're documented here so future-you doesn't relearn them.

For the broader Markdown / Quarto primer (text formatting, lists, parameters, inline R, ggplot, custom styles), see `<your-repos>/primers/quarto_markdown_word`. This skill focuses on the Word-specific moving parts.

---

## YAML setup

A working Word-output YAML looks like this:

```yaml
---
title: "Report Title"
subtitle: "Version 1.1"        # optional
date: today
date-format: long
format:
  docx:
    output-file: "report.docx"           # optional; defaults to <qmd-basename>.docx
    reference-doc: custom-reference.docx # provides Title/Caption/etc. Word styles
    toc: true                            # or false
    toc-depth: 2
    number-sections: true                # optional
    fig-width: 6.5
    fig-height: 4
    fig-dpi: 300
params:
  output_path: "Z:/Shared/.../report_destination"
execute:
  echo: false      # set true to show code in the doc
  warning: false
  message: false
---
```

Key points:

- **`reference-doc`** is the path (relative to the `.qmd`) to a Word document whose paragraph and character styles Quarto will use. Without one, you get pandoc's minimal default styles and things like the Caption style may be absent or invisible — see the "captions silently drop" gotcha below.
- **`date: today` + `date-format: long`** renders something like "May 12, 2026". Other options: `"MMMM D, YYYY"`, `iso`, custom Luxon format strings.
- **`fig-width`/`fig-height`/`fig-dpi`** are sane defaults for letter paper with 1" margins (6.5" content area).
- For parameterized templates, see the `quarto-scaffold` skill.

---

## The reference doc

A Word `.docx` template that defines the styles your report will use: `Title`, `Subtitle`, `Heading 1/2/3`, `Caption`, `Block Text`, `TOC Heading`, etc. Pandoc maps Quarto/Markdown structure to these styles when rendering.

### What lives in it

| Style | Used by |
|---|---|
| `Title`, `Subtitle` | YAML `title` / `subtitle` |
| `Heading 1`–`6` | `#`, `##`, … |
| `Caption` | `tbl-cap`, `fig-cap` |
| `Block Text` | `::: {custom-style="Block Text"}` divs |
| `TOC Heading` | TOC heading paragraph |
| Custom styles | Any `custom-style="X"` reference in the doc |

### Page numbers

**Page numbers live in the reference doc's footer**, not in the `.qmd`. There's no Quarto/Pandoc option to add them at render time.

To add page numbers, either:

1. **Open `custom-reference.docx` in Word** → Insert → Page Number → Bottom of Page → Plain Number 2 → Save. Done.
2. **Or edit the XML directly** if Word isn't available. Add a `word/footer1.xml` with a `PAGE` field, register it in `word/_rels/document.xml.rels` and `[Content_Types].xml`, and reference it in `word/document.xml`'s `<w:sectPr>` via `<w:footerReference w:type="default" r:id="..."/>`. The PAGE field MUST include the `separate` fldChar — `begin → instrText " PAGE " → separate → result "1" → end` — or Word will report "unreadable content".

### Getting a starter reference doc

If you don't have one, the RRC primer at `<your-repos>/primers/quarto_markdown_word/custom-reference.docx` is a known-good starting point with all standard styles plus the styles used by the SEM/MOT templates.

---

## Tables (flextable)

`flextable` is the only table package that renders reliably in Word. Avoid `gt` (HTML-first, can produce broken Word output) and `kableExtra` (no docx support). `knitr::kable()` works but offers no row-level styling.

### The minimal pattern that works

```r
library(flextable)
library(officer)  # provides fp_par, run_autonum, etc. when needed

# Single helper that wraps the conventions
ft_base <- function(df) {
  flextable(df) |>
    theme_vanilla() |>
    align(align = "left", part = "all") |>
    autofit() |>
    fit_to_width(max_width = 6.5)  # US Letter content width with 1" margins
}
```

Then in each table chunk:

````markdown
```{r}
#| label: tbl-my-table
#| tbl-cap: "My table caption"
my_df |> ft_base() |> colformat_double(digits = 2)
```
````

### Captions: use chunk options, not `set_caption()`

`flextable::set_caption(caption = "...")` is **silently dropped** by Quarto's docx pipeline in many setups — the table renders without a caption and no error is raised. Always use Quarto's chunk options instead:

- `#| label: tbl-<name>` — gives the table a cross-reference target (`@tbl-name` in prose)
- `#| tbl-cap: "..."` — the caption text, rendered with the reference doc's `Caption` style

For dynamic captions (computed at runtime), use `!expr`:

```r
#| tbl-cap: !expr 'sprintf("Visits by visitor type in %s", region_name)'
```

### autofit, not `set_table_properties(layout = "autofit")`

These look similar but behave differently:

- ✅ `autofit()` — the **flextable function**. Computes column widths from cell content. This is what you want.
- ❌ `set_table_properties(layout = "autofit", align = "left")` — sets Word's table layout property AND can interact badly with the table-align value. Frequently produces **single-character-wide columns** in docx where header text wraps to one letter per line.

If you also need the table positioned at the left margin of the page (vs centered), Quarto-rendered flextables tend to default to a sensible left position; don't try to "fix" it with `set_table_properties` unless you're hitting an actual problem.

### Wide tables: `fit_to_width()`

`autofit()` lets a wide table overflow the page. To scale it down to fit:

```r
ft |> fit_to_width(max_width = 6.5)  # in inches
```

Only shrinks tables that exceed `max_width`; narrower tables pass through unchanged. Safe to apply unconditionally — make it part of your `ft_base` helper.

### Multi-table chunks (e.g., one table per group)

Quarto's `tbl-cap` chunk option captions **one** table per chunk. For loops that produce multiple tables, captions need to be printed manually in the loop body. Use `results: asis` and `cat()`:

````markdown
```{r}
#| results: asis
for (grp in groups) {
  ft <- build_table(grp) |> ft_base() |> colformat_double(digits = 2)
  cat(sprintf("\n\n**Spending in %s**\n\n", grp))
  cat(knit_print(ft))
  cat("\n\n")
}
```
````

The bold-markdown caption is a pragmatic fallback (proper Word `Caption` style isn't auto-numbered this way, but the captions render reliably).

### Subtotal / total rows: bold + background

```r
ft_base(df) |>
  bold(i = ~ category %in% c("Subtotal", "Total")) |>
  bg(i = ~ category == "Subtotal", bg = "#F2F2F2", part = "body") |>
  bg(i = ~ category == "Total",    bg = "#D9D9D9", part = "body")
```

The `i = ~ <predicate>` formula evaluates against the data; rows where the predicate is `TRUE` get the styling.

### Per-column digits

`colformat_double(digits = N)` applies to all double columns. For per-column control:

```r
ft |>
  colformat_double(j = "weighted_mean",       digits = 4) |>
  colformat_double(j = c("mean", "spending"), digits = 2) |>
  colformat_num(j = "n",                      big.mark = ",")
```

### Global defaults

```r
set_flextable_defaults(
  font.family = "Calibri",
  font.size = 10,
  padding.top = 3,
  padding.bottom = 3,
  border.color = "#666666"
)
```

Call once near the top of the document. All subsequent flextables inherit these.

---

## Figures

Use `ggplot2` for any figure that needs to render in Word. Specifically **avoid `plotly`** — its output is interactive JavaScript and does not survive the docx conversion. `patchwork`, `ggstats::gglikert`, and similar ggplot-based packages are fine.

Standard figure chunk:

````markdown
```{r}
#| label: fig-my-figure
#| fig-cap: "Caption text"
#| fig-alt: "Alt text for 508 compliance"
#| fig-width: 6.5
#| fig-height: 4

ggplot(...) + ...
```
````

Cross-reference with `@fig-my-figure` in prose.

---

## Custom styles in prose

For block-level styling, wrap content in a fenced div:

```markdown
::: {custom-style="Block Text"}
This paragraph uses the "Block Text" style from the reference doc.
:::
```

For inline styling:

```markdown
The rating was [Very Good]{custom-style="Strong"}.
```

The style name must match a style defined in `custom-reference.docx` — if it doesn't, the text falls back to the default paragraph style.

For the title page, the standard pattern (centered title + subtitle, manual page break):

```markdown
::: {custom-style="Title"}
Report Title
:::

::: {custom-style="Subtitle"}
Subtitle text
:::

{{< pagebreak >}}
```

---

## Post-render: fix_docx.R

The flextable → Pandoc → docx pipeline produces invalid OOXML in a few specific ways. The symptoms users see:

- "**Word found unreadable content in <file>.docx. Do you want to recover the contents…**" dialog on open
- Document opens in **Compatibility Mode** (titlebar says "[Compatibility Mode]")
- Document opens as an unsaved "Document1" recovered copy rather than the file itself

`fix_docx.R` (bundled with this skill) patches four known issues:

1. **flextable stray text nodes** (`header1`, `body1`) inside `<w:tr>` elements
2. **Duplicate `<w:pPr>`** blocks Pandoc emits when wrapping a flextable in a cross-reference table
3. **Missing trailing `<w:p>`** in `<w:tc>` cells (OOXML schema requires every cell to end with a paragraph)
4. **AppVersion 12.0** in `docProps/app.xml` (Pandoc lies about being Word 2007) — bumped to 16.0 with `compatibilityMode=15`, fixing Compatibility Mode on open

### Wiring it in

Copy `fix_docx.R` from this skill directory into your project's `scripts/` folder, then source it from your `post_render.R`:

```r
# scripts/post_render.R
library(yaml)

# ... locate the rendered .docx via QUARTO_PROJECT_OUTPUT_FILES ...

source("fix_docx.R")
for (out_file in out_paths) {
  if (grepl("\\.docx$", out_file, ignore.case = TRUE) && file.exists(out_file)) {
    tryCatch(fix_docx(out_file),
             error = function(e) message("fix_docx failed for ", out_file, ": ", e$message))
  }
}

# ... then optionally copy to network destination ...
```

Activate via `_quarto.yml`:

```yaml
project:
  type: default
  post-render:
    - "Rscript post_render.R"
```

For copy-to-network on top of fix_docx, combine with the `quarto-render-sync` skill pattern.

---

## Common gotchas — quick reference

| Symptom | Cause | Fix |
|---|---|---|
| Captions don't appear | `flextable::set_caption()` silently dropped | Use chunk-level `#| tbl-cap:` |
| Columns squeezed to one character wide | `set_table_properties(layout = "autofit")` | Use `autofit()` function instead |
| Wide table cut off at page edge | `autofit()` doesn't bound width | Add `fit_to_width(max_width = 6.5)` |
| "Unreadable content" warning on open | flextable+Pandoc invalid OOXML | Run `fix_docx.R` in post-render |
| Document opens in Compatibility Mode | Pandoc sets AppVersion 12.0 | `fix_docx.R` bumps to 16.0 |
| "run_autonum not found" | Function lives in officer (re-exported in newer flextable) | `library(officer)` |
| `case_match()` deprecation warning | Newer dplyr | Use `case_when()` with `TRUE ~ default` fallback |
| Inline markdown `**bold**` not bolding in flextable cells | Wrong layer | Use `bold(i = ~ ...)` on the flextable, not in cell strings |
| Per-region tables in a loop have no captions | `tbl-cap` is one-per-chunk | `cat()` bold markdown captions inside the loop with `results: asis` |
| Cover image broken when path contains `(` | Markdown `![](path)` parses `)` as URL end | Use `knitr::include_graphics()` instead |

---

## Quick checklist for a new Word report

1. `format: docx` with `reference-doc: custom-reference.docx`
2. `library(flextable)` and `library(officer)` in the setup chunk
3. Define an `ft_base()` helper: `theme_vanilla()` + `align(...)` + `autofit()` + `fit_to_width(6.5)`
4. Use `#| label: tbl-...` and `#| tbl-cap: "..."` on every table chunk
5. `_quarto.yml` post-render hook that sources `fix_docx.R`
6. Reference doc has `Caption` style and (if wanted) a `PAGE` field in `word/footer1.xml`

Render with Ctrl+Shift+K in RStudio/Positron or `quarto render` from the terminal.
