.8086
.model small
.STACK 100h

.CODE
main proc
   mov ah, 19h
   int 21h

   add al, 'A'
   mov ah, 02h
   mov dl, al
   int 21h

   mov ah, 4Ch
   int 21h

main endp
end main
