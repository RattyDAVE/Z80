DEFC COLS=80; 80 
DEFC LINES=5; 25 
DEFC SCREENSIZE=COLS*LINES 

DEFC CR=0DH 
DEFC LF=0AH 
DEFC CS=0CH 

DEFC SER_BUFSIZE=003FH 
DEFC SER_EMPTYSIZE=0005H 
DEFC RTS_HIGH=00D6h 
DEFC RTS_LOW=0096h 
DEFC serBuf=08000h 
DEFC SERRDPTR=08041h 
DEFC SERBUFUSED=08043h 
DEFC WAITFORCHAR=0074h 


;INCUDE "init_debug.z80"
                    ;include init.z80
                    ;include fake_init.z80

                    ; Change address to 8100h
            ORG    08080h ;  (32896)
INIT2:              

                    ;LD      HL,ANSI_SCRM ; Set Screen mode to 80x25
                    ;CALL    PRINT_STR ; Send it!

            LD      HL,ANSI_CLS 
            CALL    PRINT_STR 
            LD      a,'.' ; Set the Fill char
            CALL    FILL_SCR_BUFF ; Run the Fill Char routine
            LD      a,00000011B ; Set the Attributes
            CALL    FILL_SCR_ATTR ; Run the Fill Attrib Routine
            LD      B,1 ; Set start Line
            LD      C,1 ; Set start Col
            CALL    SET_POS 
            LD      A,01010001B 
            CALL    SET_ATTR_BUFF 
            LD      DE,INIT_STR1 
            CALL    COPY_STR_SCR 

START:              
            LD      HL,ANSI_HOME ; Home the Cursor
            CALL    PRINT_STR ; Send it!
            CALL    PRNT_SCR ; Print Screen Buffer

                    ;Frame debugging
            LD      A,(LOOP_COUNTER) 
            CALL    PNT_NUM 
            LD      hl,LOOP_COUNTER 
            INC     (hl) 
                    ;End of frame debugging

                    ;RST     010h ; Wait for keypress
            CALL    RX_NOWAIT ; Key press with no wait!
            AND     11011111B ; lower to uppercase
            CP      'S' ; Is it S ?
            CALL    Z,SCROLL_SCR 
            CP      'L'; Is it L ?
            JP      Z,0f800h ; Jump to LOADER!
            JR      START 

                    ; END OF MAIN LOOP

                    ;-----------------------------------------------------------------------------
PRINT_STR:          ;--------- Print (HL) to screen TEST ---------------------
            PUSH    af ;Save AF to stack
            PUSH    HL ;Save BC to Stack
PRINT_STR_1:        
            LD      a,(hl) ; Put the contents of HL in A
            CP      00 
            JR      Z,PRINT_STR_END ; End on 0
            RST     08 ; Call the Output routine
            INC     HL ; Add one to HL- Next Char
            JP      PRINT_STR_1 ; Loop and print more
PRINT_STR_END:      
            POP     HL ; Restore BC
            POP     af ; Restore AF
            RET     ;---------------------------------------------------------
                    ;-----------------------------------------------------------------------------

                    ;***********************************************************
FILL_SCR_BUFF:      ;Clears/Fills the screen buffer. (a = fill char)
            LD      hl,SCR_BUFF ; Pointer to the source
            LD      de,SCR_BUFF+1 ; Pointer to the destination
            LD      bc,SCREENSIZE ; Number of bytes to move
            DEC     BC ; All ready done one.
            LD      (hl),a ; The value to fill
            LDIR    ; Moves BC bytes from (HL) to (DE)
            RET     ;*****************************************************************************

FILL_SCR_ATTR:      ;Clears/Fills the screen attributes. (a = attributes)
            LD      hl,SCR_ATTR ; Pointer to the source
            LD      de,SCR_ATTR+1 ; Pointer to the destination
            LD      bc,SCREENSIZE ; Number of bytes to move
            DEC     BC ; All ready done one.
            LD      (hl),a ; The value to fill
            LDIR    ; Moves BC bytes from (HL) to (DE)
            RET     ;*****************************************************************************


                    ;***********************************************************
PRNT_SCR:           ; PRINTS SCREEN

                    ;LD      HL,ANSI_CUR_OFF
                    ;CALL    PRINT_STR
            LD      HL,SCR_BUFF ; HL contains start of screen area.
            LD      c,LINES ; C contains LINES
PRNT_LINE:          
            LD      b,COLS ; B contains ROWS
PRNT_COL:           

            CALL    GET_ATTR ; Print Attribs
            LD      a,(HL) ; Contents of HL into A (Char to print!)
            RST     08 ; Print the CHR
            INC     HL ; Move to next screen char to print
            DJNZ    PRNT_COL ; dec b, if not zero jump! More chars on line!
            LD      A,CR ; Put CR in A
            RST     08 ; Print the CR
            LD      A,LF ; Put LF in A
            RST     08 ; Print the LF
            DEC     C 
            JR      z,PRNT_SCR_DONE 
            JR      PRNT_LINE ; Start next line.
PRNT_SCR_DONE:      
            RET     ;--------------------------------------------------
                    ;***********************************************************


                    ;******************************************************************************
SET_POS:            ;------- B=LINE (1 to LINE), C = COLS (1 to COLS)
                    ;HL retuns the START ADDRESS
            LD      HL,SCR_BUFF 
            DEC     B ; Take 1 away from a
            JR      Z,COL_START ; HL contains the correct start point for the line!
            LD      D,0 ; Zero D
LN_START_1:         
            LD      E,COLS ; Put COLS into A
            ADD     HL,DE ; Add the offser for next line.
            DJNZ    LN_START_1 ; dec b, if not zero jump!

COL_START:          ;------- Sets HL to the col pos (called after LINE) --------------
            DEC     c ; take 1 away from C
            ADD     HL,BC ; B is already 0 so just add C
            RET     ; -------------------------------------------------------------
                    ;*****************************************************************************

COPY_STR_SCR:       ;--------- Copy String to Start of screen buffer ----------
                    ; Needs HL Set to the Start position (Provided by SET_POS)
                    ; Needs DE Set to the Start of the String.
            PUSH    af ;Save AF to stack
            PUSH    de ;Save DE to Stack
                    ;LD      hl,STRING1 ; Load the address of the string into HL
                    ;LD      de,SCREEN ; Load the address off the screen
COPY_STR_SCR_1:     
            LD      a,(de) ; Contents of DE into A
            CP      00 
            JR      Z,COPY_STR_SCR_END ;   Return if zero.
            LD      (hl),A ; Put 'A' into the address HL
            CALL    SET_ATTR 
            INC     hl ; Add 1 to HL
            INC     de ; Add 1 to DE
            JR      COPY_STR_SCR_1 
COPY_STR_SCR_END:   
;dsuw            POP     de ; Restore DE
            POP     af ; Restore AF
            RET     ;----------------------------------------------------------

                    ;Number in a to decimal ASCII
                    ;adapted from 16 bit found in z80 Bits to 8 bit by Galandros
                    ;Example: display a=56 as "056"
                    ;input: a = number
                    ;Output: a=0,value of a in the screen
                    ;destroys af,bc
PNT_NUM:            
            LD      c,-100 
            CALL    PNT_NUM1 
            LD      c,-10 
            CALL    PNT_NUM1 
            LD      c,-1 
PNT_NUM1:           
            LD      b,'0'-1 
PNT_NUM2:           
            INC     b 
            ADD     a,c 
            JR      c,PNT_NUM2 
            SUB     c ;works as add 100/10/1
            PUSH    af ;safer than ld c,a
            LD      a,b ;char is in b
            RST     08 ;print a char
            POP     af ;safer than ld a,c
            RET     
                    ;-------------------------------------------------------------------


GET_ATTR:           ;HL is the Current address of Char to be printed.
            PUSH    AF 
            PUSH    BC 
            PUSH    DE 
            PUSH    HL 
            LD      DE,SCREENSIZE 
            ADD     HL,DE ; Add the screen buffer, HL now contains Attrib location.
            LD      A,B ; Put Col into A
            CP      00 ; Check if 0
            JR      Z,GET_ATTR_ANSI ; If 0 then we have new line and print the ANSI
            LD      A,(HL) 
            DEC     HL 
            LD      D,(HL) 
            CP      D 
            JR      Z,GET_ATTR_END 
            INC     HL 
GET_ATTR_ANSI:      
            LD      A,27 ; ESC
            RST     08 ; Print it!
            LD      A,'[' ; 
            RST     08 ; Print it!
            LD      A,'3' ; 3x for Forground
            RST     08 ; Print it!
            LD      A,(hl) ; A contain the ATTRIB
            AND     00000111B ; Get Forground Nibble.
            ;ADD     a,48 ; Add 48 so converts to Ascii Char. Eg 1 = "1"
            OR 00110000b
            RST     08 ; Print the Colour
            LD      A,';' ; Next Item
            RST     08 ; Print it!
            LD      A,'4' ; 4x for Forground
            RST     08 ; Print it!
            LD      A,(hl) ; A contain the ATTRIB
            AND     01110000B ; Get Background Nibble.
            SRL     A ; Shift Left
            SRL     A ; Shift Left
            SRL     A ; Shift Left
            SRL     A ; Shift Left.. Now we are in the right Position.
            ;ADD     a,48 ; Add 48 so converts to Ascii Char. Eg 1 = "1" (ADD 7 Tstates)
            OR 00110000b
            RST     08 ; Print the Colour
            LD      A,'m' ; ESC
            RST     08 ; Print it!
GET_ATTR_END:       
            POP     HL 
            POP     DE 
            POP     BC 
            POP     AF 
            RET     

SET_ATTR_BUFF:      ; Puts Attribute in temp location.
            PUSH    HL 
            LD      HL,SCR_ATTR_BUFF 
            LD      (HL),A 
            POP     HL 

SET_ATTR:           ;HL is the Current address of Char.
                    ;A contains Attribute.
            PUSH    HL 
            PUSH    BC 
            LD      bc,SCREENSIZE 
            ADD     HL,BC ; Add the screen buffer, HL now contains Attrib location.
            LD      BC,SCR_ATTR_BUFF 
            LD      A,(BC) 
            LD      (hl),A ; A contain the ATTRIB
            POP     BC 
            POP     HL 
            RET     

SCROLL_SCR:         ;Scroll the screen buffer. (a = fill char)
            LD      hl,SCR_BUFF+COLS ; Pointer to the source
            LD      de,SCR_BUFF ; Pointer to the destination
            LD      bc,SCREENSIZE-COLS ; Number of bytes to move
            LDIR    ; Moves BC bytes from (HL) to (DE)
            LD      hl,SCR_BUFF+SCREENSIZE-COLS 
            LD      (hl),' ' 
            LD      DE,SCR_BUFF+SCREENSIZE-COLS+1 
            LD      bc,COLS-1 
            LDIR    ; Moves BC bytes from (HL) to (DE)
            LD      hl,SCR_ATTR+COLS ; Pointer to the source
            LD      de,SCR_ATTR ; Pointer to the destination
            LD      bc,SCREENSIZE-COLS ; Number of bytes to move
            LDIR    ; Moves BC bytes from (HL) to (DE)
            LD      hl,SCR_ATTR+SCREENSIZE-COLS 
            LD      (hl),00000001b 
            LD      DE,SCR_ATTR+SCREENSIZE-COLS+1 
            LD      bc,COLS-1 
            LDIR    ; Moves BC bytes from (HL) to (DE)
            RET     ;*****************************************************************************

RX_NOWAIT:          
            LD      A,(serBufUsed) ; What have we in the buffer?
            CP      $00 ; If we have more than 00 then do somthing.
            RET     Z ; Nothing waiting! So RETurn
            PUSH    HL ;Save HL
            LD      HL,(serRdPtr) 
            INC     HL 
            LD      A,L ; Only need to check low byte becasuse buffer<256 bytes
            ;CP      (serBuf+SER_BUFSIZE) & $FF
            ;CP      (serBuf+SER_BUFSIZE) ~ $FF
            CP      ( serBuf + SER_BUFSIZE )
            JR      NZ,RX_NOWAIT_NO_WRAP 
            LD      HL,serBuf 
RX_NOWAIT_NO_WRAP:          
            DI      ; Disable the interupts need full attention on
            LD      (serRdPtr),HL 
            LD      A,(serBufUsed) 
            DEC     A 
            LD      (serBufUsed),A 
            CP      SER_EMPTYSIZE 
            JR      NC,RX_NOWAIT_RTS1
            LD      A,RTS_LOW 
            OUT     ($80),A ; Send RTS LOW ... We are FULL!!!
RX_NOWAIT_RTS1:               
            LD      A,(HL) 
            EI      ; Enable interupts
            POP     HL 
            RET     ; Char ready in A


MEM_READONLY:       ;READ ONLY
MEM_ANSI_STRINGS:   
                    ;ANSI_CUR_OFF: DB    27,"[25l",00 ; Cursor Off
                    ;ANSI_CUR_ON: DB     27,"[25h",00 ; Cursor On
ANSI_SCRM:  DEFM      27 & "[27h" & 00 ; Set screen mode to 80x25
ANSI_CLS:   DEFM      27 & "[2J" & 00 ;Clear Screen
ANSI_HOME:  DEFM      27 & "[;H" & 00 ;Put cursor at 0,0
ANSI_RESET: DEFM      27 & "[0m" & 00 ;Reset all attributes
                    ;ANSI_BOLD:  DB      27,"[1m",00 ;Set bright attribute
                    ;ANSI_DIM:   DB      27,"[2m",00 ;Set dim attribute
                    ;ANSI_SO:    DB      27,"[3m",00 ;Set standout attribute
                    ;ANSI_UL:    DB      27,"[4m",00 ;Set underscore (underlined text) attribute
                    ;ANSI_BLINK: DB      27,"[5m",00 ;Set blink attribute
                    ;ANSI_REV:   DB      27,"[7m",00 ;Set reverse attribute
                    ;ANSI_HID:   DB      27,"[8m",00 ;Set hidden attribute
                    ;ANSI_FG_BK: DB      27,"[30m",00 ; ESC[30m - FG Black
                    ;ANSI_FG_RD: DB      27,"[31m",00 ; ESC[31m - FG Red
                    ;ANSI_FG_GN: DB      27,"[32m",00 ; ESC[32m - FG Green
                    ;ANSI_FG_YL: DB      27,"[33m",00 ; ESC[33m - FG Yellow
                    ;ANSI_FG_BL: DB      27,"[34m",00 ; ESC[34m - FG Blue
                    ;ANSI_FG_MG: DB      27,"[35m",00 ; ESC[35m - FG Magenta
                    ;ANSI_FG_CY: DB      27,"[36m",00 ; ESC[36m - FG Cyan
                    ;ANSI_FG_WH: DB      27,"[37m",00 ; ESC[37m - FG White
                    ;ANSI_BG_BK: DB      27,"[40m",00 ; ESC[40m - BG Black
                    ;ANSI_BG_RD: DB      27,"[41m",00 ; ESC[41m - BG Red
                    ;ANSI_BG_GN: DB      27,"[42m",00 ; ESC[42m - BG Green
                    ;ANSI_BG_YL: DB      27,"[43m",00 ; ESC[43m - BG Yellow
                    ;ANSI_BG_BL: DB      27,"[44m",00 ; ESC[44m - BG Blue
                    ;ANSI_BG_MG: DB      27,"[45m",00 ; ESC[45m - BG Magenta
                    ;ANSI_BG_CY: DB      27,"[46m",00 ; ESC[46m - BG Cyan
                    ;ANSI_BG_WH: DB      27,"[47m",00 ; ESC[47m - BG White

INIT_STR1:  DEFM      "Initalising Screen"  & 00 
                    ;INIT_STR2:  DB      "Screen Initalised",00
                    ;STRING1:    DB      "Lets start this thing",00

MEM_READWRITE:      ;READ WRITE
LOOP_COUNTER: DEFM    00 ; Used for Debugging
                    ;SCR_LINES:  DB      LINES Now a constant
                    ;SCR_COLS:   DB      COLS Now a constant
SCR_BUFF:   DEFS      SCREENSIZE ; Screen Buffer. (Characters)
SCR_ATTR:   DEFS      SCREENSIZE ; Screen Attributes. (Colours)
                    ;TEST_END:   DB      255
SCR_ATTR_BUFF: DEFS   01 ; Screen Attrib buffer.


