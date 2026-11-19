
; ISR_KB.ASM - ISR personalizado para IRQ1 (teclado)
; Compila: nasm -f bin ISR_KB.ASM -o ISR_KB.COM

[BITS 16]
[ORG 100h]

section .text

start:
    ; Obtener y guardar vector original INT 09h
    MOV AX, 3509h
    INT 21h
    MOV [old_isr], BX
    MOV [old_isr+2], ES

    ; Instalar ISR personalizado
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr
    MOV AX, 2509h
    INT 21h
    POP DS

    STI

.esperar:
    ; Mostrar mensajes fuera de la ISR
    CLI
    MOV AX, [contador]
    STI

    CMP AX, [mostrados]
    JE .comprobar

    INC WORD [mostrados]

    MOV AH, 09h
    MOV DX, msg_tecla
    INT 21h

.comprobar:
    CMP WORD [mostrados], MAX_KEYS
    JB .esperar

    ; Restaurar vector original
    PUSH DS
    LDS DX, [old_isr]
    MOV AX, 2509h
    INT 21h
    POP DS

    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h

    MOV AX, 4C00h
    INT 21h

; ISR personalizado
mi_isr:
    PUSH AX
    PUSH DS

    MOV AX, CS
    MOV DS, AX

    ; Leer scancode del teclado
    IN AL, 60h

    ; Contar solamente eventos de pulsacion
    TEST AL, 80h
    JNZ .fin_isr

    CMP WORD [contador], MAX_KEYS
    JAE .fin_isr

    INC WORD [contador]

.fin_isr:
    ; EOI al PIC maestro
    MOV AL, 20h
    OUT 20h, AL

    POP DS
    POP AX
    IRET

; Datos
contador  DW 0
mostrados DW 0
MAX_KEYS  EQU 5
old_isr   DD 0

msg_tecla DB 0Dh, 0Ah, "Tecla detectada por ISR propio$"
msg_fin   DB 0Dh, 0Ah, "ISR restaurado. Fin del programa.$"

