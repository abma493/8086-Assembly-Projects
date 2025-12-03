PBYTE TYPEDEF PTR BYTE	; PTR to byte (arr of chars or integers)
input_to_arr PROTO NEAR C pinput:PBYTE, parr:PBYTE
print_arr PROTO NEAR C asize:BYTE, parr:PBYTE


; Synopsis:
;	Parse DOS input buffer into byte array 
; Parameters:
;	pinput: pointer to DOS input buffer
;	parr  : pointer to dest byte arr
; Returns:
;	arrsize >> ax
; Learning:
;	(1) MASM has implied dereferencing for all data labels, 
;	    incl. LOCAL variables as shown in this proc
;   (2) When using ptr args, MASM does not expl. retrive values.
;		You must use two MOV instructions, one to retrieve the value
;		and the other to dereference. For instance, not doing line 20
;		but proceeding to do mov ax, [pinput+1] is double indirection, 
;	    (which is illegal), since any stack param in the proc resolves to
;		[bp-<offset>]. This is why something like mov myStackWord, 0 is OK,
;		bc it resolves to mov [bp-2], 0
input_to_arr PROC C USES bx cx dx si di, pinput:PBYTE, parr:PBYTE

	LOCAL asize:BYTE		; asize = arrsize to prevent symbol conflict
	mov asize, 0			; initialize local var
	mov si, pinput          ; first load the address of input
	mov di, parr			; first load the address of arr
	
	mov cx, 2				; prep index (cx = i = 2)
	xor dx, dx				; dx = j = 0 (prep index)
	jmp itr_loop
itr_loop:
	mov al, [si + 1]        ; al holds DOS chars read (incl. commas)
	inc ax 					; +1 to account for input indexing
	mov bl, al				; save this index upper bound for now
	shr al, 1				; divide by two (faster than using div)
	mov [asize], al		    ; arrsize now holds # of ints in arr
	mov al, bl				; restore al to DOS input indexing 
	
	cmp cl, al 	
	jle parse_value				 ; if i < len(input_arr), xchg value 
	mov al, [asize]			 ; Load arrsize into AL for return
	RET							 ; array parsed
parse_value:
	mov bl, cl					 ; load i for indexing
	xor ah, ah
	mov al, [si + bx]			 ; ax = input[i]
	sub al, '0'					 ; convert ASCII to number (0x35 -> 0x05)
	mov bl, dl					 ; load j for indexing
	mov BYTE PTR [di + bx], al   ; arr[j] = arr[i]
	add cx, 2					 ; 2, 4, 6, 8, ...
	inc dx						 ; 0, 1, 2, 3, ...
	jmp itr_loop

input_to_arr endp

; Synopsis:
; 	Print an integer array in the form <i>, <i+1>, ... <n>
;	where i is an index and n is the last index of the array
; Parameters:
; 	asize: byte representing size of array (255 max)
; 	parr : pointer to integer array to be printed  
; Returns:
; 	N/A
print_arr PROC C USES ax cx dx si, asize:BYTE, parr:PBYTE
	LOCAL i:BYTE			; elem index
	mov i, 0
	mov si, parr			; holds start of arr (address)
	xor cx, cx				; ensure its clear
	mov cl, [asize]		    ; cx holds size of array
print_loop:
	mov dl, [si]
	add dl, '0'
	mov ah, 02h				; DOS print char
	int 21h

	mov dl, ' '				; print space
	mov ah, 02h
	int 21h

	inc si					; next elem address 
	inc i					; next elem index
	cmp [i], cl
	jl print_loop
	RET

print_arr endp