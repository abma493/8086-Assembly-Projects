; TODO Work in-progress, needs testing and some checks/debugging
.8086
.model small, C

get_left MACRO dest:REQ, i:REQ
	mov al, i
	shl al, 1 		;; i*2
	mov dest, al 	;; L or R are set a val here
ENDM

get_right MACRO dest:REQ, i:REQ
	mov al, i 
	shl al, 1 	
	inc ax			;; i*2+1
	mov dest, al
ENDM

.stack 100h
.data
	
	; define data here
	prompt  db "Enter array to sort:", "$"
	result  db "Sorted array:", "$"
	crlf    db 0Dh, 0Ah, 0Dh, 0Ah, "$" 			; newline
	input   db 19, 0, 19 DUP(?) 				; DOS input str
	arrsize db ?
	array   db 10 DUP(0)
	
.code
INCLUDE DOSPARSE.INC
heapsort       PROTO C A: PTR BYTE
max_heapify    PROTO C A: PTR BYTE, i: BYTE
build_max_heap PROTO C A: PTR BYTE
.STARTUP
main proc

	writestr prompt
	mov dx, offset input 
	mov ah, 0Ah
	int 21h
	
	INVOKE input_to_arr, offset input, offset array
	mov arrsize, al
	dec al						; 0-based adjust
	INVOKE heapsort, ADDR array
	
	
.EXIT
main endp

heapsort proc USES ax bx cx, A: PTR BYTE 
	
	mov si, A					; load base addr of A array
	
	INVOKE build_max_heap, A
	mov cl, arrsize
	
sort_array:
	
	mov bx, cx
	mov al, [si + 1] 			; A[1]
	xchg [si + bx], al			; exchange A[1] with A[i]
	mov al, [si] 				; A[0] A.heapsize
	dec al						; A.heapsize -= 1
	INVOKE max_heapify, A, 1	; CAN YOU PASS AN IMM ???
	
	LOOP sort_array				; impl. dec cx, loop til CX=0
	
	RET
	
heapsort endp

max_heapify proc USES si, A: PTR BYTE, i: BYTE
	
	LOCAL       L: BYTE
	LOCAL       R: BYTE
	LOCAL largest: BYTE
	
	; set L and R vars
	get_left L, i
	get_right R, i
	
	mov si, A
	mov al, L
	mov bl, al			
	mov dl, [si + bx]			; A[L]
	mov bl, i
	
	; MASM distinguishes auto between instruction 
	; and operator forms based on context
	.IF (ax <= [si]) && (dl > [si + bx])
		mov largest, al
	.ELSE
		mov largest, bl 
	.ENDIF
	
	mov al, R
	mov bx, ax
	mov dx, [si + bx]			; A[R]
	mov bl, i
	.IF (ax <= [si]) && (dl > [si + bx])
		mov largest, al
	.ENDIF
	
	.IF largest != bl
		mov bl, largest
		mov dl, [si + largest]
		mov bl, i
		xchg [si + bx], dl		; exchange A[i] with A[largest]
		INVOKE max_heapify, A, largest
	.ENDIF

max_heapify endp

build_max_heap proc USES cx, A: PTR BYTE

	mov si, A
	mov al, arrsize 	; do I really gotta do this?
	mov [si], ax		; A.heapsize = n
	
	shr ax, 1			; div by 2
	mov cx, ax			; i = n/2
	
build:
	INVOKE max_heapify, A, cl
	LOOP build
	
	RET
	
build_max_heap endp

END