
; LPT1.ASM - Escritura al puerto paralelo con timeout
; Compila: nasm -f bin LPT1.ASM -o LPT1.COM

[BITS 16]
[ORG 0x100]

DATA_PORT   EQU 0378h
STATUS_PORT EQU 0379h
CTRL_PORT   EQU 037Ah

MAX_RETRY   EQU 0005h

start:
    ; Esperar a que la impresora este lista
    MOV CX, MAX_RETRY

.wait_ready:
    MOV DX, STATUS_PORT
    IN  AL, DX
    TEST AL, 80h
    JNZ .enviar
    LOOP .wait_ready

    ; Timeout si el puerto no responde
    MOV AH, 09h
    MOV DX, msg_timeout
    INT 21h
    JMP .fin

.enviar:
    ; Enviar caracter A (41h)
    MOV AL, 41h
    MOV DX, DATA_PORT
    OUT DX, AL

    ; Activar STROBE
    MOV DX, CTRL_PORT
    IN  AL, DX
    AND AL, 0FEh
    OUT DX, AL

    ; Retardo
    MOV CX, 0Fh
.delay:
    LOOP .delay

    ; Desactivar STROBE
    OR  AL, 01h
    MOV DX, CTRL_PORT
    OUT DX, AL

    ; Mostrar resultado
    MOV AH, 09h
    MOV DX, msg_ok
    INT 21h

.fin:
    MOV AX, 4C00h
    INT 21h

msg_timeout DB 'Timeout: LPT1 no responde', 0Dh, 0Ah, '$'
msg_ok      DB 'Secuencia de escritura LPT1 ejecutada', 0Dh, 0Ah, '$'

