/* Optimisation pass to optimise the AST */

// TODO: Make this whole file use rewriter callbacks with function pointers

#include "../src/util/bool.hc"
#include "../src/ast.hc"

/* Check if a loop is a zeroing loop: [-] or [+] */
Bool IsZeroLoop(Ast *loop) {
    if (loop == NULL) return False;
    if (loop->kind != AST_LOOP) return False;
    if (loop->children == NULL) return False;
    if (loop->children->size != 1) return False;

    Ast *child = PtrVecGet(loop->children, 0)(Ast*);
    if (child == NULL) return False;
    if (child->count != 1) return False;
    if (child->kind != AST_INC && child->kind != AST_DEC) return False;

    return True;
}

Bool IsTransferLoop(Ast *loop, I64 *ptr_delta, I64 *amount) {
    if (loop == NULL) return False;
    if (loop->kind != AST_LOOP) return False;
    if (loop->children == NULL) return False;

    PtrVec *children = loop->children;
    if (children->size != 4) return False;

    Ast *dec       = PtrVecGet(children, 0)(Ast*);
    Ast *move_out  = PtrVecGet(children, 1)(Ast*);
    Ast *arith     = PtrVecGet(children, 2)(Ast*);
    Ast *move_back = PtrVecGet(children, 3)(Ast*);
    if (dec == NULL || move_out == NULL || arith == NULL || move_back == NULL) return False;

    if (dec->kind != AST_DEC || dec->count != 1) return False;
    if (move_out->kind != AST_INC_PTR && move_out->kind != AST_DEC_PTR) return False;
    if (move_back->kind != AST_INC_PTR && move_back->kind != AST_DEC_PTR) return False;
    if (move_out->kind == AST_INC_PTR && move_back->kind != AST_DEC_PTR) return False;
    if (move_out->kind == AST_DEC_PTR && move_back->kind != AST_INC_PTR) return False;
    if (move_out->count != move_back->count) return False;
    if (arith->kind != AST_INC && arith->kind != AST_DEC) return False;

    if (ptr_delta != NULL) {
        I64 offset = move_out->count;
        if (move_out->kind == AST_DEC_PTR)
            offset = -offset;
        *ptr_delta = offset;
    }

    if (amount != NULL) {
        I64 value = arith->count;
        if (arith->kind == AST_DEC)
            value = -value;
        *amount = value;
    }

    return True;
}

/* Recursively optimise an AST list */
PtrVec* OptimiseList(PtrVec *in) {
    PtrVec *out = PtrVecNew(in->size);
    for (I64 i = 0; i < in->size; i++) {
        Ast *n = PtrVecGet(in, i)(Ast*);
        if (n == NULL) continue;

        /* Recurse into loops */
        if (n->kind == AST_LOOP && n->children != NULL) {
            n->children = OptimiseList(n->children);

            if (IsZeroLoop(n)) {
                PtrVecRelease(n->children);
                n->children = NULL;
                n->kind = AST_ZERO;
                n->target_offset = 0;
                n->multiplier = 0;
            } else {
                I64 offset = 0;
                I64 amount = 0;
                if (IsTransferLoop(n, &offset, &amount)) {
                    PtrVecRelease(n->children);
                    n->children = NULL;
                    n->target_offset = offset;
                    n->multiplier = amount;
                    if (amount == 1 || amount == -1) {
                        n->kind = AST_ADD_MOVE;
                    } else {
                        n->kind = AST_MUL_MOVE;
                    }
                }
            }
        }

        PtrVecPush(out, n);
    }
    return out;
}

/* Entry point to optimise an AST */
Ast* Optimise(Ast *root) {
    if (root == NULL) return NULL;
    if (root->children == NULL) return root;
    root->children = OptimiseList(root->children);
    return root;
}
