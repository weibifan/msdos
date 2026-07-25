;-------------------------------------------------------------------------------
; Tetris clone for IBM with MDA graphics (80 x 25 chars)
;-------------------------------------------------------------------------------
CPU 8086    ; specifically compile for 8086 architecture (compatible with 8088)
;-------------------------------------------------------------------------------
; CONSTANTS (all constants are defined using uppercase)
;-------------------------------------------------------------------------------
NEXTBLOCKYPOS equ 8  
PLAYFIELDOFFX equ 29
SCOREPOSX     equ 59
SCOREPOSY     equ 2
SCOREWIDTH    equ 10
LEVELPOSX     equ 60
LEVELPOSY     equ 17
LEVELWIDTH    equ 9
SELECTPOSY    equ 17
LEVELSELPOSX  equ 15
RANDOMPOSX    equ 40
TITLEPOSY     equ 5
TITLELINES    equ 9
;-------------------------------------------------------------------------------
    org 100h

start:
    ; clear screen
    mov ax,7
    int 10h
    call hidecursor

    ; initialize all variables
    call init

    ; show titlescreen
    call titlescreen

    ; build the playing field
    call buildfield
    call buildinterface
    call printstatsstatic
    call newblock

; game loop
loop:
    call hidecursor
    call storetime
.wait:
    call hidecursor
    call parsekey
    jc .movedown
    call checktime              ; check if system can make a time step, carry = no
    jc .wait
.movedown:
    call movedown
    jnc .cont
.col:
    call writeblock             ; write current block to field
    call removerows             ; check if there are any full lines and remove them
    call newblock               ; add new block
    call checkplacecol          ; check if there is a collision upon placement, carry = yes
    jnc .cont
    call gameover
    jmp exit
.cont:
    call hidecursor
    jmp loop
exit:
    ; clear screen
    mov ax,7
    int 10h
    
    ; exit program
    call restorecursor
    xor ah,ah
    int 21h

;-------------------------------------------------------------------------------
; show title screen and wait for key stroke
;-------------------------------------------------------------------------------
titlescreen:
    ; print ASCII ART
    mov cl,TITLEPOSY
    mov ch,TITLELINES       ; number of lines to print
.nextline:
    push cx
    mov dh,cl               ; row number
    mov dl,10               ; column number
    call setcursor

    mov al,TITLELINES       ; equal to line number
    sub al,ch               ; calculate line number
    mov ah,0
    mov bx,62               ; calculate offset
    mul bx
    lea dx,titlepagestr     ; set pointer to string
    add dx,ax               ; add offset to pointer
    mov ah,9                ; call print string routine
    int 21h

    pop cx                  ; retrieve counters
    inc cl
    dec ch
    jnz .nextline

    ; print start string
    mov dh,23
    mov dl,24               ; column number
    call setcursor

    lea dx,startstr
    mov ah,9
    int 21h

    ; print level selection
    mov dh,SELECTPOSY
    mov dl,LEVELSELPOSX
    call setcursor
    lea dx,levelselstr
    mov ah,9
    int 21h

    ; print piece generation selection
    mov dh,SELECTPOSY
    mov dl,RANDOMPOSX
    call setcursor
    lea dx,randomstr1
    mov ah,9
    int 21h

    mov dh,SELECTPOSY+2
    mov dl,RANDOMPOSX
    call setcursor
    lea dx,randomstr2
    mov ah,9
    int 21h

    ; print levels
    mov dh,SELECTPOSY+2
    mov dl,LEVELSELPOSX
    call setcursor
    mov cl,10
    mov dh,0
.nextlevel:
    mov ah,2
    mov dl,dh
    add dl,'0'
    int 21h
    mov dl,' '
    int 21h
    inc dh
    dec cl
    jnz .nextlevel

    call selectlevel
    call selectrng

.loop:
    mov ah,1                ; check for keystroke
    int 16h
    jz .loop                ; exit if no key pressed
    xor ah, ah
    int 16h                 ; grab keystroke from the buffer

    cmp ax, 0231h
    jz .levelsel
    cmp ax, 0332h
    jz .levelsel
    cmp ax, 0433h
    jz .levelsel
    cmp ax, 0534h
    jz .levelsel
    cmp ax, 0635h
    jz .levelsel
    cmp ax, 0736h
    jz .levelsel
    cmp ax, 0837h
    jz .levelsel
    cmp ax, 0938h
    jz .levelsel
    cmp ax, 0A39h
    jz .levelsel
    cmp ax, 0B30h
    jz .zerokey
    cmp ax, 1C0Dh           ; ENTER key
    jz .exit
    cmp ax,1E61h            ; A key
    jz .randomselect
	cmp ax,3062h            ; B key
    jz .randomselect
    jmp .loop

.zerokey:
    mov ah,1
.levelsel:
    sub ah,1
    mov [level],ah
    call setlevelspeed
    call selectlevel
    jmp .loop
.randomselect:
    sub al,61h
    mov [randomtype],al
    call selectrng
    jmp .loop

.exit:
    ; clear screen
    mov ax,7
    int 10h
    ret

;-------------------------------------------------------------------------------
; initialize playing variables
;-------------------------------------------------------------------------------
selectlevel:
    mov dh,SELECTPOSY+1
    mov dl,LEVELSELPOSX
    call setcursor
    mov dl,' '
    mov bl,20
    call printcharseq

    mov dh,SELECTPOSY+3
    mov dl,LEVELSELPOSX
    call setcursor
    mov dl,' '
    mov bl,20
    call printcharseq
    
    mov bl,[level]              ; grab current level
    sal bl,1                    ; multiply by 2
    mov ah,LEVELSELPOSX
    add ah,bl
    mov dl,ah
    mov dh,SELECTPOSY+1
    push dx
    call setcursor
    mov dl,'*'
    mov ah,2
    int 21h

    pop dx
    add dh,2
    call setcursor
    mov dl,'*'
    mov ah,2
    int 21h

    ret

;-------------------------------------------------------------------------------
; initialize playing variables
;-------------------------------------------------------------------------------
selectrng:
    mov dh,SELECTPOSY+1
    mov dl,RANDOMPOSX
    call setcursor
    mov dl,' '
    mov bl,20
    call printcharseq

    mov dh,SELECTPOSY+3
    mov dl,RANDOMPOSX
    call setcursor
    mov dl,' '
    mov bl,20
    call printcharseq
    
    mov al,[randomtype]
    mov bl,3
    mul bl
    mov cl,al
    mov al,[randomtype]
    mov bl,9
    mul bl
    mov ch,al

    mov dh,SELECTPOSY+1
    mov dl,RANDOMPOSX
    add dl,ch
    call setcursor
    mov dl,'*'
    mov bl,6
    sub bl,cl
    call printcharseq

    mov dh,SELECTPOSY+3
    mov dl,RANDOMPOSX
    add dl,ch
    call setcursor
    mov dl,'*'
    mov bl,6
    sub bl,cl
    call printcharseq

    ret

;-------------------------------------------------------------------------------
; initialize playing variables
;-------------------------------------------------------------------------------
init:
    mov ax,0
    mov [score], ax
    mov [score+2], ax
    mov [linescleared], ax
    mov [drawptr], al
    mov [speed],byte 45         ; default value
    mov [level], al
    mov [randomtype],byte 1
    mov bl,7
    mov di,blockstats
.nextword:
    mov [di],ax
    add di,2
    dec bl
    jnz .nextword
    
    call initrand       ; initialize pseudorandom number generator
    call generatebag    ; fill bag of seven
    ret

;-------------------------------------------------------------------------------
; build the playing field
;-------------------------------------------------------------------------------
buildfield:
    mov cl,0    ; row number
    mov dh,cl   ; row number
    mov dl,PLAYFIELDOFFX   ; column number
    call setcursor
    
    mov ah,9
    lea dx,headerline
    int 21h

    inc cl      ; increment line
    mov dh,cl   ; row number
    mov dl,PLAYFIELDOFFX   ; column number
    call setcursor

    mov ah,9
    lea dx,curline
    int 21h

    inc cl      ; increment line
    mov dh,cl   ; row number
    mov dl,PLAYFIELDOFFX   ; column number
    call setcursor

    mov ah,9
    lea dx,topline
    int 21h
    inc cl      ; increment line

.nextline:
    ; set cursor position
    mov dh,cl   ; row number
    mov dl,PLAYFIELDOFFX   ; column number
    call setcursor

    ; print line
    mov ah,9
    lea dx,regularline
    int 21h
    
    inc cl
    cmp cl,23   ; check if done?
    jnz .nextline
    
    ; set cursor position
    mov dh,cl   ; row number
    mov dl,PLAYFIELDOFFX   ; column number
    call setcursor

    ; print string
    mov ah,9
    lea dx,bottomline
    int 21h

    ; zero the field array
    mov byte [field],0
    lea si,field
    lea di,field+1
    mov cx,199
    cld
    rep movsb
    ret

;-------------------------------------------------------------------------------
; build the interface
;-------------------------------------------------------------------------------
buildinterface:
    call printscoreborder
    call printnextblockboundary
    call printlevelborder
    call printscore
    call printlevel
    ret

;-------------------------------------------------------------------------------
; print the boundary for the score
;-------------------------------------------------------------------------------
printscoreborder:
    mov cl,SCOREPOSY        ; initial  row index

.firstrow:
    mov dh,cl               ; row number
    mov dl,SCOREPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xc9
    int 21h

    mov bl,SCOREWIDTH
    mov dl,0xcd
    call printcharseq

    mov ah,2
    mov dl,0xbb
    int 21h

.nextstringrow:
    inc cl
    mov dh,cl               ; row number
    mov dl,SCOREPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xBA
    int 21h

    mov ah,9
    lea dx,scorestr
    int 21h

    mov ah,2
    mov dl,0xBA
    int 21h

.seprow:
    inc cl
    mov dh,cl               ; row number
    mov dl,SCOREPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xcc
    int 21h

    mov bl,SCOREWIDTH
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xb9
    int 21h

.blockspace:
    inc cl
    mov dh,cl               ; row number
    mov dl,SCOREPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xBA
    int 21h

    mov bl,SCOREWIDTH
    mov dl,' '
    call printcharseq
    
    mov ah,2
    mov dl,0xBA
    int 21h

.finalrow:
    inc cl
    mov dh,cl               ; row number
    mov dl,SCOREPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xc8
    int 21h

    mov bl,SCOREWIDTH
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xbc
    int 21h

    ret

;-------------------------------------------------------------------------------
; print the boundary for the level
;-------------------------------------------------------------------------------
printlevelborder:
    mov cl,LEVELPOSY        ; initial  row index

.firstrow:
    mov dh,cl               ; row number
    mov dl,LEVELPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xc9
    int 21h

    mov bl,LEVELWIDTH
    mov dl,0xcd
    call printcharseq

    mov ah,2
    mov dl,0xbb
    int 21h

.nextstringrow:
    inc cl
    mov dh,cl               ; row number
    mov dl,LEVELPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xBA
    int 21h

    mov ah,9
    lea dx,levelstr
    int 21h

    mov ah,2
    mov dl,0xBA
    int 21h

.seprow:
    inc cl
    mov dh,cl               ; row number
    mov dl,LEVELPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xcc
    int 21h

    mov bl,LEVELWIDTH
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xb9
    int 21h

.blockspace:
    inc cl
    mov dh,cl               ; row number
    mov dl,LEVELPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xBA
    int 21h

    mov bl,LEVELWIDTH
    mov dl,' '
    call printcharseq
    
    mov ah,2
    mov dl,0xBA
    int 21h

.finalrow:
    inc cl
    mov dh,cl               ; row number
    mov dl,LEVELPOSX        ; column number
    call setcursor

    mov ah,2
    mov dl,0xc8
    int 21h

    mov bl,LEVELWIDTH
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xbc
    int 21h

    ret

;-------------------------------------------------------------------------------
; Spawn the blocks used for the statistics
;-------------------------------------------------------------------------------
printstatsstatic:
    mov cl,7
    mov bl,0                ; start column
    mov bh,3                ; start row
    lea si,blockspieces

.nextpiece:
    mov ch,4
.nextblock:
    mov dx,[si]
    sal dl,1                ; multiply by 2
    add dl,bl               ; column counter
    add dh,bh               ; row counter
    push bx
    call setcursor
    pop bx
    mov ah,2
    mov dl,0xdb
    int 21h
    int 21h

    add si,2
    dec ch
    jnz .nextblock

    add bh,3
    dec cl
    jnz .nextpiece

    ret

;-------------------------------------------------------------------------------
; print number of blocks spawn of each type
;-------------------------------------------------------------------------------
printblockstats:
    mov cl,7
    mov dl,18            ; start column
    mov dh,3             ; start row
    lea si,blockstats

.nextblock:
    push dx
    push cx
    call setcursor
    mov ax,[si]
    call uint16todec    ; garbles all registers
    mov ah,09h
    mov dx,buffer
    int 21h             ; print string
    add si,2
    pop cx
    pop dx
    add dh,3
    dec cl
    jnz .nextblock
    ret

;-------------------------------------------------------------------------------
; print the boundary for the next block
;-------------------------------------------------------------------------------
printnextblockboundary:
    mov cl,NEXTBLOCKYPOS    ; initial  row index

.firstrow:
    mov dh,cl               ; row number
    mov dl,61               ; column number
    call setcursor

    mov ah,2
    mov dl,0xc9
    int 21h

    mov bl,8
    mov dl,0xcd
    call printcharseq

    mov ah,2
    mov dl,0xbb
    int 21h

.nextstringrow:
    inc cl
    mov dh,cl   ; row number
    mov dl,61   ; column number
    call setcursor

    mov ah,9
    lea dx,nextstr
    int 21h

.seprow:
    inc cl
    mov dh,cl   ; row number
    mov dl,61   ; column number
    call setcursor

    mov ah,2
    mov dl,0xcc
    int 21h

    mov bl,8
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xb9
    int 21h

.blockspace:
    inc cl
    mov ch,4    ; row counter
.nextrow:
    mov dh,cl   ; row number
    mov dl,61   ; column number
    call setcursor

    mov ah,2
    mov dl,0xBA
    int 21h

    mov bl,8
    mov dl,' '
    call printcharseq

    mov ah,2
    mov dl,0xBA
    int 21h
    inc cl
    dec ch
    jnz .nextrow

.finalrow:
    mov dh,cl   ; row number
    mov dl,61   ; column number
    call setcursor

    mov ah,2
    mov dl,0xc8
    int 21h

    mov bl,8
    mov dl,0xcd
    call printcharseq
    
    mov ah,2
    mov dl,0xbc
    int 21h

    ret

;-------------------------------------------------------------------------------
; Debug routine that prints the data field
;-------------------------------------------------------------------------------
buildshadowfield:
    lea di,field                ; pointer to field
    lea si,bplcnt               ; pointer to number of blocks per line
    mov cl,3                    ; line counter
.nextline:
    ; set cursor position
    mov ah,2
    xor bh,bh
    mov dh,cl   ; row number
    mov dl,60   ; column number
    int 10h

    mov dh,cl
    sub dh,3
    call printhex

    ; print space
    mov dl,' '
    mov ah,02h
    int 21h
    
    mov ch,10   ; number of blocks
.next:
    mov dl,[di]
    call printnibble
    inc di
    dec ch
    jnz .next

    ; print space
    mov dl,' '
    mov ah,02h
    int 21h

    ; print line counter
    mov dl,[si]
    call printnibble

    inc cl
    inc si
    cmp cl,23
    jnz .nextline
    ret

;-------------------------------------------------------------------------------
; print the current block
;-------------------------------------------------------------------------------
printblock:
    mov cl,4            ; set counter
    lea si,blockcoord
.nextblock:
    mov dx,[si]         ; x-pos in dl, y-pos in dh
    cmp dh,20
    jnc .cont
      
    ; calculate row
    add dh,3            ; add y-offset
    
    ; calculate column
    sal dl,1            ; multiply by 2
    add dl,30           ; add x-offset
    call setcursor
    
    ; print characters
    mov ah,02h
    mov dl,0xdb
    int 21h
    mov dl,0xdb
    int 21h

.cont:
    inc si              ; increment si with two positions
    inc si
    dec cl
    jnz .nextblock      ; next block if not done
    ret

;-------------------------------------------------------------------------------
; show the next block on the screen
;-------------------------------------------------------------------------------
printnextblock:
    call clearnextblock
    mov cl,4                ; set counter
    lea si,drawbag          ; set pointer to drawbag
    mov dl,[drawptr]        ; get offset
    mov dh,0
    add si,dx               ; pointer to piece is going to be next
    mov dl,[si]             ; store in dl
    mov ch,[si]             ; also store copy in ch (used later)
    mov dh,0
    sal dx,1
    sal dx,1
    sal dx,1                ; multiply by 8
    lea si,blockspieces     ; set pointer to block start coordinates
    add si,dx               ; add offset
.nextblock:
    mov dx,[si]             ; x-pos in dl, y-pos in dh
    mov ah,2
    xor bh,bh
    add dh,NEXTBLOCKYPOS+5  ; add y-offset to row
    sal dl,1                ; multiply by 2 for column
    add dl,56               ; add x-offset to column
    cmp ch,0
    jz .cont
    cmp ch,3
    jz .cont
    dec dl
.cont:
    int 10h                 ; set cursor
    
    ; print characters
    mov ah,2
    mov dl,0xdb
    int 21h
    mov ah,2
    mov dl,0xdb
    int 21h

    inc si              ; increment si with two positions
    inc si
    dec cl
    jnz .nextblock      ; next block if not done
    ret

;-------------------------------------------------------------------------------
; show the next block on the screen
;-------------------------------------------------------------------------------
clearnextblock:
    mov cl,11
    mov ch,4
.nextrow:
    ; set pointer
    mov ah,2
    mov bh,0
    mov dh,cl           ; add y-offset
    mov dl,62           ; add x-offset
    int 10h

    mov bl,8
    mov dl,' '
    call printcharseq

    inc cl
    dec ch
    jnz .nextrow
    ret

;-------------------------------------------------------------------------------
; remove the current block
;-------------------------------------------------------------------------------
removeblock:
    mov cl,4            ; set counter
    lea si,blockcoord
.nextblock:
    mov dx,[si]         ; y-pos in dh, x-pos in dl
    cmp dh,20
    jnc .cont

    ; set cursor
    mov ah,2
    mov bh,0
      
    ; calculate row
    add dh,3            ; add y-offset
    
    ; calculate column
    sal dl,1            ; multiply by 2
    add dl,30           ; add x-offset

    ; set cursor
    int 10h
    
    ; print characters
    mov ah,02h
    mov dl,' '
    int 21h
    mov dl,'.'
    int 21h

.cont:
    inc si              ; increment si with two positions
    inc si
    dec cl
    jnz .nextblock      ; next block if not done
    ret

;-------------------------------------------------------------------------------
; Store current block onto field
;-------------------------------------------------------------------------------
writeblock:
    mov bl,4            ; set counter
    lea si,blockcoord
.nextblock:
    mov dx,[si]         ; y-pos in dh, x-pos in dl

    ; calculate pointer
    lea di,field        ; load base address
    mov ax,10           ; store base in ax
    mov cl,dh
    mul cl              ; multiply with y-offset (store in ax)
    mov dh,0            ; zero upper byte
    add ax,dx           ; add x-position
    add di,ax           ; build pointer
    
    ; store value
    mov al,1
    mov [di],al
    
    ; next block
    inc si              ; increment si with two positions
    inc si
    dec bl              ; decrement counter
    jnz .nextblock      ; next block if not done
    ret

;-------------------------------------------------------------------------------
; Assess whether there are any full rows, if so, remove these and move
; all other rows downwards
;-------------------------------------------------------------------------------
removerows:
    call countrows
    call countpoints
    call purgerows
    call redrawfield
    call updatescore
    call adjustlevel
    ;call buildshadowfield
    ret

;-------------------------------------------------------------------------------
; Count number of blocks per line and store this in memory
;-------------------------------------------------------------------------------
countrows:
    mov cl,20           ; row counter
    lea di,bplcnt       ; storage pointer
    lea si,field        ; pointer to field
.nextline:
    mov ch,10           ; block counter
    mov ah,0            ; register to store sum
.nextblock:
    mov al,[si]
    add ah,al           ; add value
    inc si
    dec ch
    jnz .nextblock
    mov [di],ah         ; store counter
    inc di
    dec cl
    jnz .nextline
    ret

;-------------------------------------------------------------------------------
; loop once more over the rows and check if a row contains 10 blocks
; store the result in 'nrlinesrem' which is used to determine the
; number of points the user receives
;-------------------------------------------------------------------------------
countpoints:
    mov cl,20                   ; row counter
    lea di,bplcnt               ; storage pointer
    mov [nrlinesrem],byte 0     ; set counter to zero
.nextline:
    mov al,[di]
    cmp al,10
    jnz .cont
    mov al,[nrlinesrem]
    inc al
    mov [nrlinesrem],al
.cont:
    inc di
    dec cl
    jnz .nextline
    ret

;-------------------------------------------------------------------------------
; Remove completed row from the field
;-------------------------------------------------------------------------------
purgerows:
    mov al,[nrlinesrem]         ; check if there are any lines removed
    cmp al,0
    jz .exit                    ; if not, early exit

    mov bl,20                   ; row counter
    lea si,bplcnt+19            ; storage pointer (count from bottom row to top)
.line:
    mov al,[si]                 ; get number of blocks in a row
    cmp al,10                   ; check if it equals 10
    jnz .cont                   ; if not, continue
    push si                     ; put source index on stack
    mov cl,bl
    dec cl                      ; decrement cl to get current row number
    call migraterows            ; let all rows above this row move down
    pop si                      ; retrieve source index from stack
    jmp .line                   ; repeat procedure, do not decrement row
.cont:
    dec si                      ; decrement pointer
    dec bl                      ; decrement row counter
    jnz .line                   ; if not zero, go to next line
.exit:
    ret

;-------------------------------------------------------------------------------
; Remove the row and migrate all other rows
; INPUT: CL - number of rows to collapse
;-------------------------------------------------------------------------------
migraterows:
    push cx                     ; store line counter
    mov ax,10                   ; number of blocks per row
    mov ch,0                    ; zero upper byte
    mul cx                      ; multiply 10 by number of rows -> result in AX
    mov cx,ax                   ; store number of bytes to migrate in CX
    lea si,field                ; load pointer to field
    add si,cx                   ; set pointer to row to be removed
    dec si                      ; decrement to point to end of row above
    mov di,si                   ; set destination pointer
    add di,10                   ; move to end of row to be removed
    sal cx,1                    ; divide by 2 to get number of words
    std                         ; set decrement direction
    rep movsw                   ; move downward, overwriting the rows

    ; write zeros on the first row
    mov cl,10
    lea si,field
.nextblock:
    mov [si],byte 0
    inc si
    dec cl                      ; decrement block counter
    jnz .nextblock

    ; finally also migrate the block counter per line
    pop cx                      ; retrieve line counter
    mov ch,0
    lea di,bplcnt               ; put pointer at variable
    add di,cx                   ; increment to corresponding line
    mov si,di                   ; copy to source index
    dec si                      ; decrement to the byte before
    std                         ; set reverse direction
    rep movsb                   ; perform copy
    mov [bplcnt],byte 0         ; store zero for new line
    ret

;-------------------------------------------------------------------------------
; New block
;-------------------------------------------------------------------------------
newblock:
    ; select RNG based on type
    mov al,[randomtype]
    cmp al,0
    jnz .bag
    mov dl,[drawbag]    ; always draw first piece from bag
    jmp .cont
.bag:
    lea di,drawbag
    mov dl,[drawptr]    ; draw piece from bag based on ptr
    mov dh,0
    add di,dx
    mov dl,[di]
    mov dh,0

.cont:
    ; store into block counter
    mov al,dl
    lea si,blockstats
    mov ah,0
    sal ax,1
    add si,ax
    mov ax,[si]
    inc ax
    mov [si],ax

    ; load block positions
    lea si,blockspieces ; set source
    mov [blocktype],dl  ; store blocktype
    mov dh,0
    sal dx,1
    sal dx,1
    sal dx,1            ; multiply by 8
    add si,dx           ; add offset to source index
    lea di,blockcoord   ; set destination
    mov cx,4            ; set counter
    cld
    rep movsw           ; perform copy
    
    ; set default block rotation
    mov al,0
    mov [blockrot],al

    ; for RNG != bag, skip check whether a new bag has to be generated 
    mov al,[randomtype]
    cmp al,0
    jz .randomrng

    ; check if this was the last piece in the bag, if so, generate a new bag
    mov dl,[drawptr]
    inc dl
    cmp dl,7
    jnz .exit
    call generatebag
    mov dl,0
    jmp .exit
.randomrng:
    mov cx,7
    call randmod
    mov [drawbag],dl
    mov dl,0
.exit:
    mov [drawptr],dl
    call printnextblock
    call printblock
    ;call printbag
    call printblockstats
    ret

;-------------------------------------------------------------------------------
; Redraw the playing field based on the field variable
;-------------------------------------------------------------------------------
redrawfield:
    mov al,[nrlinesrem] ; check if there are any lines removed
    cmp al,0
    jz .exit            ; if not, early exit

    mov cl,20           ; row counter
    mov dh,3            ; screen row
    lea si,field        ; pointer to field
.nextrow:
    ; set cursor position
    mov ah,2
    xor bh,bh
    mov dl,30           ; column number
    int 10h

    mov ch,10           ; block counter

.nextblock:
    mov al,[si]
    cmp al,1            ; check if occupied
    jz .loadblock       ; load block characters
    lea di,emptystr     ; else load empty characters
    jmp .draw
.loadblock:
    lea di,blockstr
.draw:
    mov dl,[di]         ; print character
    mov ah,02h
    int 21h
    inc di              ; increment character pointer
    mov dl,[di]         ; print next character
    mov ah,02h
    int 21h

    inc si              ; increment field pointer
    dec ch              ; decrement block counter
    jnz .nextblock      ; goto next block

    inc dh              ; increment screen row
    dec cl              ; decrement row counter
    jnz .nextrow        ; goto next row
.exit:
    ret

;-------------------------------------------------------------------------------
; Update the player score
;-------------------------------------------------------------------------------
updatescore:
    mov al,[nrlinesrem] ; check if there are any lines removed
    cmp al,0
    jz printscore.exit  ; if not, early exit

    ; increment linecounter
    mov ah,0
    mov bx,[linescleared]
    add bx,ax
    mov [linescleared],bx

    ; increment score
    mov al,[nrlinesrem]
    mov ah,0
    dec ax
    sal ax,1            ; multiply by 2
    lea si,linescores
    add si,ax
    mov ax,[si]         ; retrieve score addition
    mov dx,0
    mov cx,[score]
    mov bx,[score+2]
    add bx,ax
    adc cx,dx           ; add with carry
    mov [score],cx
    mov [score+2],bx

printscore:
    ; print scorecounter
    mov cx,[score]
    mov bx,[score+2]
    call uint32todec

    ; set cursor
    mov ah,2
    xor bh,bh
    mov dh,SCOREPOSY+3   ; row number
    mov dl,SCOREPOSX+1   ; column number
    int 10h

    ; count number of positions
    mov cl,0
    lea si,buffer
.nextbyte:
    mov al,[si]
    cmp al,'$'
    jz .cont
    inc cl
    inc si
    jmp .nextbyte

.cont:
    mov bl,10
    sub bl,cl
    mov dl,' '
    call printcharseq

    ; write line counter
    mov ah,09h
    lea dx,buffer
    int 21h

    ; print linecounter
    mov ax,[linescleared]
    call uint16todec

    ; set cursor
    mov ah,2
    xor bh,bh
    mov dh,1    ; row number
    mov dl,38   ; column number
    int 10h

    ; write line counter
    mov ah,09h
    lea dx,buffer
    int 21h

.exit:
    ret

;-------------------------------------------------------------------------------
; adjust the game level based on the number of lines removed
;-------------------------------------------------------------------------------
adjustlevel:
    mov ax,[linescleared]
    mov dx,0                    ; clear remainder
    mov bx,10
    div bx                      ; divide by 10 to determine level
    mov ah,[level]
    cmp ah,al                   ; check if new level is larger than current
    jnc .exit                   ; if so, set new level
    mov [level],al
.exit:
    call printlevel
    call setlevelspeed
    ret

;-------------------------------------------------------------------------------
; set the game speed based on the level
;-------------------------------------------------------------------------------
setlevelspeed:
    mov al,[level]
    cmp al,15                   ; if level bigger or equal to 15?
    jc .cont                    ; if not, use equation
    mov ah,1                    ; else, set speed to 1
    jmp .exit
.cont:
    mov ah,15                   ; speed = 15 - level
    sub ah,al
.exit:
    mov [speed],ah
    ret

;-------------------------------------------------------------------------------
; print current level
;-------------------------------------------------------------------------------
printlevel:
    mov al,[level]
    call uint8todec

    ; set cursor
    mov ah,2
    xor bh,bh
    mov dh,LEVELPOSY+3      ; row number
    mov dl,LEVELPOSX+4      ; column number
    int 10h

    ; write line counter
    mov ah,09h
    lea dx,buffer
    int 21h
    ret

;-------------------------------------------------------------------------------
; check collision of the current block
;-------------------------------------------------------------------------------
; first check collission with the edges of the playing field
checkcol:
    mov cl,4            ; set counter
    lea si,tempblockcoord
.nextblock:
    mov dx,[si]         ; y-pos in dh, x-pos in dl (little endian retrieval)
    cmp dh,20           ; check if block is on the last line
    jz .col             ; collision detected and exit routine
    cmp dl,0x0A         ; check if x-coord is greater than 9, carry flag is 0 (NC)
    jnc .col
    inc si
    inc si
    dec cl
    jnz .nextblock      ; next block if not done
    jmp checkcolfield
.col:
    stc                 ; set carry flag
    ret

; check collisions with the blocks in the field
checkcolfield:          ; check collisions with the field when the block is lowered
    mov bl,4            ; set counter
    lea si,tempblockcoord
.nextblock:
    mov dx,[si]         ; y-pos in dh, x-pos in dl
    
    ; calculate pointer
    lea di,field        ; load base address
    mov ax,10           ; store base in ax
    mov cl,dh
    mul cl              ; multiply with y-offset (store in ax)
    xor dh,dh           ; zero upper byte
    add ax,dx           ; add x-position
    add di,ax           ; build pointer

    ; check if occupied
    mov al,[di]         ; load value in al
    cmp al,1            ; check if there is a block in that position
    jz checkcol.col     ; exit with a collision
    inc si              ; increment si with two positions
    inc si
    dec bl
    jnz .nextblock      ; next block if not done
    clc                 ; clear carry
    ret

;-------------------------------------------------------------------------------
; check whether fresh placement (current block) results in a collision
;-------------------------------------------------------------------------------
checkplacecol:
    mov bl,4            ; set counter
    lea si,blockcoord
.nextblock:
    mov dx,[si]         ; y-pos in dh, x-pos in dl
    
    ; calculate pointer
    lea di,field        ; load base address
    mov ax,10           ; store base in ax
    mov cl,dh
    mul cl              ; multiply with y-offset (store in ax)
    mov dh,0            ; zero upper byte
    add ax,dx           ; add x-position
    add di,ax           ; build pointer

    ; check if occupied
    mov al,[di]         ; load value in al
    cmp al,1            ; check if there is a block in that position
    jz checkcol.col     ; exit with a collision
    inc si              ; increment si with two positions
    inc si
    dec bl
    jnz .nextblock      ; next block if not done
    clc
    ret

;-------------------------------------------------------------------------------
; Copy current block coordinates to temporary block coordinates
;-------------------------------------------------------------------------------
curtotempblock:
    mov cx,4                ; set counter
    lea si,blockcoord       ; source location
    lea di,tempblockcoord   ; target location
    cld
    rep movsw
    ret

;-------------------------------------------------------------------------------
; Copy current block coordinates to buffer 
;-------------------------------------------------------------------------------
curtobuffer:
    mov cx,4                ; set counter
    lea si,blockcoord       ; source location
    lea di,buffer           ; target location
    cld
    rep movsw
    ret

;-------------------------------------------------------------------------------
; Copy temporary block coordinates to current block coordinates
;-------------------------------------------------------------------------------
temptocurblock:
    mov cx,4                ; set counter
    lea si,tempblockcoord   ; source location
    lea di,blockcoord       ; target location
    cld
    rep movsw
    ret

;-------------------------------------------------------------------------------
; Rotate a piece
;-------------------------------------------------------------------------------
rotatepiece:
    call curtobuffer
    lea si,rotationvectors  ; load base position

    ; calculate base for blocktype
    mov al,[blocktype]
    mov ah,0
    mov cl,32
    mul cl                  ; multiply by 32, store in ax
    add si,ax               ; add offset to base

    ; calculate rotation type
    mov al,[blockrot]
    mov ah,0
    sal ax,1
    sal ax,1
    sal ax,1                ; multiply by 8
    add si,ax

    ; create temporary block position in buffer
    mov cl,8                ; loop counter
    lea di,buffer
.nextbyte:
    mov al,[si]             ; load rotation
    mov ah,[di]             ; load coordinate
    add ah,al               ; apply rotation to coordinate
    mov [di],ah             ; store in buffer
    inc si
    inc di
    dec cl
    jnz .nextbyte

    ; the regular rotation is applied, now loop over offsets that account
    ; for wallkicks and check if a valid position can be found

    mov al,[blocktype]
    cmp al,0                ; is this an i-piece?
    jnz .tryo               ; if not, check if this is an o-piece
    lea si,wallkick_i       ; if yes, start reading from wallkick_i
    mov ch,5                ; rotation checks (5 in total)
    jmp .startkicktrials    ; start loop
.tryo:
    cmp al,3                ; o-piece?
    jnz .otherpiece         ; if not, other piece, go to starttry
    lea si,wallkick_i       ; if o-piece, start reading from wallkick_i
    mov ch,1                ; rotation checks (1 in total)
    jmp .startkicktrials    ; start loop
.otherpiece:
    lea si,wallkick_jlstz   ; neither i nor o piece
    mov ch,5                ; rotation checks (5 in total)
.startkicktrials:
    mov al,[blockrot]
    mov ah,0
    mov bx,10
    mul bx                  ; multiply ax by 10, store in ax
    add si,ax               ; add rotation offset to pointer
.nexttry:
    mov cl,4                ; number of words
    mov bp,buffer           ; set buffer
    mov di,tempblockcoord
.nextblock:
    mov bx,[si]             ; store offset in ax; tx in bl, ty in bh
    mov ax,[bp]             ; load coordinates from buffer
    add al,bl               ; add wallkick offset to x
    add ah,bh               ; add wallkick offset to y
    mov [di],ax             ; store in temp array
    add bp,2
    add di,2
    dec cl                  ; decrement word counter (# block coords)
    jnz .nextblock

    push cx                 ; store counter
    push si                 ; store wallkick position
    call trymove            ; exit upon collision and do not apply rotation
    jnc .cont               ; if there was no collision, write the result
    pop si                  ; retrieve wallkick position
    add si,2                ; increment to next trial kick
    pop cx                  ; retrieve counter
    dec ch                  ; decrement try counter
    jnz .nexttry
    jmp .exit               ; no possible rotation found, exit
.cont:
    add sp,4                ; fix stack
    ; increment rotation factor (modulus 4)
    mov al,[blockrot]
    inc al
    cmp al,4        ; check if number is less than 4 (carry = yes)
    jc .wq          ; if less than 4, write & exit
    mov al,0        ; else reset to 0
.wq:
    mov [blockrot], al
.exit:
    ret    

;-------------------------------------------------------------------------------
; move block to the left
;-------------------------------------------------------------------------------
moveleft:    
    mov bx,0x00FF                ; (-1,0) : two's compliment -1 and zero
    jmp move

;-------------------------------------------------------------------------------
; move block to the right
;-------------------------------------------------------------------------------
moveright:    
    mov bx,0x0001                ; (1,0)
    jmp move

;-------------------------------------------------------------------------------
; move block one position down
;-------------------------------------------------------------------------------
movedown:    
    mov bx,0100h                ; (0,1)
    jmp move

;-------------------------------------------------------------------------------
; move block specified by coordinates in BX
; INPUT: BX - input position
; GARBLES: AX,SI,DI,CL
;-------------------------------------------------------------------------------
move:
    mov cl,4
    lea si,blockcoord
    lea di,tempblockcoord
.nextblock:
    mov ax,[si]
    add al,bl
    add ah,bh
    mov [di],ax
    inc si
    inc si
    inc di
    inc di
    dec cl
    jnz .nextblock
    jmp trymove

;-------------------------------------------------------------------------------
; print block coord to the screen
;-------------------------------------------------------------------------------
printblockcoord:
    mov cl,4
    mov ch,10
    lea si,blockcoord
.nextblock:
    ; set cursor position
    mov dh,ch
    mov dl,2           ; row number
    call setcursor

    ; print x coordinate
    mov dh,[si]
    call printhex
    inc si

    ; print y coordinate
    mov dh,[si]
    call printhex
    inc si

    ; next coordinate
    inc ch
    dec cl
    jnz .nextblock

    ; print blockrotation
    mov ah,2
    xor bh,bh
    mov dh,ch
    mov dl,2           ; row number
    int 10h
    mov dh,[blockrot]
    call printhex

    call hidecursor
    ret

;-------------------------------------------------------------------------------
; try to perform movement (incl. rotation) based on positions in temporary
; block and if succesful, execute it
;-------------------------------------------------------------------------------
trymove:
    call checkcol               ; check if there is a collision, carry = yes
    jc .col
.nocol:
    call removeblock
    call temptocurblock
    call printblock
    cld                         ; no collision found, carry = no
    ret
.col:
    stc                         ; collision found, carry = yes
    ret

;-------------------------------------------------------------------------------
; print temporary block coord to the screen
;-------------------------------------------------------------------------------
printtempblockcoord:
    mov cl,4
    mov ch,16
    lea si,tempblockcoord
.nextblock:
    ; set cursor position
    mov ah,2
    xor bh,bh
    mov dh,ch
    mov dl,2           ; row number
    int 10h

    ; print x coordinate
    mov dh,[si]
    call printhex
    inc si

    ; print y coordinate
    mov dh,[si]
    call printhex
    inc si

    ; next coordinate
    inc ch
    dec cl
    jnz .nextblock

    call hidecursor
    ret

;-------------------------------------------------------------------------------
; Perform operations based on key press
;-------------------------------------------------------------------------------
parsekey:
    clc
    mov ah,1                ; check for keystroke
    int 16h
    jz .exit                ; exit if no key pressed
    xor ah, ah
    int 16h                 ; grab keystroke from the buffer
    push ax
    call restorecursor
    pop ax
    cmp ax,4b00h            ; key left
    jz .keyleft
    cmp ax,1e61h            ; A
    jz .keyleft

    cmp ax,4d00h            ; key right
    jz .keyright
    cmp ax,2064h            ; D
    jz .keyright

    cmp ax,5000h            ; key down
    jz .keydown
    cmp ax,1F73h            ; S
    jz .keydown

    cmp ax,4800h            ; key up
    jz .keyup
    cmp ax,1177h            ; W
    jz .keyup
    
    clc                     ; clear carry
    jmp .exit               ; any other key
.keyleft:
    call moveleft
    clc                     ; clear carry
    jmp .exit
.keyright:
    call moveright
    clc                     ; clear carry
    jmp .exit
.keydown:
    stc                     ; set carry (will skip wait state)
    jmp .exit               ; and directly execute a movedown command
.keyup:
    call rotatepiece
    clc                     ; clear carry
    jmp .exit
.exit:
    ret

;-------------------------------------------------------------------------------
; Game over routine
;-------------------------------------------------------------------------------
gameover:
    ; clear screen
    mov ax,7
    int 10h
    
    ; set cursor
    mov ah,2
    xor bh,bh            ; zero bh
    mov dh,12            ; row number
    mov dl,32            ; column number
    int 10h
    
    ; print string
    mov ah,09h
    mov dx,strgameover
    int 21h
    
    ; set cursor
    mov ah,2
    xor bh,bh            ; zero bh
    mov dh,14            ; row number
    mov dl,23            ; column number
    int 10h
    
    ; print string
    mov ah,09h
    mov dx,strgameover2
    int 21h
    
    ; wait for key press
    xor ah,ah
    int 16h

    ret

;-------------------------------------------------------------------------------
; Restore the cursor
; Always call this function before exiting the program, else the system
; will crash
;-------------------------------------------------------------------------------
restorecursor:
    xor dx,dx            ; row number
    jmp setcursor

;-------------------------------------------------------------------------------
; Set the cursor indicated by positions DL,DH
; INPUT: DH - row
;        DL - column
; GARBLES: AH,BH
;-------------------------------------------------------------------------------
setcursor:
    mov ah,2
    xor bh,bh
    int 10h
    ret

;-------------------------------------------------------------------------------
; Hide the cursor just outside the visible screen area
;-------------------------------------------------------------------------------
hidecursor:
    mov ch, 32
    mov ah, 1
    int 10h
    ret

;-------------------------------------------------------------------------------
; Show system time on screen
;-------------------------------------------------------------------------------
storetime:
    ; load system time
    xor ah,ah
    int 1ah
    
    ; store result in memory
    mov [timestamp],cx
    mov [timestamp+2],dx

    ret

;-------------------------------------------------------------------------------
; Wait 10 clock ticks
;-------------------------------------------------------------------------------
waittime:
    ; load system time
    xor ah,ah
    int 1ah
    
    mov cx,[timestamp+2]    ; load lower word old time in cx
    sub dl,cl               ; subtract old time from new time
    cmp dl,1                ; check number of cycles passed (18 cycles ~ 1 sec)
    jc waittime             ; if not, try again
    
    ret

;-------------------------------------------------------------------------------
; Check whether the system can perform a move step (CARRY = NO)
;-------------------------------------------------------------------------------
checktime:
    ; load system time
    xor ah,ah
    int 1ah
    
    mov cx,[timestamp+2]    ; load lower word old time in cx
    sub dl,cl               ; subtract old time from new time
    cmp dl,[speed]          ; check number of cycles passed (18 cycles ~ 1 sec)
    
    ret

;-------------------------------------------------------------------------------
; Generate a sequence of the 7 possible Tetris pieces
;-------------------------------------------------------------------------------
generatebag:
    ; fill the buffer
    mov bl,7                ; counter
    mov bh,0                ; value to write
    lea di,buffer
.nextbyte:
    mov [di],bh
    inc bh
    inc di
    dec bl
    jnz .nextbyte

    ; fill the bag
    mov bl,7                ; counter
    lea di,drawbag          ; set storage pointer
.nextpiece:
    mov cl,bl               ; maximum value to generate (minus one)
    mov ch,0
    call randmod            ; generate random number value in dx
    lea si,buffer
    add si,dx               ; set pointer
    mov bh,0
    mov al,[si]             ; load piece to put in bag
    mov [di],al             ; put in bag

    ; remove value from buffer by realigning
    push di                 ; push bag pointer on stack
    mov di,si               ; set storage pointer
    inc si                  ; set source pointer one byte further
    mov cx,bx               ; maximum number of element to shift
    sub cx,dx               ; subtract shift position
    dec cx
    cld                     ; forward direction
    rep movsb               ; perform realign
    pop di                  ; retrieve bag pointer from stack
    
    inc di                  ; next bag position
    dec bl                  ; decrement counter
    jnz .nextpiece
    ret

;-------------------------------------------------------------------------------
; print pieces in bag
;-------------------------------------------------------------------------------
printbag:
    ; set cursor position
    mov ah,2
    xor bh,bh
    mov dh,24   ; row number
    mov dl,70   ; column number
    int 10h

    mov bl,7
    lea si,drawbag
.nextbyte:
    mov dl,[si]
    call printnibble
    inc si
    dec bl
    jnz .nextbyte

    ; clear line above
    mov ah,2
    xor bh,bh
    mov dh,23   ; row number
    mov dl,70   ; column number
    int 10h

    mov bl,7
    mov dl,' '
    call printcharseq

    ; indicate bag pointer
    mov ah,2
    xor bh,bh
    mov dh,23   ; row number
    mov dl,70   ; column number
    mov al,[drawptr]
    add dl,al
    int 10h

    ; print marker
    mov ah,2
    mov dl,'*'
    int 21h

    ret

;-------------------------------------------------------------------------------
; Print HEX byte
; INPUT: DH - BYTE TO PRINT
; GARBLES: AH,DX
;-------------------------------------------------------------------------------
printhex:
    ; upper nibble
    mov dl,dh
    sar dl,1
    sar dl,1
    sar dl,1
    sar dl,1            ; shift arithmetic right 4x
    and dl,0fh          ; drop upper nibble
    call printnibble

    ; lower nibble
    mov dl,dh           ; reload digit
    and dl,0fh          ; drop upper nibble
    call printnibble

    ret

;-------------------------------------------------------------------------------
; Print nibble
; INPUT: DL - NIBBLE TO PRINT
;-------------------------------------------------------------------------------
printnibble:
    cmp dl,0x0A
    jc .printnum
    add dl,'A'-10
    jmp .print
.printnum:
    add dl,'0'
.print:
    mov ah,02h
    int 21h
    ret

;-------------------------------------------------------------------------------
; Print sequence of chars
; INPUT: DL - CHAR TO PRINT
;        BL - NUMBER OF CHARS TO PRINT
;-------------------------------------------------------------------------------
printcharseq:
    mov ah,2
.nextbyte:
    int 21h

    dec bl
    jnz .nextbyte
ret

;-------------------------------------------------------------------------------
; Initialize the random number generator
;-------------------------------------------------------------------------------
initrand:
    mov ah,00h
    int 1ah
    mov [prn],dx        ; store as pseudorandom number
    call rand
    ret

;-------------------------------------------------------------------------------
; Generate a random number
;
; CLOBBERS: DX
; RETURN: AX
;-------------------------------------------------------------------------------
rand:
    mov ax, 25173
    mul word [prn]
    add ax, 13849
    mov [prn], ax
    ret

;-------------------------------------------------------------------------------
; Generate a random number
;
; INPUT: CX - modulus value (to generate value between [ 0 - (CX-1) ])
; RETURN: DX - remainder
;-------------------------------------------------------------------------------
randmod:
    call rand       ; put random number in ax
    xor dx,dx
    div cx          ; divide by value in cx, remainder in dx
    ret

;-------------------------------------------------------------------------------
; Convert 8 bit unsigned integer to decimal string
; INPUT: AL - 8 bit unsigned integer
;-------------------------------------------------------------------------------
uint8todec:
    mov ah,0
    lea di,buffer+3
    mov cx, 3              ; digit counter
    mov [di],byte '$'      ; write terminating character
    dec di
    jmp uint16todec.nextdigit

;-------------------------------------------------------------------------------
; Convert 16 bit unsigned integer to decimal string
; INPUT: AX - 16 bit unsigned integer
;-------------------------------------------------------------------------------
uint16todec:
    lea di,buffer+5
    mov cx, 5              ; digit counter
    mov [di],byte '$'      ; write terminating character
    dec di
    
.nextdigit:
    mov dx, 0              ; clear DX before division
    mov bx, 10             ; divisor is 10
    div bx                 ; divide by 10, quotient in AX, remainder in DX
    add dl, '0'            ; convert remainder to ASCII
    mov [di], dl           ; store ASCII character in buffer
    dec di                 ; move to the next position in the buffer
    dec cx                 ; decrement digit counter
    jnz .nextdigit         ; repeat for all digits
    ret

;-------------------------------------------------------------------------------
; Convert 16 bit unsigned integer to decimal string
; INPUT: CX:BX - 32 bit unsigned integer
;-------------------------------------------------------------------------------
uint32todec:
    mov bp, 10      ; constant divider 10
    push bp         ; push terminating word
    mov dx,cx
    or dx,bx        ; assess whether uint is equal to zero
    jz .writezero   ; if so, stop routine
.next:
    xor dx, dx      ; clear remainder
    xchg ax, cx     ; exchange ax and cx
    div bp          ; divide upper word by bp
    xchg cx, ax     ; put quotient back into cx, dx contains remainder
    xchg ax, bx     ; exchange ax and bx
    div bp          ; divide dx:ax by bp
    mov bx, ax      ; copy quotient to bx
    push dx         ; put dx on stack
    or ax, cx       ; OR quotients
    jnz .next
.writechars:
    lea di,buffer   ; set pointer to buffer
.nextchar:
    pop dx          ; retrieve char
    cmp dx,bp       ; compare to divider
    jz .exit        ; if equal, exit
    add dl,'0'      ; else, add ASCII offset
    mov [di],dl     ; store result in buffer
    inc di          ; increment buffer pointer
    jmp .nextchar
.exit:
    mov dl,'$'      ; write terminating char
    mov [di],dl
    ret
.writezero:
    mov ax,0
    push ax
    jmp .writechars

;-------------------------------------------------------------------------------
; SECTION DATA
;-------------------------------------------------------------------------------
section .data

headerline:     db 0xC9,
                times 20 db 0xCD,
                db 0xBB,'$'
curline:        db 0xBA,' LINES:             ',0xBA,'$'
bottomline:     db 0xC8,
                times 20 db 0xCD,
                db 0xBC,'$'
topline:        db 0xCC,
                times 20 db 0xCD,
                db 0xB9,'$'
regularline:    db 0xBA,' . . . . . . . . . .',0xBA,'$'
strgameover:    db '!!GAME OVER!!$'
strgameover2:   db '-- Press any key to exit game. --$'

blockstr: db 0xDB,0xDB
emptystr: db ' .'

;
; static block coordinates ("alphabetical" ordering) (x,y)
;
blockspieces:
block_ipiece:  db 0x03,0x00,0x04,0x00,0x05,0x00,0x06,0x00
block_jpiece:  db 0x04,0xFF,0x04,0x00,0x05,0x00,0x06,0x00
block_lpiece:  db 0x04,0x00,0x05,0x00,0x06,0x00,0x06,0xFF
block_opiece:  db 0x04,0xFF,0x05,0xFF,0x04,0x00,0x05,0x00
block_spiece:  db 0x04,0x00,0x05,0x00,0x05,0xFF,0x06,0xFF
block_tpiece:  db 0x05,0x00,0x04,0x00,0x06,0x00,0x05,0xFF
block_zpiece:  db 0x04,0xFF,0x05,0xFF,0x05,0x00,0x06,0x00

;
; relative rotation movement (x,y)
;
rotationvectors:
rotation_ipiece: 
db 0x02,0xFF,0x01,0x00,0x00,0x01,0xFF,0x02 ; 0 -> 1
db 0x01,0x02,0x00,0x01,0xFF,0x00,0xFE,0xFF ; 1 -> 2
db 0xFE,0x01,0xFF,0x00,0x00,0xFF,0x01,0xFE ; 2 -> 3
db 0xFF,0xFE,0x00,0xFF,0x01,0x00,0x02,0x01 ; 3 -> 0
rotation_jpiece:
db 0x02,0x00,0x01,0xFF,0x00,0x00,0xFF,0x01 ; 0 -> 1
db 0x00,0x02,0x01,0x01,0x00,0x00,0xFF,0xFF ; 1 -> 2
db 0xFE,0x00,0xFF,0x01,0x00,0x00,0x01,0xFF ; 2 -> 3
db 0x00,0xFE,0xFF,0xFF,0x00,0x00,0x01,0x01 ; 3 -> 0
rotation_lpiece:
db 0x01,0xFF,0x00,0x00,0xFF,0x01,0x00,0x02 ; 0 -> 1
db 0x01,0x01,0x00,0x00,0xFF,0xFF,0xFE,0x00 ; 1 -> 2
db 0xFF,0x01,0x00,0x00,0x01,0xFF,0x00,0xFE ; 2 -> 3
db 0xFF,0xFF,0x00,0x00,0x01,0x01,0x02,0x00 ; 3 -> 0
rotation_opiece:
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; 0 -> 1
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; 1 -> 2
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; 2 -> 3
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ; 3 -> 0
rotation_spiece:
db 0x01,0xFF,0x00,0x00,0x01,0x01,0x00,0x02 ; 0 -> 1
db 0x01,0x01,0x00,0x00,0xFF,0x01,0xFE,0x00 ; 1 -> 2
db 0xFF,0x01,0x00,0x00,0xFF,0xFF,0x00,0xFE ; 2 -> 3
db 0xFF,0xFF,0x00,0x00,0x01,0xFF,0x02,0x00 ; 3 -> 0
rotation_tpiece:
db 0x00,0x00,0x01,0xFF,0xFF,0x01,0x01,0x01 ; 0 -> 1
db 0x00,0x00,0x01,0x01,0xFF,0xFF,0xFF,0x01 ; 1 -> 2
db 0x00,0x00,0xFF,0x01,0x01,0xFF,0xFF,0xFF ; 2 -> 3
db 0x00,0x00,0xFF,0xFF,0x01,0x01,0x01,0xFF ; 3 -> 0
rotation_zpiece:
db 0x02,0x00,0x01,0x01,0x00,0x00,0xFF,0x01 ; 0 -> 1
db 0x00,0x02,0xFF,0x01,0x00,0x00,0xFF,0xFF ; 1 -> 2
db 0xFE,0x00,0xFF,0xFF,0x00,0x00,0x01,0xFF ; 2 -> 3
db 0x00,0xFE,0x01,0xFF,0x00,0x00,0x01,0x01 ; 3 -> 0

wallkicks:
wallkick_jlstz:
db 0x00,0x00,0xFF,0x00,0xFF,0xFF,0x00,0x02,0xFF,0x02 ; 0 -> 1
db 0x00,0x00,0x01,0x00,0x01,0x01,0x00,0xFE,0x01,0xFE ; 1 -> 2
db 0x00,0x00,0x01,0x00,0x01,0xFF,0x00,0x02,0x01,0x02 ; 2 -> 3
db 0x00,0x00,0xFF,0x00,0xFF,0x01,0x00,0xFE,0xFF,0xFE ; 3 -> 0
wallkick_i:
db 0x00,0x00,0xFE,0x00,0x01,0x00,0xFE,0x01,0x01,0xFE ; 0 -> 1
db 0x00,0x00,0xFF,0x00,0x02,0x00,0xFF,0xFE,0x02,0x01 ; 1 -> 2
db 0x00,0x00,0x02,0x00,0xFF,0x00,0x02,0xFF,0xFF,0x02 ; 2 -> 3
db 0x00,0x00,0x01,0x00,0xFE,0x00,0x01,0x02,0xFE,0xFF ; 3 -> 0

linescores: 
db 0x28,0x00    ; 1 line : 40 points
db 0x64,0x00    ; 2 lines: 100 points
db 0x2C,0x01    ; 3 lines: 300 points
db 0xE8,0x03    ; 4 lines: 1000 points

scorestr: db '  SCORE   $'
levelstr: db '  LEVEL  $'
nextstr: db 0xBA,'  NEXT  ',0xBA,'$'

titlepagestr:
db ' _________  _______  _________  ________  ___     ___    ___ $'
db '|\___   ___\\  ___ \|\___   ___\\   __  \|\  \   |\  \  /  /|$'
db '\|___ \  \_\ \   __/\|___ \  \_\ \  \|\  \ \  \  \ \  \/  / /$'
db '     \ \  \ \ \  \_|/__  \ \  \ \ \   _  _\ \  \  \ \    / / $'
db '      \ \  \ \ \  \_|\ \  \ \  \ \ \  \\  \\ \  \  /     \/  $'
db '       \ \__\ \ \_______\  \ \__\ \ \__\\ _\\ \__\/  /\   \  $'
db '        \|__|  \|_______|   \|__|  \|__|\|__|\|__/__/ /\ __\ $'
db '     An IBM compatible Tetris clone by Ivo Filot |__|/ \|__| $'
db '     https://github.com/ifilot/tetrix             ( v0.2.0 ) $'
levelselstr: db '[0-9] Starting level:$'
randomstr1: db '[A] and [B] Piece generation:$'
randomstr2: db 'RANDOM   BAG$'
startstr: db '-- Hit ENTER to start game --$'

;-------------------------------------------------------------------------------
; SECTION BLOCK STARTING SYMBOL
;-------------------------------------------------------------------------------
section .bss

blocktype: resb 1       ; current block type
blockrot: resb 1        ; current block rotation
prn: resb 2             ; pseudorandom number
timestamp: resb 4       ; current system timestamp
blockcoord: resb 8      ; 4 blocks x 2 coordinates
tempblockcoord: resb 8  ; temporary block position
field: resb 200         ; 20 rows x 10 columns
bplcnt: resb 20         ; counter how many blocks per line there are
nrlinesrem: resb 1      ; number of lines that will be removed
linescleared: resb 2    ; total number of lines cleared in the game
score: resb 4           ; current game score
drawbag: resb 7         ; bag of 7 tetris pieces, generated randomly
drawptr: resb 1         ; pointer to bag position
buffer: resb 20         ; buffer for temporary storage
speed: resb 1           ; movement speed of the pieces
level: resb 1           ; current level
randomtype: resb 1      ; which RNG for piece selection to use
blockstats: resb 14     ; counter for how many pieces of particular type      
