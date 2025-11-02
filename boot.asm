[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov [boot_drive], dl

    ; Clear screen (Yellow on Blue)
    mov ah, 0x06
    xor al, al
    xor cx, cx
    mov dx, 0x184F
    mov bh, 0x1E
    int 0x10

    ; Set cursor top-left
    mov ah, 0x02
    xor bh, bh
    xor dh, dh
    xor dl, dl
    int 0x10

    ; Print boot message
    mov si, msg
print_msg:
    lodsb
    or al, al
    jz done_msg_print
    mov ah, 0x0E
    mov bl, 0x1E
    int 0x10
    jmp print_msg
done_msg_print:

    ; Progress bar loop (1..20)
    mov si, 1
next_step:
    push si
    call draw_bar
    pop si
    call delay
    inc si
    cmp si, 21
    jl next_step

    ; Ensure 100% step
    mov si, 20
    call draw_bar
    call delay

    ; Clear screen (Black on White)
    mov ah, 0x06
    xor al, al
    xor cx, cx
    mov dx, 0x184F
    mov bh, 0x0F
    int 0x10

    ; Reset cursor
    mov ah, 0x02
    xor bh, bh
    xor dh, dh
    xor dl, dl
    int 0x10

    ; Print done message
    mov si, done_msg
print_done:
    lodsb
    or al, al
    jz show_welcome
    mov ah, 0x0E
    mov bl, 0x0F
    int 0x10
    jmp print_done

; -------------------------------
; Show welcome message
; -------------------------------
show_welcome:
    mov ah, 0x02
    xor bh, bh
    mov dh, 2
    xor dl, dl
    int 0x10

    mov si, welcome_msg
print_welcome:
    lodsb
    or al, al
    jz check_key
    mov ah, 0x0E
    mov bl, 0x0F
    int 0x10
    jmp print_welcome

check_key:
    mov ah, 0x00  ; BIOS keyboard function (wait for keypress)
    int 0x16      ; Call BIOS keyboard interrupt
    
    cmp al, 'R'   ; Check if key is uppercase R
    je reload
    cmp al, 'r'   ; Check if key is lowercase r
    je reload
    jmp check_key ; If not R/r, keep checking

reload:
    jmp 0x0000:0x7C00 ; Jump back to bootloader start

hang:
    jmp hang   ; infinite loop (fallback)

; -------------------------------
; Draw progress bar
; -------------------------------
draw_bar:
    pusha
    mov ah, 0x02
    xor bh, bh
    mov dh, 2
    xor dl, dl
    int 0x10

    mov cx, 30
clear_line_bar:
    mov ah, 0x0E
    mov al, ' '
    mov bl, 0x1E
    int 0x10
    loop clear_line_bar

    mov ah, 0x02
    xor bh, bh
    mov dh, 2
    xor dl, dl
    int 0x10

    mov ah, 0x0E
    mov al, '['
    mov bl, 0x1E
    int 0x10

    mov cx, si
print_hash:
    cmp cx, 0
    je print_spaces
    mov al, '#'
    mov bl, 0x1E
    int 0x10
    dec cx
    jmp print_hash

print_spaces:
    mov cx, 20
    sub cx, si
print_space_loop:
    cmp cx, 0
    je print_bracket
    mov al, ' '
    mov bl, 0x1E
    int 0x10
    dec cx
    jmp print_space_loop

print_bracket:
    mov al, ']'
    mov bl, 0x1E
    int 0x10
    mov al, ' '
    mov bl, 0x1E
    int 0x10

    mov ax, si
    mov bx, 5
    mul bx
    mov dx, 0
    mov bx, 10
    div bx
    add al, '0'
    mov ah, 0x0E
    mov bl, 0x1E
    int 0x10
    mov al, dl
    add al, '0'
    int 0x10
    mov al, '%'
    int 0x10

    popa
    ret

; -------------------------------
; Delay routine
; -------------------------------
delay:
    mov cx, 0FFFh
delay1:
    mov dx, 0FFFFh
delay2:
    dec dx
    jnz delay2
    dec cx
    jnz delay1
    ret

; -------------------------------
; Data / messages
; -------------------------------
boot_drive db 0

msg db "Booting BrownOS...",0
done_msg db "BrownOS Loaded",0
welcome_msg db "Welcome to BrownOS!",0

times 510-($-$$) db 0
dw 0xAA55
