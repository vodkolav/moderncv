<!-- Repository-specific guidance for AI coding agents working on moderncv -->
# Copilot instructions — moderncv (concise)

Purpose: make AI coding agents productive quickly in this LaTeX package repository.

- **Big picture:** This repo provides a LaTeX document class `moderncv` (see `moderncv.cls`) plus many style modules in the root directory: `moderncvbody*.sty`, `moderncvhead*.sty`, `moderncvfoot*.sty`, `moderncvstyle*.sty`, `moderncvcolor*.sty` and icon sets `moderncvicons*.sty`. The `examples/` folder contains runnable CV templates and `manual/moderncv_userguide.tex` documents usage. Changes must preserve backwards compatibility: this is a public LaTeX class used by users.

- **Where to look first:**
  - `moderncv.cls` — core class and public API (commands like `\moderncvstyle`, `\moderncvcolor`, `\moderncvhead`, `\moderncvbody`, `\moderncvfoot`).
  - `moderncvbody*.sty`, `moderncvhead*.sty`, `moderncvfoot*.sty` — concrete header/body/footer variants. Follow their naming conventions when adding variants.
  - `moderncvstyle*.sty` — glue files that load combinations of head/body/foot.
  - `examples/template.tex` and `JohnnyCoder.tex` — minimal, real-world examples showing expected preamble and commands.
  - `manual/moderncv_userguide.tex` — user-facing documentation; update when API or examples change.

- **Common workflows / commands (concrete):**
  - Produce a CV PDF from Markdown using this repo's template (example used in terminal):

    `pandoc JohnnyCoder.md --template=moderncv.tex -o JohnnyCoder.pdf`

  - Compile a `.tex` example directly (bibliography-aware):

    `pdflatex example.tex && bibtex example || true; pdflatex example.tex; pdflatex example.tex`

  - Build the user manual (pdfLaTeX):

    `pdflatex manual/moderncv_userguide.tex` (run twice if figures/refs require it)

- **Patterns & conventions to follow:**
  - Keep the public API stable: commands defined in `moderncv.cls` (e.g. `\name`, `\title`, `\address`, `\moderncvstyle{...}`, `\moderncvcolor{...}`) are user-facing. Prefer adding new optional hooks rather than changing existing command signatures.
  - New theme/variant files follow the `moderncv<head|body|foot><name>.sty` convention and are usually small wrappers that set lengths/colours and register fonts/symbols.
  - Color schemes live in `moderncvcolor<name>.sty` and must only define colorX values; styles reference these.
  - Icon packs are in files named `moderncvicons*.sty` and interact with provided symbol macros; be conservative when changing icon names.

- **Integration points & engine specifics:**
  - The class contains engine detection (pdfLaTeX vs XeTeX/LuaTeX). Avoid breaking the conditional logic in `moderncv.cls` — use the existing `ifxetex`/`ifluatex` checks.
  - Font loading is conditional; do not unconditionally enable `fontspec` unless you add explicit support for Xe/Lua builds.

- **Tests & verification (manual):**
  - After code changes, regenerate a few example PDFs from `examples/` (use `examples/template.tex` and `JohnnyCoder.tex`) and the manual to ensure no regressions.
  - If your change touches bibliography behavior, test with `examples/publications.bib` and the `\bibliography{publications}` usage in `examples/template.tex`.

- **Files to update when changing public behavior:**
  - `README.md`, `manual/moderncv_userguide.tex`, and at least one `examples/*.tex` demonstrating the new behavior.

- **Licensing / attribution:**
  - This project is under the LaTeX Project Public License (LPPL). Preserve license headers and author attributions when editing source files.

- **What NOT to do:**
  - Do not rename or remove public commands from `moderncv.cls` without a migration path in examples and the manual.
  - Avoid changing binary or font files (`*.fd`, fontawesome files) unless explicitly required.

- If anything above is unclear or you'd like more examples (e.g., how to add a new `moderncvbody` variant), tell me which part and I will expand with a short, concrete example and a test checklist.
