## f77

Simple compiler driver for Fortran 77 (& IV/66)

## Dependencies

1. A working `cc` with gcc-style optimization flags (`-On`)
2. An `f2c` f77 transpiler
3. Sed and bash (for f77 itself)

## Advantages 

* `.f77`, `.F77`, `.for`, `.FOR` FORTRAN77 files support
* all `gcc` and `f2c` flags direct usage (including `-c`, `-o`, `-On`, `-P` `-In`, `-U`, etc.)
* no build artifacts, just a binary
* `-O3` by default
* `error:` and `warning:` highlighting (even for f2c!)
* preprocessing for `.F` files
* full f66 support:
    * you can f77 as `./f66` and it'll act as FORTRAN66 compiler
    * for `.{f,F}66` files F66 behavior with any name
* c api:
    * --extern= to call pure c functions
    * --byval=func= to call c by-value functions
    * (wip) libC bindings

## License

This software is a public domain and licensed under The Unlicense. See `./LICENSE` to get more information
