/* Linear Intermediate Representation for Brainfuck */

#include "../src/util/bool.hc"
#include "../src/ast.hc"

/* IR instruction kinds */
#define IR_INC_PTR    0
#define IR_DEC_PTR    1
#define IR_INC        2
#define IR_DEC        3
#define IR_PUT        4
#define IR_GET        5
#define IR_LOOP_START 6
#define IR_LOOP_END   7
#define IR_ZERO       8
#define IR_ADD_MOVE   9
#define IR_MUL_MOVE   10

class Ir {
    I32 kind;          // instruction kind
    I64 count;         // repetition count for inc/dec/move
    I64 target_offset; // for ADD_MOVE/MUL_MOVE or jump target
    I64 multiplier;    // signed scale factor for transfer loops
    I64 jump;          // index to jump to for loops
};

/* Allocate a new IR instruction */
Ir *IrNew(I32 kind) {
    Ir *ins = MAlloc(sizeof(Ir));
    ins->kind = kind;
    ins->count = 1;
    ins->target_offset = 0;
    ins->multiplier = 0;
    ins->jump = -1;
    return ins;
}

/* Recursive helper to flatten AST into linear IR */
U0 FlattenAstList(PtrVec *ir_list, PtrVec *ast_list) {
    for (I64 i = 0; i < ast_list->size; i++) {
        Ast *n = PtrVecGet(ast_list, i)(Ast*);
        if (!n) continue;

        switch [n->kind] {
            case AST_INC_PTR:
            case AST_DEC_PTR:
            case AST_INC:
            case AST_DEC:
            case AST_PUT:
            case AST_GET: {
                    Ir *ins = IrNew(n->kind);
                    ins->count = n->count;
                    PtrVecPush(ir_list, ins);
                    break;
            }

            case AST_ZERO:
            case AST_ADD_MOVE:
            case AST_MUL_MOVE: {
                    Ir *ins = IrNew(n->kind);
                    ins->target_offset = n->target_offset;
                    ins->multiplier = n->multiplier;
                    PtrVecPush(ir_list, ins);
                    break;
            }

            case AST_LOOP: {
                    Ir *loop_start = IrNew(IR_LOOP_START);
                    I64 start_idx = ir_list->size;
                    PtrVecPush(ir_list, loop_start);

                    FlattenAstList(ir_list, n->children);

                    Ir *loop_end = IrNew(IR_LOOP_END);
                    I64 end_idx = ir_list->size;
                    loop_start->jump = end_idx;
                    loop_end->jump = start_idx;
                    PtrVecPush(ir_list, loop_end);
                    break;
            }
        }
    }

}

/* Flatten an AST into a linear IR list */
PtrVec* AstToIr(Ast *root) {
    PtrVec *ir_list = PtrVecNew(64);
    if (!root || !root->children) return ir_list;
    FlattenAstList(ir_list, root->children);
    return ir_list;
}
