#include "../src/parser.hc"
#include "../src/lexer.hc"

/* Assert that a flat AST sequence matches expected kinds */
Bool AssertASTFlat(Ast *root, I32 *expected, I64 expected_len, U8 *msg) {
    if (!root) {
        "%s: FAIL, null AST\n", msg;
        return False;
    }

    PtrVec *flat = PtrVecNew(expected_len);
    PtrVec *stack = PtrVecNew(16);
    PtrVecPush(stack, root);

    while (stack->size > 0) {
        Bool ok = True;
        Ast *node = PtrVecPop(stack, &ok)(Ast*);
        if (!node) continue;

        switch (node->kind) {
            case AST_INC_PTR: case AST_DEC_PTR:
            case AST_INC:     case AST_DEC:
            case AST_PUT:     case AST_GET:
                PtrVecPush(flat, node);
                break;

            case AST_LOOP:
                if (node->children) {
                    for (I64 i = node->children->size; i-- > 0; ) {
                        Ast *child = PtrVecGet(node->children, i)(Ast*);
                        if (child) PtrVecPush(stack, child);
                    }
                }
                break;
        }
    }

    if (flat->size != expected_len) {
        "%s: FAIL, AST node count mismatch. Expected %lld, got %lld\n", msg, expected_len, flat->size;
        return False;
    }

    for (I64 i = 0; i < expected_len; i++) {
        Ast *node = PtrVecGet(flat, i)(Ast*);
        if (!node || node->kind != expected[i]) {
            "%s: FAIL, AST mismatch at index %lld\n", msg, i;
            return False;
        }
    }

    "%s: PASS\n", msg;
    return True;
}


U0 TestAllCommands() {
    U8 *src = "><+-.,";
    PtrVec *tokens = Lex(src);
    Ast *ast = Parse(tokens);

    if (!ast || !ast->children) {
        "TestAllCommands: FAIL, null or empty AST\n";
        PtrVecRelease(tokens);
        return;
    }

    I32 expected[6] = {AST_INC_PTR, AST_DEC_PTR, AST_INC, AST_DEC, AST_PUT, AST_GET};
    AssertASTFlat(ast, expected, 6, "TestAllCommands");

    PtrVecRelease(tokens);
}

U0 TestLoop() {
    U8 *src = "+[->+<].";
    PtrVec *tokens = Lex(src);
    Ast *ast = Parse(tokens);

    if (!ast || !ast->children) {
        "TestLoop: FAIL, null or empty AST\n";
        PtrVecRelease(tokens);
        return;
    }

    I32 expected[6] = {AST_INC, AST_DEC, AST_INC_PTR, AST_INC, AST_DEC_PTR, AST_PUT};
    AssertASTFlat(ast, expected, 6, "TestLoop");

    PtrVecRelease(tokens);
}

U0 TestEmpty() {
    U8 *src = "";
    PtrVec *tokens = Lex(src);
    Ast *ast = Parse(tokens);

    if (!ast || !ast->children || ast->children->size == 0) {
        "TestEmpty: PASS\n";
    } else {
        "TestEmpty: FAIL, expected empty AST\n";
    }

    PtrVecRelease(tokens);
}

U0 RunParserTests() {
    "Running parser tests...\n";
    TestAllCommands();
    TestLoop();
    TestEmpty();
    "All parser tests finished\n";
}

U0 Main() {
    RunParserTests();
}
