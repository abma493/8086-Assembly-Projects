; implied .8086 by default
.model small
.stack 2048


.DATA ; DGROUP 64K limit
   msg db "Hello, world!", 0dh, 0ah, '$'
.CODE ; code segment 
.STARTUP

     mov ah, 9
     mov dx, offset msg
     int 21h

.EXIT  ; generates executable code
END    ; tell assembler its reached end of module

