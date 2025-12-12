#include "../src/lexer.hc"

// Helper: assert that a token at index has expected kind
U0 AssertTokenKind(PtrVec *tokens, I64 index, I32 expected_kind, U8 *msg) {
    Token *t = PtrVecGet(tokens, index)(Token*);
    if (t->kind != expected_kind) {
        "%s at token index %d\n", msg, index;
    }
}

// Test 1: All Brainfuck commands
U0 TestAllCommands() {
    U8 *src = "><+-.,[]";
    PtrVec *tokens = Lex(src);

    I32 expected[8] = {TK_INC_PTR, TK_DEC_PTR, TK_INC, TK_DEC, TK_PUT, TK_GET, TK_LOOP_START, TK_LOOP_END};
    for (I64 i = 0; i < 8; i++) {
        AssertTokenKind(tokens, i, expected[i], "TestAllCommands failed");
    }

    "TestAllCommands passed\n";
    PtrVecRelease(tokens);
}

// Test 2: Sequence with ignored characters
U0 TestWithComments() {
    U8 *src = "+a>b\n-.,[]z";
    PtrVec *tokens = Lex(src);

    I32 expected[7] = {TK_INC, TK_INC_PTR, TK_DEC, TK_PUT, TK_GET, TK_LOOP_START, TK_LOOP_END};
    for (I64 i = 0; i < 7; i++) {
        AssertTokenKind(tokens, i, expected[i], "TestWithComments failed");
    }

    "TestWithComments passed\n";
    PtrVecRelease(tokens);
}

// Test 3: Empty program
U0 TestEmpty() {
    U8 *src = "";
    PtrVec *tokens = Lex(src);

    if (tokens->size != 0) {
        "TestEmpty failed: expected 0 tokens\n";
    } else {
        "TestEmpty passed\n";
    }

    PtrVecRelease(tokens);
}

// Test 4: Nested loops
U0 TestNestedLoops() {
    U8 *src = "[[++>--]]";
    PtrVec *tokens = Lex(src);

    I32 expected[9] = {TK_LOOP_START, TK_LOOP_START, TK_INC, TK_INC, TK_INC_PTR, TK_DEC, TK_DEC, TK_LOOP_END, TK_LOOP_END};
    for (I64 i = 0; i < 9; i++) {
        AssertTokenKind(tokens, i, expected[i], "TestNestedLoops failed");
    }

    "TestNestedLoops passed\n";
    PtrVecRelease(tokens);
}

// Run all lexer tests
U0 RunLexerTests() {
    "Running lexer tests...\n";
    TestAllCommands();
    TestWithComments();
    TestEmpty();
    TestNestedLoops();
    "All lexer tests finished\n";
}


U0 Main()
{
    RunLexerTests();
}