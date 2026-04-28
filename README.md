# My PhD Thesis

This repository contains the LaTeX source files, figures, and supporting material for my PhD thesis.

## Structure

- `main.tex` — main thesis entry point
- `frontmatter/` — title pages, abstract, acknowledgments, etc.
- `backmatter/` — bibliography and appendices
- `chapter_*` and `ch_*` — thesis chapters
- `figures/` — figures and graphics
- `prem/` — preamble and configuration files
- `timevariant_loop/` — additional thesis material
- `make.cmd` / `make.sh` — build scripts

## Build

### Windows
```
make.cmd
```

### Linux / macOS / WSL
```
./make.sh
```

## Notes

- The `out/` directory contains build artifacts and is ignored by Git.
- Ensure LaTeX (e.g., TeX Live or MiKTeX) is installed.

## License

See `LICENSE`.
# dissertation-tu-chemnitz
