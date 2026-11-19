
; ISR_TIME.ASM - Medicion del tiempo entre interrupciones
; Compila: nasm -f bin ISR_TIME.ASM -o ISR_TIME.COM

[BITS 16]
[ORG 100h]

start:
    ; Guardar vector original INT 09h
    MOV AX, 3509h
    INT 21h
    MOV [old_isr], BX
    MOV [old_isr+2], ES

    ; Inicializar contador de ticks BIOS
    PUSH ES
    MOV AX, 0040h
    MOV ES, AX
    MOV AX, [ES:006Ch]
    MOV [ticks_prev], AX
    POP ES

    ; Instalar ISR personalizado
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr
    MOV AX, 2509h
    INT 21h
    POP DS

    STI

    MOV AH, 09h
    MOV DX, msg_inicio
    INT 21h

.esperar:
    ; Consultar cantidad de interrupciones registradas
    CLI
    MOV AX, [contador]
    STI

    CMP AX, [mostrados]
    JE .comprobar_fin

    ; Obtener siguiente intervalo
    MOV BX, [mostrados]
    SHL BX, 1
    MOV AX, [intervalos+BX]
    MOV [valor_actual], AX

    INC WORD [mostrados]

    ; Mostrar mensaje fuera de la ISR
    MOV AH, 09h
    MOV DX, msg_ticks
    INT 21h

    MOV AX, [valor_actual]
    CALL imprimir_decimal

.comprobar_fin:
    CMP WORD [mostrados], MAX_KEYS
    JB .esperar

    ; Restaurar ISR original
    PUSH DS
    LDS DX, [old_isr]
    MOV AX, 2509h
    INT 21h
    POP DS

    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h

    ; Terminar programa
    MOV AX, 4C00h
    INT 21h

; ISR personalizado con medicion de ticks
mi_isr:
    PUSH AX
    PUSH BX
    PUSH DS
    PUSH ES

    MOV AX, CS
    MOV DS, AX

    ; Limitar a cinco interrupciones
    MOV BX, [contador]
    CMP BX, MAX_KEYS
    JAE .continuar

    ; Leer contador de ticks del BIOS
    MOV AX, 0040h
    MOV ES, AX
    MOV AX, [ES:006Ch]

    ; Calcular ticks transcurridos
    MOV DX, AX
    SUB AX, [ticks_prev]

    ; Guardar intervalo en el arreglo
    SHL BX, 1
    MOV [intervalos+BX], AX

    ; Actualizar ticks anteriores
    MOV [ticks_prev], DX

    ; Incrementar contador
    INC WORD [contador]

.continuar:
    POP ES
    POP DS
    POP BX
    POP AX

    ; Encadenar con el ISR original
    JMP FAR [CS:old_isr]

; Subrutina para imprimir AX en decimal
imprimir_decimal:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX

.divide:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ .divide

.imprimir:
    POP DX
    ADD DL, 30h
    MOV AH, 02h
    INT 21h
    LOOP .imprimir

    POP DX
    POP CX
    POP BX
    POP AX
    RET

; Variables
old_isr      DD 0
ticks_prev   DW 0
contador     DW 0
mostrados    DW 0
valor_actual DW 0

MAX_KEYS EQU 5

intervalos TIMES 5 DW 0

; Mensajes
msg_inicio DB 0Dh, 0Ah, "ISR_TIME instalado. Presione teclas.$"
msg_ticks  DB 0Dh, 0Ah, "Ticks desde la interrupcion anterior: $"
msg_fin    DB 0Dh, 0Ah, "ISR_TIME restaurado. Fin del programa.$"
