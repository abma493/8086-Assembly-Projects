.8086
; you can also but "C" in .model to prevent typing "C" on each proc

.stack 1000h
.data
	FPBYTE TYPEDEF FAR PTR BYTE 				; far ptr to bytes
	prompt  db "Enter array to sort:", "$"
	result  db "Sorted array:", "$"
	crlf    db 0Dh, 0Ah, 0Dh, 0Ah, "$" 			; newline
	input   db 19, 0, 19 DUP(?) 				; DOS input str
	array   db 10 DUP(0)
	arrsize db 0
	psp_seg	dw ?								; store PSP segmennt (if u were to need it, here is an example)
	
.code
INCLUDE DOSPARSE.INC
; PROTOs required when using INVOKE and call
mergesort    PROTO C A:PTR BYTE, p:BYTE, r:BYTE
merge        PROTO C A:PTR BYTE, p:BYTE, q:BYTE, r:BYTE
alloc_mem    PROTO C arr:FPBYTE, alloc_size:BYTE
free_mem     PROTO C arr:FPBYTE
populate_arr PROTO C sarr:PTR BYTE, darr:FPBYTE, arrsize:BYTE
.STARTUP
main proc
	
	; show prompt, ask for input, parse to array (in global near .DATA)
	writestr prompt			
	mov dx, offset input
	mov ah, 0Ah
	int 21h
	
	INVOKE input_to_arr, offset input, offset array
	mov arrsize, al			; prev proc returns arrsize in AX
	dec al 					; 0-based index adjust
	
	; perform the mergesort algorithm
	xor cl, cl
	INVOKE mergesort, ADDR array, cl, al
	
	; print the sorted array
	writestr crlf
	INVOKE print_arr, arrsize, offset array		; offset or ADDR works for INVOKE (ADDR doesn't for CALL)
	
.EXIT
main endp

; example [3,1,4,7,5,2,6]
; main merge sort procedure that splits array into subarrays recursively
; using merge subroutine for sorting the subarrays 
mergesort proc C USES ax bx, A:PTR BYTE, p:BYTE, r:BYTE
	
	xor bh, bh		; for use in merge; u only init BL in this proc, but BH could be anything
	mov al, p	    ; at least 1 operand req for cmp to be in reg
	cmp al, r		; if p < r
	jl recurse
	RET
recurse:
	mov bl, al					; bl = q = p
	add bl, r					; q+=r
	shr bl, 1					; q/2
	INVOKE mergesort, A, p, bl 
	inc bl						; q+1
	INVOKE mergesort, A, bl, r
	dec bl						; return q to its val before +1
	INVOKE merge, A, p, bl, r
	RET
	
mergesort endp

; This proc will merge two subarrays recursively. 
; ds is preserved as its modded here to point to L_arr dyn alloc'd segment.
merge proc C USES ax bx ds si di, A:PTR BYTE, p:BYTE, q:BYTE, r:BYTE
	LOCAL      nl:BYTE 		; for left subarray limit (last index)
	LOCAL      nr:BYTE 		; for right subarray limit (last index)
	LOCAL     L_arr:FPBYTE  ; contents of L and R are garbo 
	LOCAL     R_arr:FPBYTE  ; (stack space is reserved but locals can't be init)
	
	mov WORD PTR L_arr, 0  ; init arrays to save a mov to set arr[0] (offset) in alloc_mem
	mov WORD PTR R_arr, 0  ; LOCALs must be declared before the first instruction in proc
	
	mov al, q	  
	sub al, p    
	inc al        
	mov nl, al  						; nl = q - p + 1
	
	mov al, r
	sub al, q
	mov nr, al  						; nr = r - q  
	
	; create L[1..nl+1] and populate it
	mov al, nl
	inc ax								; account for +1 for terminal sym
	INVOKE alloc_mem, ADDR L_arr, al
	dec ax								; return back to original value
	
	mov bl, p
	INVOKE populate_arr, A, L_arr, al
	
	; create R[1..n2+1]	and populate it
	mov al, nr
	inc ax
	INVOKE alloc_mem, ADDR R_arr, al
	dec ax
	
	mov bl, q
	inc bx 		; q+1
	INVOKE populate_arr, A, R_arr, al
	
	; loop invariant that sorts merged subarrays begins
	mov cl, p   	    ; k=p
	lds si, L_arr	 	; i=0  !!! DS no longer points to .DATA here
	les di, R_arr  		; j=0
	
loop_invariant:
	
	cmp cl, r					; for k=p to r
	jg end_li					; end loop invariant
	mov al, [si]
	cmp al, es:[di]				; we use the explicit seg override rather than ASSUME
	jle up_larr					; update left arr index L[i] <= R[j]
	
	; else, up_rarr L[i] > R[j]
	mov bx, cx					; to index A
	mov al, BYTE PTR es:[di]
	push si						; save L index tmprly
	mov si, A 					; si now holds index of A array
	mov ss:[si + bx], al		; A[k] = R[j]
	pop si						; restore si to hold L index for next itr
	inc di						; j+=1
	inc cx						; k+=1 of enclosing loop
	jmp loop_invariant
	
up_larr: 						; L[i] <= R[j]
	mov bx, cx
	mov al, BYTE PTR [si]
	push si						; repurpose SI to hold A rather than L_arr temporarily
	mov si, A					; load addr of A (recall no use of [] bc A is a stack param [bp-#])
	mov ss:[si + bx], al		; SS = DS for .model small w/ NEARSTACK, as is in this prog
	pop si						; restore the SI offset for the dyn alloc'd L_arr
	inc si						; i+=1
	inc cx
	jmp loop_invariant

end_li:
	INVOKE free_mem, L_arr
	INVOKE free_mem, R_arr
	RET
	
merge endp

; Synopsis:
;	Load the appropriate address of alloc'd mem by DOS into the FPBYTE 
;   array pointer. Recall a pointer in MASM is always a WORD (2B for seg,
;	2B for offset). Due to the nature of this proc, ADDR operator used in 
;   proc invocation (INVOKE).
; param(s):
;	LOAD ax for size of array
; Returns:
;	N/A	
alloc_mem proc C arr:FPBYTE, alloc_size:BYTE
	
	mov ah, 62h ; get PSP addr
	int 21h		; stores seg in bx
	mov es, bx	; es now holds PSP 
	
	
	; Shrink mem given to prog bc DOS gives all avail free mem on prog start.
	; Get .LST file and calc total size from DATA, STACK, CODE 
	; then +10h for PSP and div sum by 10h, dropping lower digit,
	; rounding up if lowest digit is not 0. 
	; Example:
	;		542h -> 552h -> 55h paragraphs -> round up = 56h to shrink/expand
	
	; ES already = PSP segment at this point
	mov ah, 4Ah							; mod memory blks (shrink avail prog mem)
	mov bx, 13Ch						; program LST file shows 1308h prog size (+10h for PSP)
	int 21h								; keep 131h paragraphs (1310h size)
	; now there is free mem to be dyn. alloc'd 
	; TODO check if error !!!
	
	les di, arr							; load far pointer ES:DI
	
prep_alloc:

	xor ah, ah							; ax used by INVOKE to set up params, so clear it
	mov al, alloc_size
	push ax
	add ax, 15							; 15 to ensure any partial paragraph rounds up
	mov cl, 4
	shr ax, cl							; div by 16 (2^4)
	
	or ax, ax							; if ZF=1, AX is 0
	jnz alloc
	inc ax								; ensure min 1 paragraph
alloc:
	mov bx, ax							; # of paragraphs requested
	mov ah, 48h 						; alloc mem
	int 21h
	jc error
	; ax will contain seg addr of alloc'd mem (MCB + 1 par)
	; offset (arr[0]) is already 0
	mov WORD PTR es:[di+2], ax 			; Load segment (recall x86 is little-endian)
	pop ax						
	RET
error:
	; TODO handle error, if no handler then ret 
	RET
alloc_mem endp

; Synopsis:
;	Free alloc'd memory via DOS
free_mem proc C arr:FPBYTE

	mov es, WORD PTR arr[2]				; ES holds seg of blk to be returned
	mov ah, 49h							; DOS func to free mem
	int 21h
	
	RET

free_mem endp


; Synopsis:
;	Given a main array (sarr), populate 0..arrsize elements,
;	where arrsize = n - 1, and n will be the last valid index
;   to hold a terminator symbol ($). Given that the actual value
;   of FPBYTE params required, we simply pass the pointers and 
;   dereference them here (lines 139-140)
; Params:
; 	Let sarr    = source array (A)
; 	Let darr    = dest array  (the dyn. alloc'd array, the subarray)
;   Let arrsize = size of darr elements to be populated
;   Let bx      = starting index of sarr	
populate_arr proc C USES si di, sarr:PTR BYTE, darr:FPBYTE, asize:BYTE
	
	mov si, sarr    				; sarr contains ptr val
	add si, bx						; addr must be loaded first from stack param before addressing contained elem
	les di, darr				    ; load far pointer addr (ES:DI = dest addr)
	xor cx, cx						; index for darr (=0)
populate:
	cmp cl, asize					; is cx smaller than expected size of subarray being populated?
	jge done
	
	mov dl, [si]					; hold value of sarr elem 
	mov es:[di], dl					; retrieve val of first elem of darr
	inc si							; sarr[i+1]
	inc di          				; darr[j+1]
	inc cx							; inc loop counter counter
	jmp populate
done:
	mov BYTE PTR es:[di], '$'		; terminal symbol (ASCII 24h) 
	; TODO what if elem cmp to '$' is greater than '$' (36) value? We need to account for this.
	RET
populate_arr endp

END





