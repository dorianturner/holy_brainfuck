#include "../src/ast.hc"
#include "../src/lexer.hc"
#include "../src/util/bool.hc"

/* I'm doing this parsing via Parser combinators
   where I compose small parsers into larger ones.
   Each parser takes a ParseResult (tokens + index)
   and returns a new ParseResult with value and updated index. */

class ParseResult {
    PtrVec *tokens;  // input tokens
    I64 index;       // current position in tokens
    Bool ok;         // parse success flag
    PtrVec *value;   // always PtrVec<Ast*>
};

/* Helper to create a new ParseResult */
ParseResult* ParseResultNew(PtrVec *tokens) {
    ParseResult *res = MAlloc(sizeof(ParseResult))(ParseResult*);
    res->tokens = tokens;
    res->index  = 0;
    res->ok     = True;
    res->value  = NULL;
    return res;
}

// Forward Decs
ParseResult* ParseCommand(ParseResult *in);
ParseResult* ParseLoop(ParseResult *in);
ParseResult* ParseSequence(ParseResult *in);

/* Parse a single Brainfuck command. Caller must free after use */
ParseResult* ParseCommand(ParseResult *in) {
    ParseResult *res = ParseResultNew(in->tokens);
    res->index = in->index;

    if (!res->ok || res->index >= res->tokens->size) {
        res->ok = False;
        return res;
    }

    Token *t = PtrVecGet(res->tokens, res->index)(Token*);
    if (!t) { res->ok = False; return res; }

    I64 pos;
    if (t) pos = t->pos; else pos = res->index;

    Ast *node = NULL;
    switch (t->kind) {
        case TK_INC_PTR: node = AstNew(AST_INC_PTR, pos); break;
        case TK_DEC_PTR: node = AstNew(AST_DEC_PTR, pos); break;
        case TK_INC:     node = AstNew(AST_INC, pos);     break;
        case TK_DEC:     node = AstNew(AST_DEC, pos);     break;
        case TK_PUT:     node = AstNew(AST_PUT, pos);     break;
        case TK_GET:     node = AstNew(AST_GET, pos);     break;
        default:
            "%s: Unexpected token kind %d at position %lld\n", "ParseCommand", t->kind, pos;
            res->ok = False;
            return res;
    }

    PtrVec *nodes = PtrVecNew(1);
    PtrVecPush(nodes, node);

    res->index++;        
    res->value = nodes;  
    return res;
}


/* Parse a Brainfuck loop. */
ParseResult* ParseLoop(ParseResult *in) {
    ParseResult *res = ParseResultNew(in->tokens);
    res->index = in->index;

    if (!res->ok || res->index >= res->tokens->size) {
        res->ok = False;
        return res;
    }

    Token *start = PtrVecGet(res->tokens, res->index)(Token*);
    I64 pos;
    if (start) pos = start->pos; else pos = res->index;

    if (!start || start->kind != TK_LOOP_START) {
        "%s: Expected '[' at position %lld\n", "ParseLoop", pos;
        res->ok = False;
        return res;
    }

    res->index++; // Consumes '['

    ParseResult *body_in = ParseResultNew(res->tokens);
    body_in->index = res->index;
    ParseResult *body_res = ParseSequence(body_in);

    if (body_res == NULL || !body_res->ok || body_res->value == NULL) {
        res->ok = False;
        res->index = body_res->index;
        if (body_res->value) PtrVecRelease(body_res->value);
        Free(body_res);
        Free(body_in);
        return res;
    }

    Ast *loop_node = AstNewLoop(pos, body_res->value);

    PtrVec *nodes = PtrVecNew(1);
    PtrVecPush(nodes, loop_node);

    res->index = body_res->index;
    res->value = nodes;

    Free(body_res);
    Free(body_in);
    return res;
}

/* Parse a sequence of commands and loops. */
ParseResult* ParseSequence(ParseResult *in) {
    ParseResult *res = ParseResultNew(in->tokens);
    res->index = in->index;

    PtrVec *nodes = PtrVecNew();

    while (res->ok && res->index < res->tokens->size) {
        Token *t = PtrVecGet(res->tokens, res->index)(Token*);
        if (t == NULL) { res->ok = False; break; }

        if (t->kind == TK_LOOP_END) {
            res->index++; // consume ']'
            break;
        }

        ParseResult *child = NULL;
        if (t->kind == TK_LOOP_START) {
            ParseResult *tmp = ParseResultNew(res->tokens); tmp->index = res->index;
            child = ParseLoop(tmp);
            Free(tmp);
        } else {
            ParseResult *tmp = ParseResultNew(res->tokens); tmp->index = res->index;
            child = ParseCommand(tmp);
            Free(tmp);
        }

        if (child == NULL) { res->ok = False; break; }
        if (!child->ok) {
            res->ok = False;
            res->index = child->index;
            if (child->value) PtrVecRelease(child->value);
            Free(child);
            PtrVecRelease(nodes);
            return res;
        }

        if (child->value == NULL) {
            res->ok = False;
            res->index = child->index;
            Free(child);
            PtrVecRelease(nodes);
            return res;
        }

        for (I64 i = 0; i < child->value->size; i++) {
            Ast *node = PtrVecGet(child->value, i)(Ast*);
            if (node) PtrVecPush(nodes, node);
        }

        res->index = child->index;
        PtrVecRelease(child->value);
        Free(child);
    }

    res->value = nodes;
    return res;
}


/* Top-level Parse: returns root AST_LOOP or NULL on error. */
Ast* Parse(PtrVec *tokens) {
    ParseResult *starter = ParseResultNew(tokens);
    starter->index = 0;
    ParseResult *res = ParseSequence(starter);

    if (res == NULL || res->ok == False || res->value == NULL) {
        I64 err_pos = 0;
        if (res && res->index < tokens->size) {
            Token *tmp = PtrVecGet(tokens, res->index)(Token*);
            if (tmp) err_pos = tmp->pos; else err_pos = res->index;
        }
        "%s: Parsing failure at position %lld\n", "Parse", err_pos;

        if (res) {
            if (res->value) PtrVecRelease(res->value);
            Free(res);
        }
        Free(starter);
        return NULL;
    }

    Ast *root = AstNewLoop(0, res->value);

    Free(res);
    Free(starter);
    return root;
}


/* Print flattened AST for testing (same behavior as before; consistent prints) */
U0 PrintASTFlat(Ast *root) {
    if (!root) return;

    PtrVec *stack = PtrVecNew();
    PtrVecPush(stack, root);

    while (stack->size > 0) {
        Bool ok = True;
        Ast *node = PtrVecPop(stack, &ok)(Ast*);
        if (!node) continue;

        switch (node->kind) {
            case AST_INC_PTR: "AST_INC_PTR "; break;
            case AST_DEC_PTR: "AST_DEC_PTR "; break;
            case AST_INC:     "AST_INC ";     break;
            case AST_DEC:     "AST_DEC ";     break;
            case AST_PUT:     "AST_PUT ";     break;
            case AST_GET:     "AST_GET ";     break;
            case AST_LOOP:
                if (node->children) {
                    for (I64 i = node->children->size; i-- > 0; ) {
                        Ast *child = PtrVecGet(node->children, i)(Ast*);
                        if (child) PtrVecPush(stack, child);
                    }
                }
                break;
        }
    }
    "\n";
}
