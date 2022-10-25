;; Insert Utilities Here
UTIL_PRINT_HEX_NIBBLES PROC NEAR ; Print CX hex nibbles from AX
	; CX = # Of nibbles to print
	; AX = 1-4 nibbles to print from AH high -> AL Low
UTIL_PRINT_HEX_NIBBLES_LOOP:
	rol		ax,1 ; Grab the highest nibble by Rotating left 4x
	rol		ax,1 ;
	rol		ax,1 ;
	rol		ax,1 ; 
	push	ax ; Save off the Nth rotated AX
	and		al,0Fh ; Isolate the nibble
	add		al,'0' ; Shift into the ASCII Numeric Range
	cmp		al,'9' ; Check if <= 9
	jle		UTIL_PRINT_HEX_NIBBLES_CONT
	add		al,'A'-'9'-1 ; If not, shift up to ASCII 'A' range
UTIL_PRINT_HEX_NIBBLES_CONT:
	mov		ah,svc_video_write_char_tty ; Select DOS Print TTY service
	int		int_video ; Print current character
	pop		ax ; Restore Nth rotated AX
	loop	UTIL_PRINT_HEX_NIBBLES_LOOP
	ret
UTIL_PRINT_HEX_NIBBLES ENDP

UTIL_PRINT_BYTE MACRO	; Print 2 Nibbles from AH
	; AH = byte
	mov		cx,02h
	call 	UTIL_PRINT_HEX_NIBBLES
ENDM

UTIL_PRINT_WORD MACRO 	; Print 4 Nibbles from AX
	; AX = word
	mov		cx,04h
	call 	UTIL_PRINT_HEX_NIBBLES
ENDM

UTIL_PRINT_NEWLINE MACRO ;; Print \r\n
	mov		ax,(svc_video_write_char_tty SHL 8) OR 0Dh
	int		int_video
	mov		ax,(svc_video_write_char_tty SHL 8) OR 0Ah
	int		int_video
ENDM

UTIL_LOAD_DOS_INT21H PROC NEAR
	mov		ax,interrupt_vector_table_segment
	mov		es,ax ; Set ES to 0000h (the interrupt vector segment)
	mov		ax,cs
	mov		es:int21_segment,ax ; Move the current Code Segment to the Interrupt Vector 2nd 2 bytes
	mov		ax,offset UTIL_DOS_INT_21
	mov		es:int21_offset,ax ; Move the DOS_INT_21 Offset to the Interrupt Vector 1st 2 bytes
	ret
UTIL_LOAD_DOS_INT21H ENDP


UTIL_DOS_INT_21 PROC FAR ; Need to load this vector
	sti ; re-enable interrupts
	cmp		ah,09h ; Check if service 9
	jne		short DOS_INT_21_END ; If not, exit
DOS_INT21_SVC_9:
	push	ax
	push	bx ; Save user regs
	
	mov		ah,svc_video_get_current_mode
	int		int_video ; Set's BH
	
	xchg	si,dx ; Can't use DX to index, swap with SI
DOS_INT21_LOOP:
	mov		al,[si] ; Read next character
	cmp		al,'$' ; Compare to terminator
	je		short DOS_INT_21_CLEANUP ; Leave if terminator

	mov		ah,svc_video_write_char_tty ; Else Print the character
	int		int_video
	
	inc		si ; increment to the next one
	jmp		short DOS_INT21_LOOP ; loop again
DOS_INT_21_CLEANUP:
	xchg	si,dx ; Swap SI back
	
	pop		bx ; Restore user regs
	pop		ax
DOS_INT_21_END:
	iret
UTIL_DOS_INT_21 ENDP


