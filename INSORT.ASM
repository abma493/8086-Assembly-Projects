.8086
.model small
.stack 100h
.data
	prompt  db "Enter array to sort (example 1,2,3):", "$"
	result  db "Sorted array:", "$"
	crlf    db 0Ah, 0Dh, 0Ah, 0Dh, "$" 						; newline
	input   db 10, 0, 10 DUP(?) 
	arr     db 10 DUP(0)
	arrsize db 0
.code
INCLUDE DOSPARSE.INC
.STARTUP
main proc
	mov dx, offset prompt
	mov ah, 9
	int 21h					; show prompt
	
	mov dx, offset input
	mov ah, 0Ah
	int 21h					; ask for input array
	
	; convert from DOS input buffer to int (byte) arr
	INVOKE input_to_arr, offset input, offset arr
	mov arrsize, al
	call insertion_sort		; perform insertion sort algorithm
	
	mov dx, offset crlf		; \r\n (newline)
	mov ah, 9
	int 21h
	
	mov dx, offset result
	mov ah, 9
	int 21h
	
	INVOKE print_arr, arrsize, offset arr
	
	.EXIT					; w/o .STARTUP/.EXIT (both needed if one is used), then DOS ax=4Ch

main endp

; params:
;	ax = i, bx = for indexing, cx = j, dx = k, si = arr[i]
insertion_sort proc USES ax bx cx dx si
	mov cx, 1				; j = 1 (2nd elem)
	mov al, [arrsize]
	cmp cl, al	        	; fetch size of arr
	jl outer_loop			; j < input arr len
	RET
outer_loop:
	mov bx, cx				; for indexing
	mov dl, [arr + bx]  	; k = arr[j]
	mov ax, cx				
	dec ax					; i = j - 1
	jmp inner_loop
inner_loop:
	cmp ax, 0				; chk i >= 0
	jl end_inner_loop
	mov bx, ax 	
	cmp arr[bx], dl 		; chk arr[i] > k
	jle end_inner_loop
	mov dh, arr[bx]			; arr[i]
	mov arr[bx + 1], dh		; arr[i + 1] = arr[i]
	dec ax 					; i = i - 1
	jmp inner_loop
end_inner_loop:
	inc ax
	mov bx, ax
	mov arr[bx], dl
	inc cx
	mov al, [arrsize]
	cmp cl, al
	jl outer_loop
	RET
insertion_sort endp

END















