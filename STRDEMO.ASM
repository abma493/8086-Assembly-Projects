.8086
.model large

; demo macro to wr str to DOS output
; showcases simple macro declaration
writestr MACRO string:REQ
	
	; this example does not push/pop ax,dx to preserve regs
	; vals before macro call (let's keep it simple here)
	mov ah, 9
	mov dx, offset string
	int 21h
	
ENDM

.stack 100h
.data
	FPBYTE   TYPEDEF FAR PTR BYTE 
	string   BYTE "The quick brown fox jumps over the lazy dog"
	string2  BYTE "The quick brown dog jumps over the lazy fox"
	sample   BYTE "Hello World!"
	fpstring FPBYTE string
	lstring  EQU LENGTHOF string
	nfound   db "Not found.$"
	found    db "char found in string.$"
	match    db "strings match.$"
	nmatch   db "strings do not match.$"
	crlf     db 13, 10, 13, 10, "$"
	info     BYTE  0, 1, 2, 3, 4, 5
	linfo    WORD LENGTHOF info
	dest     BYTE 50 DUP (?)
	dest2	 BYTE 15 DUP (?)
	ldest    EQU (LENGTHOF dest) / 2
.code
.STARTUP

; ## REP prefix ##
; the 7 string instructions can be prepended with a REP<cond> prefix,
; which can only be applied to one str instruction at a time (for looping 
; over logical blocks of instructions use LOOP). REP causies such str
; to iterate for # of times specified in CX (or until a <cond> becomes true.
;
;	REP		- itr until cx=0 (cx-=1)
;	REPE	- itr until cx=0 OR as long as elems eq 
;	REPNE   - itr until cx=0 OR as long as elems are neq
main proc
	
	call cmps_demo	; demo the CMPS instruction
	writestr crlf
	call scas_demo  ; demo the SCAS instruction
	writestr crlf
	call lods_demo  ; demo the LODS instruction
	writestr crlf
	call stos_demo	; demo the STOS instruction
	writestr crlf
	call movs_demo  ; demo the MOVS instruction
	
.EXIT
main endp

; SCAS scans a str for a specified value in ES:DI (dest)
; As the loop executes, SCAS compares value pointed by digits
; to accumulator (AX). If values are the same, ZF=1 (set)
; 	NOTE: If using SCASB, accum is lower AL
scas_demo proc
	
	cld 				; DF=0 (clr) upwards scan
	mov cx, lstring		; load iterations
	les di, fpstring	; load addr as ES:DI
	mov al, 'z'
	repne scasb			; b=al, itr as long as neq or cx=0
	jcxz notfound		; jump if cx=0
	writestr found
	RET
notfound:
	writestr nfound
	RET
	
scas_demo endp

; LODS loads a value from a string to an accumulator register (AX). 
; The string is the src (DS:SI), and this instruction is not normally used
; w/ a REP prefix as typ. something must be done with each element before
; going to the next. CX is used depending on the Direction flag as all other
; str instructions, and in this case it is modded by LOOP rather than REP. 
lods_demo proc
	
	cld
	mov cx, linfo
	mov si, offset info
	mov ah, 2		    ; for DOS output char
get:
	lodsb				; get a char (byte) from str, b=al
	or al, '0'			; convert to ASCII (this op OK for single digits)
	mov dl, al			; load char for DOS
	int 21h				; call DOS
	loop get			; repeat til cx=0, cx is implictly dec by LOOP
	RET
lods_demo endp

; CMPS compares two strs and points to addr after which a match or non-match occurs
cmps_demo proc
	
	; str ops use dest as ES:DI. CMPS uses dest str. 
	; MASM sets DS to DGROUP, which differs from .model
	; and DOS sets ES at start of PSP segment. Addresses could overlap
	; and thus direct access to ES w/o setting it up as below could work,
	; but its unsafe. Always set ES to DS when needed for str ops
	; ES pointing to PSP is only dangerous for write ops:
	;		STOS, MOVS, or explicit access "mov es:[offset], reg"
	mov ax, @data
	mov es, ax
	
	cld
	mov cx, lstring
	mov si, offset string
	mov di, offset string2
	repe cmpsb
	jcxz allmatch
	writestr nmatch
	RET
allmatch:
	writestr match
	RET

cmps_demo endp

; STOS stores a specified value in each position of a str
; that is the dest (ES:DI). This example stores the char 'a'
; in a 100-byte str by storing 50 words rather than 100 bytes,
; making the code faster by reducing # of iterations. To fill
; an odd num of bytes, you would have to adj for the last byte.
stos_demo proc
	
	; assume ES = DS
	
	cld
	mov ax, 'aa'
	mov cx, ldest
	mov di, offset dest
	rep stosw	

	; taken from lodsb to output array/str byte by byte
	mov cx, ldest * 2
	mov si, offset dest
	mov ah, 2
get: 				
	lodsb
	mov dl, al 
	int 21h
	loop get
	RET
	
stos_demo endp

; MOVS copies data from one area of memory to another. CX as counter
; must be loaded, in addition to src and dst string addreses, using REP
; to itr through all string/array elements
movs_demo proc

	mov ax, @data
	mov es, ax 
	
	cld
	mov cx, LENGTHOF sample	; load itr count
	mov si, offset sample
	mov di, offset dest2
	rep movsb				; itr # of times as loaded in CX
	
	; perform lodsb to output array/str byte by byte
	mov cx, LENGTHOF sample
	mov si, offset dest2
	mov ah, 2
get:
	lodsb
	mov dl, al 
	int 21h
	loop get
	RET
	
movs_demo endp


END