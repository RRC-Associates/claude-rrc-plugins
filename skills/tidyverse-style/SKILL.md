---
name: tidyverse-style
description: Coding style guide for writing R code in the tidyverse idiom. Use this skill whenever writing, editing, or reviewing R code — including .R scripts, .Rmd files, and code chunks in .qmd documents. Apply it even if the user doesn't explicitly mention tidyverse or style.
---

# Tidyverse-Style R Code

When writing R code, default to tidyverse packages and idioms. The goal is consistency across the team's codebase and readable, pipe-based workflows that are easy for colleagues to follow.

## Core Principles

**Pipe-based workflows** — Structure operations as pipelines rather than nested function calls or chains of temporary variables. Either `|>` or `%>%` is fine; be consistent within a script.

```r
# Good — reads top to bottom
result <- data |>
  filter(year == 2026) |>
  group_by(site) |>
  summarize(mean_count = mean(count, na.rm = TRUE))

# Avoid — nested and harder to follow
result <- summarize(group_by(filter(data, year == 2026), site), mean_count = mean(count, na.rm = TRUE))
```

**dplyr for data manipulation** — Use `filter()`, `mutate()`, `select()`, `summarize()`, `group_by()`, `arrange()`, and `rename()` as the default verbs for working with data frames. Reach for `across()` when applying the same operation to multiple columns.

**tidyr for reshaping** — Use `pivot_longer()` and `pivot_wider()` instead of `reshape()`, `melt()`, or `cast()`. Use `separate()`, `unite()`, `unnest()` when cleaning messy columns.

**ggplot2-based plotting** — Build visualizations with ggplot2 as the default, not base `plot()`, `barplot()`, `hist()`, etc. Use `+` to layer geoms and customize with `theme()`, `labs()`, and `scale_*` functions. Other plotting packages that build on or complement ggplot2 are welcome — for example, `plotly` (including `ggplotly()` for interactive versions of ggplot2 charts), `patchwork`, or `ggiraph`.

**purrr over loops** — Prefer `map()`, `map_dfr()`, `walk()`, and `map2()` for iteration instead of `for` loops. This keeps code in the functional, pipe-friendly style and avoids manual index management. That said, a simple `for` loop is fine when it's genuinely clearer — for example, when each iteration has side effects or the logic is complex enough that `map()` would obscure it.

**readr / readxl for reading data** — Use `read_csv()` instead of `read.csv()`, `read_excel()` instead of `xlsx::read.xlsx()`. These return tibbles and handle types more predictably.

## When Base R Is Fine

Being practical matters more than being pure. Base R is perfectly acceptable when:

- A simple operation doesn't benefit from pipes (e.g., `nrow(df)`, `names(df)`, `length(x)`)
- String operations are simple enough that `paste0()` or `gsub()` is clearer than loading stringr
- You're writing a quick one-off check, not production code
- Package dependencies matter and the base R version is equally readable

The guiding question: **would a colleague reading this code find the tidyverse version easier to follow?** If yes, use tidyverse. If it's a wash, either is fine.

## Package Preferences at a Glance

| Task | Prefer | Instead of |
|---|---|---|
| Read CSV | `readr::read_csv()` | `read.csv()` |
| Read Excel | `readxl::read_excel()` | `xlsx::read.xlsx()` |
| Write Excel | `writexl::write_xlsx()` | `xlsx::write.xlsx()`, `openxlsx::write.xlsx()` |
| Filter rows | `dplyr::filter()` | `subset()`, `df[df$x > 1, ]` |
| Add/modify columns | `dplyr::mutate()` | `transform()`, `df$new <- ...` |
| Summarize | `dplyr::summarize()` | `aggregate()`, `tapply()` |
| Reshape long | `tidyr::pivot_longer()` | `reshape()`, `melt()` |
| Reshape wide | `tidyr::pivot_wider()` | `reshape()`, `dcast()` |
| Iterate | `purrr::map()` | `lapply()`, `for` loops |
| String ops | `stringr::str_*()` | `grep()`, `gsub()`, `sub()` |
| Plotting | `ggplot2`, `plotly`, etc. | `plot()`, `barplot()`, `hist()` |
| Dates | `lubridate::ymd()`, etc. | `as.Date()`, `strptime()` |
