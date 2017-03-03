

org 32768

ld a,2              ; upper screen
call 5633           ; open channel

loop:
ld de,string        ; address of string
ld bc,eostr-string  ; length of string to print
call 8252           ; print our string
jp loop             ; repeat until screen is full

string: defb 'Dave is cool'
eostr:  equ $
