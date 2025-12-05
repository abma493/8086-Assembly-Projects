; TODO Work in-progress, needs testing and some checks/debugging
.8086
.model small, C

get_left MACRO dest:REQ, i:REQ
	mov ax, i
	shl ax, 1 		;; i*2
	mov dest, ax 	;; L or R are set a val here
ENDM

get_right MACRO dest:REQ, i:REQ
	mov ax, i 
	shl ax, 1 	
	inc ax			;; i*2+1
	mov dest, ax
ENDM

.stack 100h
.data
	
	; define data here
	prompt  db "Enter array to sort:", "$"
	result  db "Sorted array:", "$"
	arrsize db ?
	
.code
INCLUDE DOSPARSE.INC
.STARTUP
main proc

	writestr prompt
	mov dx, offset input 
	mov ah, 0Ah
	int 21h
	
	INVOKE input_to_arr, offset input, offset array
	mov arrsize, al
	dec al						; 0-based adjust
	INVOKE heapsort ADDR array
	
	
.EXIT
main endp

heapsort proc USES ax bx cx, A: PTR BYTE 
	
	mov si, A					; load base addr of A array
	
	INVOKE build_max_heap A
	mov cx, arrsize
	
sort_array:
	
	mov bx, cx
	mov ax, [si + 1] 			; A[1]
	xchg [si + bx], ax			; exchange A[1] with A[i]
	mov ax, [si] 				; A[0] A.heapsize
	dec ax						; A.heapsize -= 1
	INVOKE max_heapify, 1		; CAN YOU PASS AN IMM ???
	
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
	mov ax, L
	mov bx, ax			
	mov dx, [si + bx]			; A[L]
	mov bx, i
	
	; MASM distinguishes auto between instruction 
	; and operator forms based on context
	.IF (ax <= [si]) && (dx > [si + bx])
		mov largest, ax
	.ELSE
		mov largest, bx 
	
	mov ax, R
	mov bx, ax
	mov dx, [si + bx]			; A[R]
	mov bx, i
	.IF (ax <= [si]) && (dx > [si + bx])
		mov largest, ax
	.IF largest != bx
		mov bx, largest
		mov dx, [si + largest]
		mov bx, i
		xchg [si + bx], dx		; exchange A[i] with A[largest]
		INVOKE max_heapify A, largest

max_heapify endp

build_max_heap proc USES cx, A: PTR BYTE

	mov si, A
	mov ax, arrsize 	; do I really gotta do this?
	mov [si], ax		; A.heapsize = n
	
	shr ax, 1			; div by 2
	mov cx, ax			; i = n/2
	
build:
	INVOKE max_heapify A, cx
	LOOP build
	
	RET
	
build_max_heap endp

END