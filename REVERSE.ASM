.8086
.model small
.stack 100h

.data 
	rname   db  10 DUP(?), '$'				; reversed name
	lname   EQU 10           				; length of reverse name
	nprompt db  "Enter your name: ", "$"	; name prompt
	rprompt db "Your name reversed: ", "$"	; result prompt
	crlf    db  10,13,10,13, "$"			; newline
	buffer  db  11, ?, 11 DUP(?)			; input buffer

.code
main proc
	mov ax, @data
	mov ds, ax
	
	; prompt user for name
	mov dx, offset nprompt
	mov ah, 09h
	int 21h

	; buffered keyboard input
	mov ah, 0Ah
	mov dx, offset buffer
	int 21h
	
	mov dx, offset crlf
	mov ah, 09h
	int 21h


	; prep for loop to reverse input str (name)
	xor dx, dx
	mov dl, [buffer + 1]  				; load buffer chars read by DOS
	mov cx, 0

	; calculate starting position
	cmp dx, lname
	jg err_too_long
	je use_max_pos

	; input < 10 chars: start pos (len(buffer) - 1)
	mov di, offset rname	; start at rname i=0
	add di, dx				; di = rname + actual len of buffer
	dec di					; account for 0 based indexing
	jmp reverse_loop


exit:
	
	; print results
	mov dx, offset rprompt
	mov ah, 09h
	int 21h

	mov dx, offset rname
	mov ah, 09h
	int 21h

	mov ah, 4Ch							; ret to DOS
	int 21h

use_max_pos:
	mov di, offset rname + lname - 1 	; start @ index 10
	jmp reverse_loop
err_too_long:
	; TODO yield error
reverse_loop:
	
	cmp cx, dx							; comp counter to input buffer len 
	je exit 							; cx = end of string (itr done)
	
	mov bx, cx
	lea si, [buffer + bx + 2]           ; load buffer at i=0 (skip first 2) 
	mov al, [si]						; load byte from buffer
	mov [di], al						; store in rname
	dec di								; move backwards in rname
	inc cx
	jmp reverse_loop

main endp
end main











