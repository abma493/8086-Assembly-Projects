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
		
	PHEAP   TYPEDEF PTR HEAP					; TYPEDEFs may need to be outside any seg
	prompt  db "Enter array to sort:", "$"
	result  db "Sorted array:", "$"
	crlf    db 0Dh, 0Ah, 0Dh, 0Ah, "$" 			; newline
	input   db 19, 0, 19 DUP(?) 				; DOS input str
	arrsize db ?
	array   HEAP <>
	testme db 10 DUP(0)
	
.code
INCLUDE DOSPARSE.INC
heapsort       PROTO C p_heap: PHEAP
max_heapify    PROTO C p_heap: PHEAP, i: BYTE
build_max_heap PROTO C p_heacdp: PHEAP
.STARTUP
main proc

	writestr prompt
	mov dx, offset input 
	mov ah, 0Ah
	int 21h
	
	INVOKE input_to_arr, offset input, offset array.A
	mov arrsize, al
	INVOKE heapsort, ADDR array
	
	writestr crlf
	INVOKE print_arr, arrsize, offset array.A		
	
.EXIT
main endp

heapsort proc USES ax bx cx, p_heap: PHEAP 
	
	mov si, p_heap					; load base addr of HEAP_STRUCT
	
	INVOKE build_max_heap, p_heap
	mov cl, arrsize
	
sort_array:
	
	mov bx, cx
	mov al, [si + 1] 					; A[1]
	xchg [si + bx], al					; A[i] = A[1], al = old A[i]
	mov [si + 1], al					; A[1] = A[i]
	
	mov al, (HEAP PTR [si]).heapsize	; A[0] A.heapsize
	dec al								; A.heapsize -= 1
	mov (HEAP PTR [si]).heapsize, al
	INVOKE max_heapify, p_heap, 1			
	
	LOOP sort_array						; impl. dec cx, loop til CX=0
	
	RET
	
heapsort endp

max_heapify proc USES si, p_heap: PHEAP, i: BYTE
	
	LOCAL       L: BYTE
	LOCAL       R: BYTE
	LOCAL largest: BYTE
	
	; set L and R vars
	get_left L, i
	get_right R, i
	
	mov si, p_heap				; load entire struct
	mov al, L
	mov bl, al			
	mov dl, [si + bx]			; A[L]
	mov bl, i
	
	; MASM distinguishes auto between instruction 
	; and operator forms based on context
	.IF (al <= BYTE PTR [si]) && (dl > [si + bx])
		mov largest, al
	.ELSE
		mov largest, bl 		; largest = i
	.ENDIF
	
	mov al, R
	mov bx, ax
	mov dx, [si + bx]			; A[R]
	mov bl, largest
	.IF (al <= BYTE PTR [si]) && (dl > [si + bx])
		mov largest, al
	.ENDIF
	
	mov bl, i
	.IF largest != bl
		mov bl, largest			; cannot use LOCAL mem var as an index
		mov dl, [si + bx]		; A[largest]
		mov bl, i				; A[i]
		xchg [si + bx], dl		; A[i] = A[largest], dl = old A[i]
		mov bl, largest
		mov [si + bx], dl		; A[largest] = old A[i]
		
		INVOKE max_heapify, si, largest
	.ENDIF
	RET

max_heapify endp

build_max_heap proc USES cx, p_heap: PHEAP

	mov si, p_heap
	mov al, arrsize 	    			; do I really gotta do this?
	mov (HEAP PTR [si]).heapsize, al	; A.heapsize = n
	
	shr ax, 1			; div by 2
	mov cx, ax			; i = n/2
	
build:

	INVOKE max_heapify, p_heap, cl
	LOOP build
	
	RET
	
build_max_heap endp

END