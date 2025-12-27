## f77

Simple compiler driver for Fortran 77

## Dependencies

1. A working `cc` with gcc-style optimization flags (`-On`)
2. An `f2c` f77 transpiler
3. Sed and bash (for f77 itself)

## Advantages 

* `.f77` files support
* all `gcc` and `f2c` flags direct usage (including `-c`, `-o`, `-On`, `-P` `-In`, `-U`, etc.)
* no build artifacts, just a binary
* `-O3` by default
* `error:` and `warning:` highlighting (even for f2c!)
* preprocessing for `.F` files

## License

This software is a public domain and licensed under The Unlicense. See `./LICENSE` to get more information
