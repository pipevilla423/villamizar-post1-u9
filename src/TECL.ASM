
; TECL_ALT.ASM - Lectura alternativa del teclado
; Compila: nasm -f bin TECL_ALT.ASM -o TECL_ALT.COM
; Utiliza INT 16h para compatibilidad con DOSBox

[BITS 16]
[ORG 0x100]

start:
    ; Esperar hasta que se presione una tecla
    MOV AH, 00h
    INT 16h

    ; AH contiene el scancode de la tecla
    MOV BL, AH

    ; Mostrar scancode en hexadecimal
    MOV AH, 02h
    MOV DL, BL
    SHR DL, 4
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printH
    ADD DL, 07h

.printH:
    INT 21h

    MOV DL, BL
    AND DL, 0Fh
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printL
    ADD DL, 07h

.printL:
    INT 21h

    ; Salto de linea
    MOV AH, 02h
    MOV DL, 0Dh
    INT 21h
    MOV DL, 0Ah
    INT 21h

    ; Terminar programa
    MOV AX, 4C00h
    INT 21h
