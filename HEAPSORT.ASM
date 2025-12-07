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

HEAP STRUCT 

	heapsize  BYTE ?
	A         BYTE 10 DUP(?)

HEAP ENDS


.stack 100h
.data
	
	PHEAP   TYPEDEF PTR HEAP
	prompt  db "Enter array to sort:", "$"
	result  db "Sorted array:", "$"
	crlf    db 0Dh, 0Ah, 0Dh, 0Ah, "$" 			; newline
	input   db 19, 0, 19 DUP(?) 				; DOS input str
	arrsize db ?
	array   HEAP <>
	
.code
INCLUDE DOSPARSE.INC
heapsort       PROTO C heap: PHEAP
max_heapify    PROTO C A: PTR BYTE, i: BYTE
build_max_heap PROTO C heap: PHEAP
.STARTUP
main proc

	writestr prompt
	mov dx, offset input 
	mov ah, 0Ah
	int 21h
	
	lea bx, array.A 			; get addr of elements field
	INVOKE input_to_arr, offset input, bx
	mov arrsize, al
	INVOKE heapsort, ADDR array
	
	
.EXIT
main endp

heapsort proc USES ax bx cx, p_heap: PHEAP 
	
	mov si, p_heap					; load base addr of HEAP_STRUCT
	
	INVOKE build_max_heap, p_heap
	mov cl, arrsize
	
sort_array:
	
	mov bx, cx
	mov al, (HEAP PTR [si]).A[1] 		; A[1]
	xchg [si + bx], al					; exchange A[1] with A[i]
	mov al, (HEAP PTR [si]).heapsize	; A[0] A.heapsize
	dec al								; A.heapsize -= 1
	mov (HEAP PTR [si]).heapsize, al
	lea bx, (HEAP PTR [si]).A				; you can also just repl. this line w/ INC bx (point to A[0])
	INVOKE max_heapify, bx, 1			
	
	LOOP sort_array						; impl. dec cx, loop til CX=0
	
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

build_max_heap proc USES cx, p_heap: PHEAP

	mov si, p_heap
	mov al, arrsize 	    			; do I really gotta do this?
	mov (HEAP PTR [si]).heapsize, al	; A.heapsize = n
	
	shr ax, 1			; div by 2
	mov cx, ax			; i = n/2
	
build:
	lea bx, (HEAP PTR [si]).A
	INVOKE max_heapify, bx, cl
	LOOP build
	
	RET
	
build_max_heap endp

END