#include "../src/lexer.hc"
#include "../src/parser.hc"
#include "../src/normalise.hc"
#include "../src/optimise.hc"
#include "../src/ir.hc"
#include "../src/generate.hc"

U8* BuildOutputPath(U8 *input_path) {
    if (input_path == NULL) return NULL;
    I64 len = StrLen(input_path);
    I64 cut = len;
    for (I64 i = len - 1; i >= 0; i--) {
        if (input_path[i] == '/') break;
        if (input_path[i] == '.') {
            cut = i;
            break;
        }
    }
    I64 out_len = cut + 4; // .asm
    U8 *out = MAlloc(out_len + 1);
    MemCpy(out, input_path, cut);
    out[cut + 0] = '.';
    out[cut + 1] = 'a';
    out[cut + 2] = 's';
    out[cut + 3] = 'm';
    out[cut + 4] = 0;
    return out;
}

U0 ReleaseTokens(PtrVec *tokens) {
    if (tokens == NULL) return;
    for (I64 i = 0; i < tokens->size; i++) {
        Token *t = PtrVecGet(tokens, i)(Token*);
        if (t) Free(t);
    }
    PtrVecRelease(tokens);
}

U0 ReleaseIr(PtrVec *ir_list) {
    if (ir_list == NULL) return;
    for (I64 i = 0; i < ir_list->size; i++) {
        Ir *ins = PtrVecGet(ir_list, i)(Ir*);
        if (ins) Free(ins);
    }
    PtrVecRelease(ir_list);
}

Bool RunCommand(U8 *cmd) {
    if (cmd == NULL) return False;
    I32 status = System(cmd);
    if (status != 0) {
        "Command failed (%d): %s\n", status, cmd;
        Free(cmd);
        return False;
    }
    Free(cmd);
    return True;
}

Bool CompileFile(U8 *input_path, U8 *output_path) {
    I64 src_len = 0;
    U8 *source = FileRead(input_path, &src_len);
    if (source == NULL) {
        "Failed to read %s\n", input_path;
        return False;
    }

    PtrVec *tokens = Lex(source);
    Free(source);
    if (tokens == NULL) {
        "Lexing failed for %s\n", input_path;
        return False;
    }

    Ast *ast = Parse(tokens);
    ReleaseTokens(tokens);
    if (ast == NULL) {
        "Parsing failed for %s\n", input_path;
        return False;
    }

    ast = Normalise(ast);
    ast = Optimise(ast);

    PtrVec *ir = AstToIr(ast);
    if (ir == NULL) {
        "Failed to build IR\n";
        return False;
    }

    Bool ok = Generate(output_path, ir);
    ReleaseIr(ir);
    if (!ok) {
        "Failed to write %s\n", output_path;
        return False;
    }

    U8 *base = StrPrint(NULL, "%s", output_path);
    U8 *dot = FileExtDot(base);
    if (dot) *dot = 0;


    // Now need to link and make an executable
    U8 *obj_path = StrPrint(NULL, "%s.o", base);
    U8 *asm_cmd = StrPrint(NULL, "nasm -felf64 %s -o %s", output_path, obj_path);
    Bool asm_ok = RunCommand(asm_cmd);
    if (!asm_ok) {
        Free(obj_path);
        Free(base);
        return False;
    }

    U8 *exe_cmd = StrPrint(NULL, "gcc -no-pie %s -o %s", obj_path, base);
    Bool exe_ok = RunCommand(exe_cmd);

    Free(obj_path);
    Free(base);

    if (!exe_ok)
        return False;

    return True;
}

U0 Main(I32 argc, U8 **argv) {
    if (argc < 2) {
        "Usage: hbf <input.bf>\n";
        return;
    }

    U8 *input_path = argv[1];
    U8 *output_path = BuildOutputPath(input_path);
    if (output_path == NULL) {
        "Failed to build output path\n";
        return;
    }

    if (!CompileFile(input_path, output_path)) {
        "Compilation failed for %s\n", input_path;
    }

    Free(output_path);
}
