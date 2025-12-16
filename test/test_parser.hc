#include "../src/parser.hc"
#include "../src/normalise.hc"
#include "../src/optimise.hc"
#include "../src/lexer.hc"

/* Flatten AST into a linear list (ignores loop nodes themselves) */
PtrVec* FlattenAst(Ast *root) {
    PtrVec *flat  = PtrVecNew(16);
    PtrVec *stack = PtrVecNew(16);

    if (root) {
        PtrVecPush(stack, root);
    }

    while (stack->size > 0) {
        Bool ok = True;
        Ast *n = PtrVecPop(stack, &ok)(Ast*);
        if (!n) {
            continue;
        }

        switch (n->kind) {
            case AST_INC_PTR:
            case AST_DEC_PTR:
            case AST_INC:
            case AST_DEC:
            case AST_PUT:
            case AST_GET:
            case AST_ZERO:
            case AST_ADD_MOVE:
            case AST_MUL_MOVE:
                PtrVecPush(flat, n);
                break;

            case AST_LOOP:
                if (n->children) {
                    for (I64 i = n->children->size; i-- > 0; ) {
                        PtrVecPush(
                            stack,
                            PtrVecGet(n->children, i)(Ast*)
                        );
                    }
                }
                break;
        }
    }

    return flat;
}

Bool AssertAst(
    Ast *root,
    I32 *expected_kinds,
    I64 *expected_counts,
    I64 expected_len,
    U8 *msg
) {
    if (root == NULL) {
        "%s: FAIL (null AST)\n", msg;
        return False;
    }

    PtrVec *flat = FlattenAst(root);

    if (flat->size != expected_len) {
        "%s: FAIL (expected %lld nodes, got %lld)\n",
            msg, expected_len, flat->size;
        return False;
    }

    for (I64 i = 0; i < expected_len; i++) {
        Ast *n = PtrVecGet(flat, i)(Ast*);
        if (n == NULL) {
            "%s: FAIL (null node at %lld)\n", msg, i;
            return False;
        }

        if (n->kind != expected_kinds[i]) {
            "%s: FAIL (kind mismatch at %lld)\n", msg, i;
            return False;
        }

        if (expected_counts) {
            if (n->count != expected_counts[i]) {
                "%s: FAIL (count mismatch at %lld)\n", msg, i;
                return False;
            }
        }
    }

    "%s: PASS\n", msg;
    return True;
}


/* Parser: flat commands */
U0 TestFlatParse() {
    Ast *ast = Parse(Lex("><+-.,"));

    I32 kinds[6] = {
        AST_INC_PTR,
        AST_DEC_PTR,
        AST_INC,
        AST_DEC,
        AST_PUT,
        AST_GET
    };

    AssertAst(ast, kinds, NULL, 6, "TestFlatParse");
}

/* Parser: loop nesting and order */
U0 TestLoopParse() {
    Ast *ast = Parse(Lex("+[->+<]."));

    I32 kinds[6] = {
        AST_INC,
        AST_DEC,
        AST_INC_PTR,
        AST_INC,
        AST_DEC_PTR,
        AST_PUT
    };

    AssertAst(ast, kinds, NULL, 6, "TestLoopParse");
}

/* Normalisation: collapse adjacent ops */
U0 TestNormalise() {
    Ast *ast = Normalise(Parse(Lex("+++--->>><<<")));

    I32 kinds[4] = {
        AST_INC,
        AST_DEC,
        AST_INC_PTR,
        AST_DEC_PTR
    };

    I64 counts[4] = {
        3,
        3,
        3,
        3
    };

    AssertAst(ast, kinds, counts, 4, "TestNormalise");
}

U0 TestOptimiseZeroLoop() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[-]"))));
    if (!ast || !ast->children || ast->children->size != 1) {
        "TestOptimiseZeroLoop: FAIL (structure)\n";
        return;
    }
    Ast *node = PtrVecGet(ast->children, 0)(Ast*);
    if (node && node->kind == AST_ZERO)
        "TestOptimiseZeroLoop: PASS\n";
    else
        "TestOptimiseZeroLoop: FAIL (kind)\n";
}

U0 TestOptimiseAddMove() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[->+<]"))));
    if (!ast || !ast->children || ast->children->size != 1) {
        "TestOptimiseAddMove: FAIL (structure)\n";
        return;
    }
    Ast *node = PtrVecGet(ast->children, 0)(Ast*);
    if (node && node->kind == AST_ADD_MOVE &&
        node->target_offset == 1 && node->multiplier == 1)
        "TestOptimiseAddMove: PASS\n";
    else
        "TestOptimiseAddMove: FAIL (kind or fields)\n";
}

U0 TestOptimiseMulMove() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[->+++<]"))));
    if (!ast || !ast->children || ast->children->size != 1) {
        "TestOptimiseMulMove: FAIL (structure)\n";
        return;
    }
    Ast *node = PtrVecGet(ast->children, 0)(Ast*);
    if (node && node->kind == AST_MUL_MOVE &&
        node->target_offset == 1 && node->multiplier == 3)
        "TestOptimiseMulMove: PASS\n";
    else
        "TestOptimiseMulMove: FAIL (kind or fields)\n";
}

/* Empty program */
U0 TestEmpty() {
    Ast *ast = Parse(Lex(""));

    if (!ast || !ast->children || ast->children->size == 0) {
        "TestEmpty: PASS\n";
    } else {
        "TestEmpty: FAIL\n";
    }
}


U0 Main() {
    "Running tests...\n";
    TestFlatParse();
    TestLoopParse();
    TestNormalise();
    TestOptimiseZeroLoop();
    TestOptimiseAddMove();
    TestOptimiseMulMove();
    TestEmpty();
    "All tests finished\n";
}
