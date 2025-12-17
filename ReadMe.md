# Brainfuck Compiler in HolyC

This project is a full Brainfuck compiler, written in gods chosen language. I made it to understand how compilers work (using an easy language so as to not get bogged down). I also did it to learn a bit about parser combinators in preparation for the Imperial WACC coursework.

## Pipeline
1. **Lexing** - `Lex()` walks the Brainfuck source, ignoring comments/whitespace and producing a flat `PtrVec` of `Token`s.
2. **Parsing** - `Parse()` consumes the tokens and builds a nested AST of `Ast` nodes, managing `[`/`]` structure.
3. **Normalisation** - `Normalise()` collapses adjacent identical operations (e.g. `+++` -> one `AST_INC` with `count=3`) and recursively normalises loop bodies.
4. **Optimisation** - `Optimise()` recognises some Brainfuck idioms: zeroing loops, pointer-transfer loops (add/mul moves), and rewrites them into specialised AST node kinds with metadata (`target_offset`, `multiplier`). I need to redo this with function pointers as the current approach is kind of not extensible at all.
5. **IR Flattening** - `AstToIr()` traverses the optimised AST and returns a linear IR (`Ir` class vector) so later stages never have to reason about nesting. I need to add an optimisation step to this IR, maybe it could be even better.
6. **Assembly Generation** - `Generate()` linearises the IR into NASM-style x86_64 assembly, mapping each IR opcode to the appropriate instructions and loop labels.
7. **Object + Executable** - `hbf` shells out to `nasm -felf64` and `gcc -no-pie` to assemble the `.asm` into an ELF object and link it into a runnable binary alongside libc’s `putchar/getchar`.

## Usage
```sh
make                # builds bin/hbf via hcc
sudo make install   # optional: installs hbf to /usr/local/bin, just trust me ;)

hbf program.bf      # emits program.asm, assembles and links program
./program           # run the compiled Brainfuck binary
```

### Requirements
- HolyC standalone compiler `github.com/Jamesbarford/holyc-lang`
- NASM
- GCC (for linking)


I made this on Ubuntu :( , so if you want it to work on something actually useful like NixOS, you'll have to deal with the devshells and flake.nix's yourself.

With those tools on PATH, the project builds with `make` and the `hbf` binary can turn any `.bf` file directly into a native executable.


## TODO: Improvements
 - Redo the optimisation to be extensible with function pointers and add more optimisations, e.g. initial loop comment
 - See if I can optimise the IR further
 - Simplify the generate stage if I can
 - Maybe make this concurrent !?!?