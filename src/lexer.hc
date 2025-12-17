#include "../src/tokens.hc"

PtrVec *Lex(U8 *source) {
    PtrVec *tokens = PtrVecNew();
    for (I64 i = 0; source[i]; i++) {
        Token *t = MAlloc(sizeof(Token));
        switch (source[i]) {
            case '>': t->kind = TK_INC_PTR; break;
            case '<': t->kind = TK_DEC_PTR; break;
            case '+': t->kind = TK_INC; break;
            case '-': t->kind = TK_DEC; break;
            case '.': t->kind = TK_PUT; break;
            case ',': t->kind = TK_GET; break;
            case '[': t->kind = TK_LOOP_START; break;
            case ']': t->kind = TK_LOOP_END; break;
            default: continue; // other characters treated as comments
        }
        t->pos = i;
        PtrVecPush(tokens, t);
    }
    return tokens;
}

U0 PrintTokenSequence(U0 *seq, I64 len, Bool is_tokens) {
    for (I64 i = 0; i < len; i++) {
        I32 kind;
        if (is_tokens) {
            Token *t = PtrVecGet(seq(PtrVec*), i)(Token*);
            kind = t->kind;
        } else {
            kind = (seq(I32*))[i];
        }

        switch [kind] {
            case TK_INC_PTR:    "TK_INC_PTR ";    break;
            case TK_DEC_PTR:    "TK_DEC_PTR ";    break;
            case TK_INC:        "TK_INC ";        break;
            case TK_GET:        "TK_GET ";        break;
            case TK_DEC:        "TK_DEC ";        break;
            case TK_PUT:        "TK_PUT ";        break;
            case TK_LOOP_START: "TK_LOOP_START "; break;
            case TK_LOOP_END:   "TK_LOOP_END ";   break;
        }
    }
    "\n";
}
