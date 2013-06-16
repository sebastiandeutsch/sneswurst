;============================================================================
; Includes
;============================================================================

;== Include MemoryMap, Vector Table, and HeaderInfo ==
.INCLUDE "header.inc"

;== Include SNES Initialization routines ==
.INCLUDE "InitSNES.asm"

;============================================================================
; Macros
;============================================================================
;============================================================================
;LoadPalette - Macro that loads palette information into CGRAM
;----------------------------------------------------------------------------
; In: SRC_ADDR -- 24 bit address of source data,
;     START -- Color # to start on,
;     SIZE -- # of COLORS to copy
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: A,X
; Requires: mem/A = 8 bit, X/Y = 16 bit
;----------------------------------------------------------------------------
.MACRO LoadPalette
    lda #\2
    sta $2121       ; Start at START color
    lda #:\1        ; Using : before the parameter gets its bank.
    ldx #\1         ; Not using : gets the offset address.
    ldy #(\3 * 2)   ; 2 bytes for every color
    jsr DMAPalette
.ENDM

;============================================================================
; LoadBlockToVRAM -- Macro that simplifies calling LoadVRAM to copy data to VRAM
;----------------------------------------------------------------------------
; In: SRC_ADDR -- 24 bit address of source data
;     DEST -- VRAM address to write to (WORD address!!)
;     SIZE -- number of BYTEs to copy
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: A, X, Y
;----------------------------------------------------------------------------

;LoadBlockToVRAM SRC_ADDRESS, DEST, SIZE
;   requires:  mem/A = 8 bit, X/Y = 16 bit
.MACRO LoadBlockToVRAM
    ldx #\2         ; DEST
    stx $2116       ; $2116: Word address for accessing VRAM.
    lda #:\1        ; SRCBANK
    ldx #\1         ; SRCOFFSET
    ldy #\3         ; SIZE
    jsr LoadVRAM
.ENDM



.bank 0 slot 0
.org 0
.section "Vblank"
;--------------------------------------
VBlank:

    pha

    lda $0004
    inc a
    sta $0004
    sta $210D
    stz $210D

    pla

    rti
.ends

;============================================================================
; Main Code
;============================================================================

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
    InitSNES    ; Clear registers, etc.

    ; Load Palette for our tiles
    LoadPalette BG_Palette, 0, 16

    ; Load Tile data to VRAM
    ; LoadBlockToVRAM Tiles_9, $0000, 32*1	; 2 tiles, 2bpp, = 32 bytes
    LoadBlockToVRAM Tiles_9, $0000, 1024*8

    lda #$00
    sta $2115
    ldx #$4000
    stx $2116


    ; let's write it 4 times
    lda #(128 / 8)

FillTileMapV:
    pha
    lda #(128 / 8)
FillTileMapH:
    pha

    lda $0000
    sta $2118
    inc a
    sta $0000

    pla

    dec a
    cmp #0
    bne FillTileMapH

    lda #(32 - 128 / 8)
ClearTileMapH:
    stz $2118
    dec a
    cmp #0
    bne ClearTileMapH

    pla
    dec a
    cmp #0
    bne FillTileMapV



;    lda #$03
;    sta $210D
;    stz $210D


    ; Setup Video modes and other stuff, then turn on the screen
    jsr SetupVideo

    stz $0000

Infinity:
    wai

    jmp Infinity    ; bwa hahahahaha


;============================================================================
; SetupVideo -- Sets up the video mode and tile-related registers
;----------------------------------------------------------------------------
; In: None
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
SetupVideo:
    lda #$01
    sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

    lda #$40            ; Set BG1's Tile Map offset to $4000 (Word address)
    sta $2107           ; And the Tile Map size to 32x32

    stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

    lda #$01            ; Enable BG1
    sta $212C

    lda #$FF
    sta $210E
    sta $210E

    lda #$0F
    sta $2100           ; Turn on screen, full Brightness

    lda #%10000001  ; enable NMI and joypads
    sta $4200

    rts
;============================================================================

;============================================================================
; LoadVRAM -- Load data into VRAM
;----------------------------------------------------------------------------
; In: A:X  -- points to the data
;     Y     -- Number of bytes to copy (0 to 65535)  (assumes 16-bit index)
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
; Notes:  Assumes VRAM address has been previously set!!
;----------------------------------------------------------------------------
LoadVRAM:
    stx $4302   ; Store Data offset into DMA source offset
    sta $4304   ; Store data Bank into DMA source bank
    sty $4305   ; Store size of data block

    lda #$01
    sta $4300   ; Set DMA mode (word, normal increment)
    lda #$18    ; Set the destination register (VRAM write register)
    sta $4301
    lda #$01    ; Initiate DMA transfer (channel 1)
    sta $420B

    rts         ; return
;============================================================================

;============================================================================
; DMAPalette -- Load entire palette using DMA
;----------------------------------------------------------------------------
; In: A:X  -- points to the data
;      Y   -- Size of data
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
DMAPalette:
    stx $4302   ; Store data offset into DMA source offset
    sta $4304   ; Store data bank into DMA source bank
    sty $4305   ; Store size of data block

    stz $4300  ; Set DMA Mode (byte, normal increment)
    lda #$22    ; Set destination register ($2122 - CGRAM Write)
    sta $4301
    lda #$01    ; Initiate DMA transfer
    sta $420B

    rts         ; return from subroutine


.ENDS

;============================================================================
; Character Data
;============================================================================
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

    .INCLUDE "tiles.inc"

.ENDS