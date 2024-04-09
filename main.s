;******************** Project Description ****************************************************************************************************************************************
; 
; @file    main.s
; @author  Anthony Spadafore, Isaac Shaker
; @date    April 16, 2024
; @note
;           The purpose of this code is to mimic the functionality of a
;			working elevator. The specifications are as follows:
;				- rotation of first motor represents up/down motion of elevator
;				- rotation of second motor represents opening/closing of doors
;				- elevator can be called from at least four different levels
;				using a push button (4 push buttons)
;				- keypad to register destination level of elevator
;				- order at which the elevator stops at different levels should
;				dynamically change
;				user should be given time to exit the elevator
;				- the admin should be allowed to pull the elevator to the first
;				floor and reset the sequence upon a button press
;				- the status of the system and operations should be communicated
;				in real time via Tera Term
;				- determine at least three technical constraints that are specific
;				to the prototype
;
;
;******************** Main Code **************************************************************************************************************************************************

			INCLUDE core_cm4_constants.s
			INCLUDE stm32l476xx_constants.s      

			IMPORT 	System_Clock_Init
			IMPORT 	UART2_Init
			IMPORT	USART2_Write
			
		; define registers
dest		RN 7	; r7 = dest
curr		RN 8	; r8 = curr
direction	RN 9	; r9 = direction

			AREA main, CODE, READONLY
			EXPORT __main						
			ENTRY			

__main		PROC
			
		; enable GPIOA, GPIOB, and GPIOC clock
			LDR r0, =RCC_BASE
			LDR r1, [r0, #RCC_AHB2ENR]
			BIC r1, r1, #0x00000007
			ORR r1, r1, #0x00000007
			STR r1, [r0, #RCC_AHB2ENR]
	
	; GPIOA: 
		;

	; GPIOB: Motor
		; set pins 2, 3, 6, 7 of GPIOB MODER to output mode (01)
			MOV r2, #0xF0F0
			MOV r3, #0x5050
			LDR r0, =GPIOB_BASE
			LDR r1, [r0, #GPIO_MODER]				; PB7 PB6 | PB5 PB4 | PB3 PB2 | PB1 PB0		pins
			BIC r1, r1, r2							; 11  11  | 00  00  | 11  11  | 00  00		mask
			ORR r1, r1, r3							; 01  01  | 00  00  | 01  01  | 00  00		value
			STR r1, [r0, #GPIO_MODER]
			
	; GPIOC:

	; Main Code
		; initialize variables
			MOV dest, #0b0000		; dest = 0000 (no destinations)
			MOV curr, #0b0001		; curr = 0001 (first floor)
			MOV direction, #0b00	; direction = 00 (rest)
									;			= 01 (up)
									;			= 10 (down)

while	; infinite loop

				CMP dest, #0b0000
				BEQ dest_EQ_0
				BNE dest_NE_0

dest_EQ_0	; if(dest == 0)
				MOV direction, #0b00
				B while

dest_EQ_0	; else if(dest != 0)
				

				CMP dest, curr
			
	
			B while
			ENDP


;******************** Pseudocode ****************************************&********************************************************************************************************
;
;			- we have two bit vectors, destination vector and a current vector
;				- the current vector displays the current location of the elevator
;				- the destination vector displays the locations that the elevator has to visit
;			- the destination vector will only be updated through interupts
;
;			while(true)
;			{
;				if(dest == 0)
;				{
;					direction = rest
;				}
;				else if(dest != 0)
;				{
;					//FIND DIRECTION
;					if(direction == rest)
;					{
;						if(dest > curr)
;						{
;							direction = up
;						}
;						else if(dest < curr)
;						{
;							direction = down
;						}
;						else if(dest == curr)
;						{
;							Display(r0 str*, r1 bytes)
;							Door_Clockwise()
;							Delay(r0 delay)
;							Door_Counterclockwise()							
;							BIC dest, curr
;							continue		//go back to top of while loop
;						}
;					}
;			
;					//GOING UP
;					if(direction == up)
;					{
;						find shiftValue using dest and curr
;
;						//IF THRERE ARE NO MORE UPWARD DESTINATIONS
;						if(LSL dest, shiftValue == 0)
;						{
;							direction = down
;							if(dest == 0)
;							{
;								direction = rest
;							}
;						}
;						else
;						{
;							Lift_Clockwise()
;							LSL curr, #1
;
;							if(curr && dest == curr)
;							{	
;								Display(r0 str*, r1 bytes)
;								Door_Clockwise()
;								Delay(r0 delay)
;								Door_Counterclockwise()
;							}
;
;							Display(r0 str*, r1 bytes)
;							BIC dest, curr
;						}
;					}
;					//GOING DOWN
;					else if(direction == down)
;					{
;						find shiftValue using dest and curr
;
;						//IF THRERE ARE NO MORE DOWNWARD DESTINATIONS
;						if(LSL dest, shiftValue == 0)
;						{
;							direction = up
;							if(dest == 0)
;							{
;								direction = rest
;							}
;						}
;						else
;						{
;							Lift_Counterclockwise()
;							LSR curr, #1
;
;							if(curr && dest == curr)
;							{	
;								Display(r0 str*, r1 bytes)
;								Door_Clockwise()
;								Delay(r0 delay)
;								Door_Counterclockwise()
;							}
;
;							Display(r0 str*, r1 bytes)
;							BIC dest, curr
;						}
;					}
;				}
;			}
;
;
;******************** Lift_Clockwise() *******************************************************************************************************************************************
		
		; to turn the shaft clockwise, the activation sequence is A_barB_bar, A_barB, AB, AB_bar
		; it takes 512 loops of this sequence for a 360 degree rotation
		
L_CW			PROC
				
		; push LR into stack
			PUSH {LR}
			
		; loop through clockwise sequence 512 times
			MOV r2, #0					; i = 0
L_CW_loop	CMP r2, #512
			BEQ L_CW_end
		
		; A_barB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x88			
			STR r1, [r0, #GPIO_ODR]
			
		; delay
			BL delay

		; A_barB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x48			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; AB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   0	  1	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x44			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; AB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00	
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   0	  1	  0	  0	
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x84				
			STR r1, [r0, #GPIO_ODR]			
		
		; delay
			BL delay
		
		; increment and loop
			ADD r2, r2, #1				; i = i + 1
			B L_CW_loop
		
		; shaft is now rotated 360 degrees CW
L_CW_end	POP {LR}
			BX LR

			ENDP


;******************** Lift_Counterclockwise() ************************************************************************************************************************************
	
	; to turn the shaft counterclockwise, the activation sequence is AB_bar, AB, A_barB, A_barB_bar
		; it takes 512 loops of this sequence for a 360 degree rotation

L_CCW		PROC
	
		; push LR into stack
			PUSH {LR}
			
		; loop through counterclockwise sequence 512 times
			MOV r2, #0					; i = 0
L_CCW_loop	CMP r2, #512
			BEQ L_CCW_end
		
		; AB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00	
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   0	  1	  0	  0	
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x84				
			STR r1, [r0, #GPIO_ODR]			
		
		; delay
			BL delay
		
		; AB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   0	  1	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x44			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
		
		; A_barB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x48			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
		
		; A_barB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x88			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; increment and loop
			ADD r2, r2, #1				; i = i + 1
			B L_CCW_loop
		
		; shaft is now rotated 360 degrees CCW
L_CCW_end	POP {LR}
			BX LR

			ENDP
		

;******************** Door_Clockwise() *******************************************************************************************************************************************
		
		; to turn the shaft clockwise, the activation sequence is A_barB_bar, A_barB, AB, AB_bar
		; it takes 512 loops of this sequence for a 360 degree rotation
		
D_CW			PROC
				
		; push LR into stack
			PUSH {LR}
			
		; loop through clockwise sequence 512 times
			MOV r2, #0					; i = 0
D_CW_loop	CMP r2, #512
			BEQ D_CW_end
		
		; A_barB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x88			
			STR r1, [r0, #GPIO_ODR]
			
		; delay
			BL delay

		; A_barB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x48			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; AB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   0	  1	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x44			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; AB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00	
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   0	  1	  0	  0	
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x84				
			STR r1, [r0, #GPIO_ODR]			
		
		; delay
			BL delay
		
		; increment and loop
			ADD r2, r2, #1				; i = i + 1
			B D_CW_loop
		
		; shaft is now rotated 360 degrees CW
D_CW_end	POP {LR}
			BX LR

			ENDP


;******************** Door_Counterclockwise() ************************************************************************************************************************************
	
	; to turn the shaft counterclockwise, the activation sequence is AB_bar, AB, A_barB, A_barB_bar
		; it takes 512 loops of this sequence for a 360 degree rotation

D_CCW		PROC
	
		; push LR into stack
			PUSH {LR}
			
		; loop through counterclockwise sequence 512 times
			MOV r2, #0					; i = 0
D_CCW_loop	CMP r2, #512
			BEQ D_CCW_end
		
		; AB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00	
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   0	  1	  0	  0	
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x84				
			STR r1, [r0, #GPIO_ODR]			
		
		; delay
			BL delay
		
		; AB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   0	  1	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x44			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
		
		; A_barB
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   0	1	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x48			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
		
		; A_barB_bar
			LDR r0, =GPIOB_BASE			; b07 b06 b05 b04 | b03 b02 b01 b00
			LDR r1, [r0, #GPIO_ODR]		;   1	0	0	0 |   1	  0	  0	  0
			BIC r1, r1, #0xFF			;  Bb	B	0	0 |  Ab	  A	  0	  0	
			ORR r1, r1, #0x88			
			STR r1, [r0, #GPIO_ODR]
		
		; delay
			BL delay
			
		; increment and loop
			ADD r2, r2, #1				; i = i + 1
			B D_CCW_loop
		
		; shaft is now rotated 360 degrees CCW
D_CCW_end	POP {LR}
			BX LR

			ENDP
		

;******************** Display(r0 str*, r1 bytes) *********************************************************************************************************************************
		
display		PROC

			;LDR r0, =char1		; r0 = pointer to str or char
			;MOV r1, #1			; r1 = number of bytes
			BL USART2_Write
			B restart
		
			ENDP
					

;******************** Delay(r0 delay) ********************************************************************************************************************************************

delay		PROC
			
			MOV	r0, #0x9999		; r0 = length of delay
delayloop	SUBS r0, #1
			CMP r0, #0
			BNE	delayloop
			
			BX LR

			ENDP
				
				
;******************** Data Allocation ********************************************************************************************************************************************

			ALIGN		

			AREA myData, DATA, READWRITE
			ALIGN

str1		DCB "BRUH",0	
char1		DCD	43			; ASCII code

			END
			
