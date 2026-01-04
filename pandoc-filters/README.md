# Markdown to moderncv Filter

This Pandoc Lua filter converts a Markdown file into a LaTeX resume using the `moderncv` class. It maps YAML frontmatter to `moderncv`'s personal information macros and converts Markdown definition lists into formatted CV entries.

## Usage

To use this filter, invoke Pandoc with the following command, specifying your Markdown file and this Lua filter.

```bash
pandoc your-resume.md --from markdown --to latex --lua-filter=moderncv.lua -o output.tex
```

You must also use a `moderncv`-compatible Pandoc template, such as the `moderncv.tex` file provided in the parent directory.

## Metadata (YAML Frontmatter)

Personal information is provided in a YAML frontmatter block at the top of your Markdown file. The filter injects this information into the LaTeX header.

### Supported Fields

*   `name`: Your full name. Can also use `firstname` and `lastname`.
*   `title`: The title of the document (e.g., "Curriculum Vitae").
*   `address`: Your mailing address.
*   `phone` or `phones`: Your phone number(s).
*   `email`: Your email address.
*   `homepage` or `url`: Your personal website.
*   `social`: A map of social media networks to usernames (e.g., `github: myuser`).
*   `photo`: Path to a photo.
*   `quote`: A brief quote.
*   `extrainfo`: Any additional information.

### Example Frontmatter

```yaml
---
firstname: Johnny
lastname: Coder
title: Curriculum Vitae
address: "123 Parkway Drive, Mytown, Mycountry"
phone: "+00 (0)00 000 0000"
email: "email@example.com"
homepage: "www.johnnycoder.com"
social:
  github: Johnny-Coder
  linkedin: johnny-coder
---
```

## CV Entries

The main content of your resume is created using Markdown definition lists under standard `#` and `##` section headings. The filter supports two main entry types, which map to `\cventry` and the `\cvitem` family of macros. Inline formatting like **bold**, *italic*, `code`, and [links](http://example.com) is preserved.

### Detailed Entries (`\cventry`)

A detailed entry consists of a definition list item followed immediately by one or more regular blocks (paragraphs, bullet points, etc.). This is ideal for describing experiences like jobs or projects.

The definition can contain up to four fields, separated by `|`.

**Markdown Syntax:**
```markdown
# Experience

**Lead Developer**
: 2020--Present | Awesome Corp, Inc. | Silicon Valley

A detailed description of the job.

* Developed and maintained critical software infrastructure.
* Mentored junior developers and led code reviews.
```

**Resulting LaTeX:**
```latex
\cventry{2020--Present}{Lead Developer}{Awesome Corp, Inc.}{Silicon Valley}{}{
A detailed description of the job.
\begin{itemize}
\item Developed and maintained critical software infrastructure.
\item Mentored junior developers and led code reviews.
\end{itemize}
}
```

### Compact Entries (`\cvitem`, `\cvdoubleitem`, etc.)

A compact entry is a standalone definition list item. It is used for lists of skills, qualifications, or publications where a long description is not needed. The specific `moderncv` macro is chosen automatically based on the number of `|`-separated fields in the definition.

*   0-1 Fields: `\cvitem`
*   2 Fields: `\cvitemwithcomment`
*   3+ Fields: `\cvdoubleitem`

**Markdown Syntax:**
```markdown
# Skills

**Programming**
: C++, Python, Lua, JavaScript

**Languages**
: English (Native) | French (Fluent)
```

**Resulting LaTeX:**
```latex
\cvitem{Programming}{C++, Python, Lua, JavaScript}
\cvitemwithcomment{Languages}{English (Native)}{French (Fluent)}
```