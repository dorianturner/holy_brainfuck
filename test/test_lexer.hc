#include "../src/lexer.hc"
#include "../src/util/bool.hc"

// Assert that the entire token sequence matches the expected kinds
Bool AssertTokens(PtrVec *tokens, I32 *expected, I64 expected_len, U8 *msg) {
    if (tokens->size != expected_len) {
        "%s: FAIL, token count mismatch. Expected %d, got %d\n", msg, expected_len, tokens->size;
        "Expected: ";
        PrintTokenSequence(expected, expected_len, False);
        "Got     : ";
        PrintTokenSequence(tokens, tokens->size, True);
        return False;
    }

    for (I64 i = 0; i < expected_len; i++) {
        Token *t = PtrVecGet(tokens, i)(Token*);
        if (t->kind != expected[i]) {
            "%s: FAIL, mismatch at token index %d\n", msg, i;
            "Expected: ";
            PrintTokenSequence(expected, expected_len, False);
            "Got     : ";
            PrintTokenSequence(tokens, expected_len, True);
            return False;
        }
    }

    "%s: PASS\n", msg;
    return True;
}

// Test all Brainfuck commands
U0 TestAllCommands() {
    U8 *src = "><+-.,[]";
    PtrVec *tokens = Lex(src);

    I32 expected[8] = {TK_INC_PTR, TK_DEC_PTR, TK_INC, TK_DEC, TK_PUT, TK_GET, TK_LOOP_START, TK_LOOP_END};
    AssertTokens(tokens, expected, 8, "TestAllCommands");

    PtrVecRelease(tokens);
}

// Sequence with comments
U0 TestWithComments() {
    U8 *src = "+a>b\n-.,[]z";
    PtrVec *tokens = Lex(src);

    I32 expected[7] = {TK_INC, TK_INC_PTR, TK_DEC, TK_PUT, TK_GET, TK_LOOP_START, TK_LOOP_END};
    AssertTokens(tokens, expected, 7, "TestWithComments");

    PtrVecRelease(tokens);
}

// Empty program
U0 TestEmpty() {
    U8 *src = "";
    PtrVec *tokens = Lex(src);

    if (tokens->size != 0) {
        "TestEmpty: FAIL, expected 0 tokens\n";
    } else {
        "TestEmpty: PASS\n";
    }

    PtrVecRelease(tokens);
}

U0 RunLexerTests() {
    "Running lexer tests...\n";
    TestAllCommands();
    TestWithComments();
    TestEmpty();
    "All lexer tests finished\n";
}

U0 Main() {
    RunLexerTests();
}