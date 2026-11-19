
; ISR_CHAIN.ASM - Encadenamiento del ISR de teclado IRQ1
; Compila: nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM

[BITS 16]
[ORG 100h]

start:
    ; Guardar vector original INT 09h
    MOV AX, 3509h
    INT 21h

    MOV [old_isr], BX
    MOV [old_isr+2], ES

    ; Instalar nuestro ISR
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr_chain
    MOV AX, 2509h
    INT 21h
    POP DS

    STI

    MOV AH, 09h
    MOV DX, msg_inicio
    INT 21h

.esperar:
    ; Leer contador de interrupciones
    CLI
    MOV AX, [contador]
    STI

    CMP AX, MAX_KEYS
    JB .esperar

    ; Restaurar el ISR original
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

; ISR personalizado con encadenamiento
mi_isr_chain:
    PUSH AX
    PUSH DS

    MOV AX, CS
    MOV DS, AX

    ; Registrar interrupcion
    CMP WORD [contador], MAX_KEYS
    JAE .continuar
    INC WORD [contador]

.continuar:
    ; Restaurar registros antes de encadenar
    POP DS
    POP AX

    ; Encadenar con el ISR original
    ; El handler original finaliza mediante IRET
    JMP FAR [CS:old_isr]

; Datos
contador DW 0
MAX_KEYS EQU 5
old_isr DD 0

msg_inicio DB 0Dh, 0Ah, "ISR encadenado instalado. Presione 5 teclas.$"
msg_fin DB 0Dh, 0Ah, "ISR original restaurado. Fin del programa.$"
