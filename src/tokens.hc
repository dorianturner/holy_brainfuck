/* Token Specification: https://en.wikipedia.org/wiki/Brainfuck */

// Brainfuck token types
#define TK_INC_PTR    0   // >
#define TK_DEC_PTR    1   // <
#define TK_INC        2   // +
#define TK_DEC        3   // -
#define TK_PUT        4   // .
#define TK_GET        5   // ,
#define TK_LOOP_START 6   // [
#define TK_LOOP_END   7   // ]

class Token {
    I32 kind;    // one of TK_* constants
    I64 pos;     // position in source code
};