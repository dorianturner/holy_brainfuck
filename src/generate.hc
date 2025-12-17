#ifndef GENERATE_HC
#define GENERATE_HC "GENERATE_HC"

// TODO: See if this can be made neater
/* This has been GPT'd because I didn't feel like doing assembly at 2am */

#include "../src/ir.hc"
#include "../src/util/bool.hc"

U0 EmitLine(PtrVec *lines, U8 *fmt, ...) {
    if (!lines || !fmt) return;
    U8 *line = StrPrintJoin(NULL, fmt, argc, argv);
    PtrVecPush(lines, line);
}

PtrVec* GenerateAsmLines(PtrVec *ir_list) {
    PtrVec *lines = PtrVecNew(128);
    EmitLine(lines, "section .bss");
    EmitLine(lines, "tape: resb 30000");
    EmitLine(lines, "section .text");
    EmitLine(lines, "global main");
    EmitLine(lines, "extern putchar");
    EmitLine(lines, "extern getchar");
    EmitLine(lines, "main:");
    EmitLine(lines, "    push rbp");
    EmitLine(lines, "    mov rbp, rsp");
    EmitLine(lines, "    sub rsp, 16");
    EmitLine(lines, "    mov rbx, tape");

    for (I64 i = 0; i < ir_list->size; i++) {
        Ir *ins = PtrVecGet(ir_list, i)(Ir*);
        if (!ins) continue;
        switch (ins->kind) {
            case IR_INC_PTR:
                EmitLine(lines, "    add rbx, %d", ins->count);
                break;
            case IR_DEC_PTR:
                EmitLine(lines, "    sub rbx, %d", ins->count);
                break;
            case IR_INC:
                EmitLine(lines, "    add byte [rbx], %d", ins->count);
                break;
            case IR_DEC:
                EmitLine(lines, "    sub byte [rbx], %d", ins->count);
                break;
            case IR_PUT:
                EmitLine(lines, "    movzx rdi, byte [rbx]");
                EmitLine(lines, "    call putchar");
                break;
            case IR_GET:
                EmitLine(lines, "    call getchar");
                EmitLine(lines, "    mov [rbx], al");
                break;
            case IR_ZERO:
                EmitLine(lines, "    mov byte [rbx], 0");
                break;
            case IR_ADD_MOVE:
                EmitLine(lines, "    mov al, [rbx]");
                EmitLine(lines, "    movsx rax, al");
                EmitLine(lines, "    imul rax, %d", ins->multiplier);
                EmitLine(lines, "    add byte [rbx+%d], al", ins->target_offset);
                EmitLine(lines, "    mov byte [rbx], 0");
                break;
            case IR_LOOP_START:
                EmitLine(lines, "loop_start_%d:", i);
                EmitLine(lines, "    cmp byte [rbx], 0");
                EmitLine(lines, "    je loop_end_%d", ins->jump);
                break;
            case IR_LOOP_END:
                EmitLine(lines, "    cmp byte [rbx], 0");
                EmitLine(lines, "    jne loop_start_%d", ins->jump);
                EmitLine(lines, "loop_end_%d:", i);
                break;
        }
    }

    EmitLine(lines, "    mov rsp, rbp");
    EmitLine(lines, "    pop rbp");
    EmitLine(lines, "    xor eax, eax");
    EmitLine(lines, "    ret");

    return lines;
}

Bool Generate(U8 *path, PtrVec *ir_list) {
    if (!path || !ir_list) return False;
    PtrVec *lines = GenerateAsmLines(ir_list);
    I64 total_len = 0;
    for (I64 i = 0; i < lines->size; i++) {
        U8 *line = PtrVecGet(lines, i)(U8*);
        if (line) total_len += StrLen(line) + 1;
    }

    U8 *buf = MAlloc(total_len + 1);
    U8 *ptr = buf;
    for (I64 i = 0; i < lines->size; i++) {
        U8 *line = PtrVecGet(lines, i)(U8*);
        if (!line) continue;
        I64 len = StrLen(line);
        MemCpy(ptr, line, len);
        ptr += len;
        *ptr++ = '\n';
    }
    *ptr = 0;

    Bool ok = FileWrite(path, buf, ptr - buf, O_CREAT | O_RDWR | O_TRUNC);
    Free(buf);
    for (I64 i = 0; i < lines->size; i++) {
        U8 *line = PtrVecGet(lines, i)(U8*);
        if (line) Free(line);
    }
    PtrVecRelease(lines);
    return ok;
}

#endif
