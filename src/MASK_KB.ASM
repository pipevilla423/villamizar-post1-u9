
; MASK_KB.ASM - Enmascarar/desenmascarar IRQ1 con el PIC 8259A
; Compila: nasm -f bin MASK_KB.ASM -o MASK_KB.COM

[BITS 16]
[ORG 0x100]

start:
    ; Leer IMR actual y guardar
    IN AL, 21h
    PUSH AX

    ; Enmascarar IRQ1 (bit 1 del IMR)
    OR AL, 02h
    OUT 21h, AL

    MOV AH, 09h
    MOV DX, msg_mask
    INT 21h

    ; Leer ticks iniciales del timer BIOS
    MOV AH, 00h
    INT 1Ah
    MOV BX, DX

.wait:
    ; Leer ticks actuales
    MOV AH, 00h
    INT 1Ah

    ; Calcular ticks transcurridos
    SUB DX, BX
    CMP DX, 55
    JB .wait

    ; Restaurar IMR original
    POP AX
    OUT 21h, AL

    MOV AH, 09h
    MOV DX, msg_unmask
    INT 21h

    MOV AX, 4C00h
    INT 21h

msg_mask DB "IRQ1 enmascarado (teclado deshabilitado)...$"
msg_unmask DB 0Dh, 0Ah, "IRQ1 restaurado.$"
