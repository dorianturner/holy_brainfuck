#include "../src/ir.hc"
#include "../src/parser.hc"
#include "../src/normalise.hc"
#include "../src/optimise.hc"

/* Assert linear IR matches expected kinds and counts */
Bool AssertIRFlat(PtrVec *ir, I32 *expected_kinds, I64 *expected_counts, I64 expected_len, U8 *msg) {
    if (!ir) {
        "%s: FAIL, null IR\n", msg;
        return False;
    }
    if (ir->size != expected_len) {
        "%s: FAIL, IR length mismatch (expected %lld, got %lld)\n", msg, expected_len, ir->size;
        return False;
    }

    for (I64 i = 0; i < expected_len; i++) {
        Ir *ins = PtrVecGet(ir, i)(Ir*);
        if (!ins || ins->kind != expected_kinds[i] || ins->count != expected_counts[i]) {
            I32 kind = -1;
            I64 count = -1;
            if (ins) {
                kind = ins->kind;
                count = ins->count;
            }
            "%s: FAIL at index %lld (kind %d, count %lld)\n", msg, i, kind, count;
            return False;
        }
    }

    "%s: PASS\n", msg;
    return True;
}

/* Simple program: +++>--< */
U0 TestFlat() {
    Ast *ast = Normalise(Parse(Lex("+++>--<")));
    PtrVec *ir = AstToIr(ast);

    I32 kinds[4]  = {IR_INC, IR_INC_PTR, IR_DEC, IR_DEC_PTR};
    I64 counts[4] = {3, 1, 2, 1};
    AssertIRFlat(ir, kinds, counts, 4, "TestFlat");

    PtrVecRelease(ir);
}

/* Test zeroing loop */
U0 TestZeroLoop() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[-]"))));
    PtrVec *ir = AstToIr(ast);

    I32 kinds[1]  = {AST_ZERO};
    I64 counts[1] = {1};

    AssertIRFlat(ir, kinds, counts, 1, "TestZeroLoop");

    PtrVecRelease(ir);
}

/* Test nested loop */
U0 TestNestedLoop() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[>+<-]"))));
    PtrVec *ir = AstToIr(ast);

    I32 kinds[6]  = {
        IR_LOOP_START,
        IR_INC_PTR,
        IR_INC,
        IR_DEC_PTR,
        IR_DEC,
        IR_LOOP_END
    };
    I64 counts[6] = {1,1,1,1,1,1};

    if (!AssertIRFlat(ir, kinds, counts, 6, "TestNestedLoop")) {
        PtrVecRelease(ir);
        return;
    }

    Ir *loop_start = PtrVecGet(ir, 0)(Ir*);
    Ir *loop_end   = PtrVecGet(ir, 5)(Ir*);
    if (!loop_start || !loop_end ||
        loop_start->jump != 5 ||
        loop_end->jump   != 0) {
        "TestNestedLoop: FAIL, loop jumps (start %lld end %lld)\n", loop_start->jump, loop_end->jump;
    } else {
        "TestNestedLoop: PASS (loop jumps set correctly)\n";
    }

    PtrVecRelease(ir);
}

/* Test add-move loop */
U0 TestAddMoveLoop() {
    Ast *ast = Optimise(Normalise(Parse(Lex("[->+<]"))));
    PtrVec *ir = AstToIr(ast);

    if (!ir || ir->size != 1) {
        "TestAddMoveLoop: FAIL, IR size\n";
        PtrVecRelease(ir);
        return;
    }
    Ir *ins = PtrVecGet(ir, 0)(Ir*);
    if (ins && ins->kind == AST_ADD_MOVE && ins->target_offset == 1 && ins->multiplier == 1)
        "TestAddMoveLoop: PASS\n";
    else
        "TestAddMoveLoop: FAIL, kind or fields\n";

    PtrVecRelease(ir);
}

U0 Main() {
    "Running IR tests...\n";
    TestFlat();
    TestZeroLoop();
    TestNestedLoop();
    TestAddMoveLoop();
    "All IR tests finished\n";
}
