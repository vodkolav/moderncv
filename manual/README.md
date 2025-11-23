**Frontmatter to moderncv (Pandoc) — Quick Guide**

This document explains how Pandoc frontmatter keys (YAML metadata) are mapped
to the LaTeX personal-data macros used by the `moderncv` template when using
the included Lua filter `pandoc-filters/moderncv.lua`.

**Why**: the Lua filter injects LaTeX macro lines into `header-includes`, so
they appear in the template preamble before `\makecvtitle` and become the
personal data shown in the CV header.

- **name / firstname + lastname**: preferred keys are `firstname` and
  `lastname` (two separate strings). If only `name` is present the filter
  splits on the first whitespace into first/last. These map to:

  - `\\name{<firstname>}{<lastname>}`

- **title**:

  - `\\title{...}`

- **address**: a single string (comma-separated) is split into up to three
  parts: street, city, country. Example: `address: "Street 1, Mytown, Country"`.
  Maps to:

  - `\\address{<street>}{<city>}{<country>}`

- **phone / phones**: either a single `phone: "+1 ..."` (defaults to
  `mobile`) or a map `phones:` with keys like `mobile`, `fixed`, `fax`.

  - `\\phone[mobile]{...}` or `\\phone[fixed]{...}`

- **email**:

  - `\\email{...}`

- **homepage / url**:

  - `\\homepage{...}`

- **social**: a mapping of social networks to account names or URLs. Supported
  social types used by the class include `linkedin`, `twitter`, `github`,
  `gitlab`, `xing`, `skype` (others are ignored by the class).

  - `social:`
    `  github: Johnny-Coder`
    maps to `\\social[github]{Johnny-Coder}`

Example frontmatter (YAML at top of a Markdown file):

```
name: Johnny Coder
title: Curriculum Vitae
email: email@example.com
phone: +00 (0)00 000 0000
address: Mytown, Mycountry
homepage: www.johndoe.com
social:
  github: Johnny-Coder
  linkedin: Johnny-Coder
  twitter: jdoe
```

Usage (generate intermediate TeX):

```bash
pandoc -s markdown/YourResume.md \\
  --lua-filter=pandoc-filters/moderncv.lua \\
  --template=moderncv.tex -o output/YourResume.tex
```

Then compile the generated TeX with `pdflatex` (run twice):

```bash
pdflatex -interaction=nonstopmode -halt-on-error output/YourResume.tex
pdflatex -interaction=nonstopmode -halt-on-error output/YourResume.tex
```

Notes and recommendations
- Prefer `firstname`/`lastname` keys for multi-part names (splitting `name`
  on the first whitespace is lossy).
- For structured addresses you can provide comma-separated parts; the filter
  will place them into the three `\\address` arguments.
- `phones` may be provided as a map for multiple phone types.
- The filter injects LaTeX macros into `header-includes`. The template
  `moderncv.tex` includes these before `\\makecvtitle` so the title is
  populated correctly.

If you want different behaviour (e.g., richer parsing for names or address
fields), the Lua filter `pandoc-filters/moderncv.lua` can be extended.
