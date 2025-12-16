#ifndef AST_HC
#define AST_HC "AST_HC"

/* Definitions for the recursive AST for brainfuck */

#define AST_INC_PTR    0
#define AST_DEC_PTR    1
#define AST_INC        2
#define AST_DEC        3
#define AST_PUT        4
#define AST_GET        5
#define AST_LOOP       6

#define AST_ZERO        7   // [-] or [+]
#define AST_ADD_MOVE    8   // [->+<] style
#define AST_MUL_MOVE    9   // multiplication loop

class Ast {
    I32 kind;          // one of the #define constants
    I64 count;         // repetition count
    I64 pos;           // source position
    PtrVec *children;  // used when kind == AST_LOOP
    I64 target_offset;  // used by AST_ADD_MOVE/AST_MUL_MOVE
    I64 multiplier;     // signed scale factor for transfer loops
};

Ast *AstNew(I32 kind, I64 pos) {
    Ast *n = MAlloc(sizeof(Ast));
    n->kind = kind;
    n->count = 1;
    n->pos = pos;
    n->children = NULL;
    n->target_offset = 0;
    n->multiplier = 0;
    return n;
}

Ast *AstNewLoop(I64 pos, PtrVec *children) {
    Ast *n = AstNew(AST_LOOP, pos);
    n->children = children;
    return n;
}

#endif