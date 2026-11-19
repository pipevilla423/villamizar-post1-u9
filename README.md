
# Post-contenido — Unidad 9

**Estudiante:** William Felipe Villamizar Soler  
**Código:** 1152498  
**Asignatura:** Arquitectura de Computadores

## Parte 1 — Decisiones técnicas

### 1. ¿Polling sin límite o polling con timeout configurable?

El polling sin límite implementado en `TECL.ASM` es aceptable cuando se tiene la certeza de que el dispositivo responderá, como ocurre en una demostración donde el estudiante presiona una tecla para continuar la ejecución. Sin embargo, cuando no se puede garantizar una respuesta, es preferible utilizar el timeout configurable de `POLL_T.ASM`, ya que permite finalizar la espera después de un número determinado de intentos y evita que el programa permanezca bloqueado indefinidamente.

Configurar un valor demasiado pequeño para `MAX_RETRY`, como `0005h` en lugar de `0FFFFh`, puede producir falsos timeouts, debido a que el programa podría agotar los intentos antes de que un dispositivo lento, pero funcional, alcance a responder.

Además, un contador de reintentos no mide directamente el tiempo transcurrido, sino la cantidad de iteraciones ejecutadas. Por esta razón, la duración de la espera depende de la velocidad de la CPU o de la configuración del emulador. En conclusión, utilizar el contador de ticks del sistema ubicado en `0040h:006Ch` permite medir el tiempo de manera más confiable, independientemente de la velocidad de ejecución del bucle.

### 2. ¿Combinar banderas de dos puertos con OR o verificarlas por separado?

Combinar las banderas de estado mediante OR, como se implementa en `MULTI_ST.ASM`, permite detectar cuándo al menos uno de dos dispositivos está listo. Sin embargo, si el puerto LPT1 mantiene permanentemente su bandera en 1, como puede ocurrir en DOSBox, el bucle `.poll` finalizará desde la primera iteración, independientemente del estado del teclado. Esto reduce la utilidad de la espera combinada, porque el programa deja de esperar realmente un evento del segundo dispositivo.

Después de realizar la operación OR, es necesario verificar individualmente los registros `BL` y `BH`, porque el resultado combinado solamente indica que alguna condición se cumplió, sin identificar cuál dispositivo produjo la salida del bucle.

Por otra parte, utilizar AND en lugar de OR exigiría que ambas condiciones fueran verdaderas simultáneamente. Esto sería útil cuando se necesita sincronizar dos eventos, por ejemplo, esperar a que el usuario presione una tecla y que la impresora esté lista antes de enviar un dato.

En conclusión, OR es apropiado cuando basta con que uno de los dispositivos esté listo, mientras que AND se utiliza cuando ambos deben cumplir sus condiciones de disponibilidad.

## Parte 2 — Decisiones técnicas

### 3. ¿En qué punto del ISR debe ir el EOI?

El EOI (End Of Interrupt) debe enviarse al PIC 8259A cuando se haya completado la atención indispensable del dispositivo, evitando retrasarlo por operaciones prolongadas. En el código original de `ISR_KB.ASM`, el EOI se envía después de imprimir un mensaje mediante `INT 21h`. Si esta operación tarda varios milisegundos, el PIC mantiene IRQ1 en servicio y puede retrasar la atención de otras interrupciones de igual o menor prioridad, aumentando su latencia.

En cambio, el código original de `ISR_TIME.ASM` envía el EOI después de leer el contador de ticks y calcular el intervalo, antes de imprimir el resultado. Esto permite liberar antes el estado de interrupción en servicio del PIC. Sin embargo, como la ISR no ejecuta `STI`, el procesador mantiene las interrupciones enmascarables deshabilitadas hasta `IRET`. Por tanto, enviar el EOI temprano no provoca por sí solo la reentrada de IRQ1 ni permite que la CPU atienda inmediatamente otras interrupciones pendientes.

Es importante distinguir que el EOI libera al PIC para gestionar nuevas solicitudes según sus prioridades, mientras que el flag IF determina si la CPU puede aceptarlas. Además, IRQ0 tiene mayor prioridad que IRQ1 en la configuración habitual del PIC maestro.

En conclusión, la práctica recomendada es enviar el EOI después de completar las operaciones esenciales sobre el hardware y evitar tareas prolongadas dentro de la ISR. Para minimizar realmente la latencia, operaciones como imprimir mensajes deben realizarse fuera de la rutina de interrupción.

### 4. ¿Polling o interrupción para el mismo dispositivo?

La elección entre polling e interrupciones depende de la frecuencia de los eventos, la latencia requerida y la necesidad de aprovechar los recursos del procesador. Aunque ambas técnicas permiten detectar una pulsación del teclado, su funcionamiento y eficiencia son diferentes.

El polling implementado en `TECL.ASM` mantiene al procesador ejecutando continuamente un bucle de espera activa hasta detectar un dato disponible. Este enfoque resulta inadecuado en aplicaciones que necesitan realizar otras tareas simultáneamente, como un videojuego en DOS que debe actualizar animaciones, procesar información o atender otros periféricos mientras espera una tecla.

Respecto a la latencia, las interrupciones de `ISR_KB.ASM` permiten reaccionar al evento sin esperar a la siguiente consulta del programa, ya que el hardware genera una solicitud IRQ1 cuando ocurre la condición correspondiente. En cambio, el polling depende de la frecuencia con la que se ejecuta el bucle `.poll`. Aunque un polling muy frecuente puede ofrecer una latencia comparable o incluso menor en determinadas circunstancias, requiere mantener al procesador ocupado constantemente.

Para un dispositivo esporádico como el teclado, donde pueden transcurrir varios minutos entre pulsaciones, mantener un bucle de espera activa representa un desperdicio de ciclos de procesamiento. Las interrupciones permiten que el programa realice otras operaciones mientras espera el evento.

En conclusión, las interrupciones son preferibles para dispositivos con eventos poco frecuentes y aplicaciones que necesitan aprovechar eficientemente el procesador. El polling puede reservarse para esperas muy breves o situaciones controladas donde instalar una ISR no se justifica.
