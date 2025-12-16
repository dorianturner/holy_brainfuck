/* Normalisation pass to optimise the AST */

#include "../src/util/bool.hc"
#include "../src/ast.hc"

Bool CanMerge(Ast *a, Ast *b) {
    if (a == NULL || b == NULL || a->kind != b->kind || a->kind == AST_LOOP ) { return False; }
    return True;
}

PtrVec* NormaliseList(PtrVec *in) {
    PtrVec *out = PtrVecNew(in->size);

    for (I64 i = 0; i < in->size; i++) {
        Ast *n = PtrVecGet(in, i)(Ast*);
        if (n == NULL) { 
            "ERROR: In Normalise, given AST has a NULL node";
            continue;
        }

        /* Recursively normalize loops */
        if (n->kind == AST_LOOP && n->children != NULL) {
            PtrVec *norm_children = NormaliseList(n->children);
            n->children = norm_children;
        }

        /* Merge with previous if possible */
        if (out->size > 0) {
            Ast *prev = PtrVecGet(out, out->size - 1)(Ast*);
            if (CanMerge(prev, n)) {
                prev->count += n->count;
                continue;
            }
        }

        PtrVecPush(out, n);
    }

    return out;
}

Ast *Normalise(Ast *root) {
    if (root == NULL || root->children == NULL) return root;
    root->children = NormaliseList(root->children);
    return root;
}
