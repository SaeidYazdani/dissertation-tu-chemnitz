# PhD Thesis LaTeX Project

This repository contains the LaTeX source, figures, bibliography, and build
scripts for my PhD thesis. It is the result of several years of writing,
rewriting, measuring, debugging, formatting, and polishing.

The project is organized around the requirements and publisher/title-page
workflow used for a dissertation at TU Chemnitz. It may therefore also be useful
as a reference for others preparing a larger LaTeX thesis with similar
university formatting and handover requirements.

The main entry point is `main.tex`; chapter content is split across
chapter-specific directories and included from there.

## Thesis Topic

In short, the thesis is about improving semiconductor testing on automated test
equipment, with a focus on DUT power supplies, measurement bottlenecks, dynamic
control, diagnostics, and the realization of a high-voltage source-measurement
prototype.

## Requirements

Install a LaTeX distribution with the usual command-line tools available on
`PATH`.

- Windows: MiKTeX or TeX Live
- Linux/macOS/WSL: TeX Live
- Required tools for the default build: `latexmk`, `pdflatex`, and `biber`
- Optional: `make`, used by `latexmk -use-make` for make-backed dependency
  generation when available

## Quick Build

Windows:

```bat
make.cmd
```

Linux, macOS, or WSL:

```bash
./make.sh
```

The final thesis PDF is written to:

```text
out/main.pdf
```

The build scripts also build the TU Chemnitz publisher/title-page filler from
`frontmatter/univerlag_publisher_filler.tex` and copy the generated PDF to
`frontmatter/univerlag_publisher_filler.pdf` only when the file content changes.

## Build Options

Show help:

```bat
make.cmd --help
make.cmd /?
```

```bash
./make.sh --help
```

Common options:

```text
--clean                 Remove auxiliary files, keep generated PDFs
--full-clean            Remove out/ and the generated title-page PDF
--clean-all             Alias for --full-clean
--rebuild               Full clean, then build
--tool latexmk          Use latexmk dependency tracking (default)
--tool pdflatex         Use pdflatex + biber + pdflatex + pdflatex
--jobs N                Use N jobs for make-backed dependency generation
--no-parallel           Disable latexmk -use-make and MAKEFLAGS
```

Windows also accepts slash-style variants for several options, for example:

```bat
make.cmd /clean
make.cmd /full-clean
make.cmd /rebuild
make.cmd /tool pdflatex
make.cmd /jobs 8
```

Examples:

```bash
./make.sh --rebuild
./make.sh --tool pdflatex
./make.sh --jobs 8
```

```bat
make.cmd --rebuild
make.cmd --tool pdflatex
make.cmd --jobs 8
```

## Project Structure

```text
.
├── main.tex                         Main thesis entry point
├── prem/                            Preamble, package setup, variables
│   ├── used_packages.tex
│   └── variables.tex
├── frontmatter/                     Title pages, abstracts, acknowledgements,
│                                    abbreviations, symbols
├── chapter_one/                     Introduction and motivation
├── chapter_two/                     State of the art and ATE background
├── chapter_three/                   Case study and measurements
├── chapter_four/                    Virtual DUT concept and prototype
├── chapter_five/                    Diagnostics and DPS-related analysis
├── timevariant_loop/                Time-variant loop and digital control topics
├── ch_smu_prototype_detials/        SMU/HVS prototype details
├── ch_hardware_realization/         Hardware realization chapters
├── ch_the_control_software/         Control software, protocol, FPGA, GUI
├── ch_tests_and_conclusion/         Prototype tests and conclusion
├── backmatter/
│   ├── sources.bib                  Bibliography database
│   └── appendices/                  Appendix material
├── figures/                         Figures and graphics used by the thesis
├── out/                             Generated build output (ignored by Git)
├── make.cmd                         Windows build script
├── make.sh                          Linux/macOS/WSL build script
├── LICENSE
└── README.md
```

## Editing Notes

- Add new thesis content by including it from the relevant chapter `content.tex`
  or chapter main file, then let `main.tex` pull the chapter-level entry point.
- Keep generated files in `out/`; do not edit files there manually.
- Keep bibliography entries in `backmatter/sources.bib`.
- Figures should be stored under `figures/` using stable paths, because many
  chapter files reference them directly.
- The repository intentionally keeps the generated
  `frontmatter/univerlag_publisher_filler.pdf`, because `main.tex` includes it
  through `frontmatter/publisher-titlepages.tex`.
- The layout and title-page handling are tailored to the TU Chemnitz thesis
  workflow. If you reuse this project elsewhere, expect to adapt the
  frontmatter and publisher-specific files.

## Troubleshooting

- If references or citations look stale, run a rebuild:

  ```bash
  ./make.sh --rebuild
  ```

  or on Windows:

  ```bat
  make.cmd --rebuild
  ```

- If `latexmk` is unavailable but `pdflatex` and `biber` are installed, use:

  ```bash
  ./make.sh --tool pdflatex
  ```

  or:

  ```bat
  make.cmd --tool pdflatex
  ```

- If the build fails because a command is missing, confirm that the LaTeX
  distribution's binary directory is on `PATH`.

## Special Thanks

This project also depends on tools and community work that made the thesis
practical to write and illustrate:

- The Inkscape authors and contributors. Inkscape was used extensively to create
  circuit schematics and figures.
- The creator of the
  [Inkscape electric symbols](https://github.com/upb-lea/Inkscape_electric_Symbols)
  library, which provided useful electrical symbols for Inkscape drawings.
- The creators and maintainers of LaTeX and the many LaTeX packages used in
  this project.

## License

See `LICENSE`.
