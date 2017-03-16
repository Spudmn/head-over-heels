	;; 
	;; stuff.asm
	;;
	;; TODO: Misc stuff?
	;;

        
L7B8F:	DEFB $00
WorldIdSnd:	DEFB $00

	;; NB: Called from main loop...
C7B91:		CALL	C7BBF
		LD	A,(MENU_SOUND)
		AND	A
		JR	NZ,L7BAD
		LD	A,(WorldId)
		CP	$07
		JR	NZ,L7BA4
		LD	A,(WorldIdSnd)
L7BA4:		LD	(WorldIdSnd),A
		OR	$40
		LD	B,A
		CALL	PlaySound
L7BAD:		CALL	DrawBlacked
		CALL	CharThing15
	;; NB: Fall through

;; Apply the attributes to make the screen visible, and draw the bits
;; around the edge.
RevealScreen:	LD	A,(AttribScheme)
		CALL	UpdateAttribs
		CALL	PrintStatus
		JP	DrawScreenPeriphery		; Tail call

C7BBF:		CALL	Reinitialise
		DEFW	LAF5B
		CALL	Reinitialise
		DEFW	ReinitThing
		LD	A,(Character)
		CP	$03
		JR	NZ,L7BDC
		LD	HL,LFB28
		SET	0,(HL)
		CALL	BuildRoom
		LD	A,$01
		JR	L7C14
L7BDC:		CALL	C728C
		JR	NZ,L7C10
		CALL	C72A3
		CALL	C774D
		LD	HL,HeelsObj
		CALL	GetUVZExtentsB
		EXX
		LD	HL,HeadObj
		CALL	GetUVZExtentsB
		CALL	CheckOverlap
		JR	NC,L7C0C
		LD	A,(Character)
		RRA
		JR	C,L7C00
		EXX
L7C00:		LD	A,B
		ADD	A,$05
		EXX
		CP	B
		JR	C,L7C0C
		LD	A,$FF
		LD	(L7B8F),A
L7C0C:		LD	A,$01
		JR	L7C14
L7C10:		CALL	BuildRoom
		XOR	A
L7C14:		LD	(LA295),A
		JP	C7C1A


	;;    ^
	;;   / \
	;;  /   \
	;; H     L
	
C7C1A:		LD	HL,(MinU)
		LD	A,(HasDoor)
		PUSH	AF
		BIT	1,A
		JR	Z,L7C29
		DEC	H
		DEC	H
		DEC	H
		DEC	H
L7C29:		RRA
		LD		A,L
		JR		NC,L7C30
		SUB		$04
		LD		L,A
L7C30:		SUB		H
	;; X coordinate of the play area bottom corner is in A.
	;; 
	;; We write out the corner position, and the appropriate
	;; overall vertical adjustments.
		ADD		A,$80
		LD		(CornerPos+1),A
		LD		C,A
		LD		A,$FC
		SUB		H
		SUB		L
		LD		B,A			; B = $FC - H - L
		NEG
		LD		E,A			; E = H + L - $FC
		ADD		A,C 			; 
		LD		(LeftAdj+1),A		; E + CornerPos
		LD		A,C
		NEG
		ADD		A,E
		LD		(RightAdj+1),A 		; E - CornerPos
	;; FIXME: Next bit.
		CALL		FloorFn
		POP		AF
		RRA
		PUSH		AF
		CALL		NC,NukeColL
		POP		AF
		RRA
		RET		C
	;; Scan from the right for the first drawn column
		LD	HL,BkgndData + 31*2
ScanR:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		DEC	HL
		DEC	HL
		JR	ScanR

	;; If the current screen column sprite isn't a door column, delete it.
NukeCol:	INC	HL
		LD	A,(HL)
		OR	~5
		INC	A
		RET	NZ
		LD	(HL),A
		DEC	HL
		LD	(HL),A
		RET

	;; Scan from the left for the first drawn column
NukeColL:	LD	HL,BkgndData
ScanL:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		INC	HL
		INC	HL
		JR	ScanL

	;; A funky shuffle routine: Load a pointer from the top of stack.
	;; (i.e. our return address contains data to skip over)
	;; The pointed value points to a size. We copy that much data
	;; from directly after it to a size later.
	;; i.e. 5 A B C D E M N O P Q becomes 5 A B C D E A B C D E.
	;; Useful for reinitialising structures.
Reinitialise:
	;; Dereference top of stack into HL, incrementing pointer
		POP	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		PUSH	HL
		EX	DE,HL
	;; Dereference /that/ into bottom of BC
		LD		C,(HL)
		LD		B,$00
	;; Then increment HL and set DE = HL + BC
		INC		HL
		LD		D,H
		LD		E,L
		ADD		HL,BC
		EX		DE,HL
	;; Finally LDIR
		LDIR
		RET
