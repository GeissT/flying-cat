; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2010 Return Infinity -- see LICENSE.TXT
;
; The BareMetal OS kernel. Assemble with NASM
; =============================================================================


USE64
ORG 0x0000000000100000

%DEFINE BAREMETALOS_VER 'v0.4.8 (July 13, 2010)'
%DEFINE BAREMETALOS_API_VER 1

kernel_start:
	jmp start		; Skip over the function call index

	align 16		; 0x0010
	jmp os_print_string
	align 8			; 0x0018
	jmp os_print_char
	align 8			; 0x0020
	jmp os_print_char_hex
	align 8			; 0x0028
	jmp os_print_newline
	align 8			; 0x0030
	jmp os_input_key_check
	align 8			; 0x0038
	jmp os_input_key_wait
	align 8			; 0x0040
	jmp os_input_string
	align 8			; 0x0048
	jmp os_delay
	align 8			; 0x0050
	jmp os_speaker_tone
	align 8			; 0x0058
	jmp os_speaker_off
	align 8			; 0x0060
	jmp os_speaker_beep
	align 8			; 0x0068
	jmp os_move_cursor
	align 8			; 0x0070
	jmp os_string_length
	align 8			; 0x0078
	jmp os_string_find_char
	align 8			; 0x0080
	jmp os_string_copy
	align 8			; 0x0088
	jmp os_string_truncate
	align 8			; 0x0090
	jmp os_string_join
	align 8			; 0x0098
	jmp os_string_chomp
	align 8			; 0x00A0
	jmp os_string_strip
	align 8			; 0x00A8
	jmp os_string_compare
	align 8			; 0x00B0
	jmp os_string_uppercase
	align 8			; 0x00B8
	jmp os_string_lowercase
	align 8			; 0x00C0
	jmp os_int_to_string
	align 8			; 0x00C8
	jmp os_string_to_int
	align 8			; 0x00D0
	jmp os_debug_dump_reg
	align 8			; 0x00D8
	jmp os_debug_dump_mem
	align 8			; 0x00E0
	jmp os_debug_dump_rax
	align 8			; 0x00E8
	jmp os_debug_dump_eax
	align 8			; 0x00F0
	jmp os_debug_dump_ax
	align 8			; 0x00F8
	jmp os_debug_dump_al
	align 8			; 0x0100
	jmp os_smp_reset
	align 8			; 0x0108
	jmp os_smp_get_id
	align 8			; 0x0110
	jmp os_smp_enqueue
	align 8			; 0x0118
	jmp os_smp_dequeue
	align 8			; 0x0120
	jmp os_serial_send
	align 8			; 0x0128
	jmp os_serial_recv
	align 8			; 0x0130
	jmp os_string_parse
	align 8			; 0x0138
	jmp os_get_argc
	align 8			; 0x0140
	jmp os_get_argv
	align 8			; 0x0148
	jmp os_smp_queuelen
	align 8			; 0x0150
	jmp os_smp_wait
	align 8			; 0x0158
	jmp os_get_timecounter
	align 8			; 0x0160
	jmp os_string_append
	align 8			; 0x0168
	jmp os_int_to_hex_string
	align 8			; 0x0170
	jmp os_hex_string_to_int
	align 8			; 0x0178
	jmp os_string_change_char
	align 8			; 0x0180
	jmp os_is_digit
	align 8			; 0x0188
	jmp os_is_alpha
	align 8			; 0x0190
	jmp os_file_read
	align 8			; 0x0198
	jmp os_file_write
	align 8			; 0x01A0
	jmp os_file_delete
	align 8			; 0x01A8
	jmp os_file_get_list
	align 8			; 0x01B0
	jmp os_smp_run
	align 8			; 0x01B8
	jmp os_smp_lock
	align 8			; 0x01C0
	jmp os_smp_unlock
	align 8			; 0x01C8
	jmp os_print_string_with_color
	align 8			; 0x01D0
	jmp os_print_char_with_color


align 16

start:

	call init_64			; After this point we are in a working 64-bit enviroment

	call hdd_setup			; Gather information about the harddrive and set it up

;	call init_pci

	call os_clear_screen

	mov ax, 0x0016			; Print the "ready" message
	call os_move_cursor
	mov rsi, readymsg
	call os_print_string

	mov ax, 0x0018			; Set the hardware cursor to the bottom left-hand corner
	call os_move_cursor
	call os_show_cursor

	; We fall through to ap_clear as align fills the space with No-Ops
	; At this point the BSP is just like one of the AP's


align 16

ap_clear:				; All cores start here on first start and after an exception

	cli				; Disable interrupts on this core

	; Get local ID of the core
	mov rsi, [os_LocalAPICAddress]
	add rsi, 0x20			; Add the offset for the APIC ID
	lodsd				; Load a 32-bit value. We only want the high 8 bits
	shr rax, 24			; Shift to the right and AL now holds the CPU's APIC ID

	; Calculate offset into CPU status table
	mov rdi, cpustatus
	add rdi, rax			; RDI points to this cores status byte (we will clear it later)

	; Set up the stack
	shl rax, 10			; Shift left 10 bits for a 1024-byte stack
	add rax, stackbase		; The stack decrements when you "push", start at 1024 bytes in
	mov rsp, rax			; Pure64 leaves 0x50000-0x9FFFF free so we use that

	; Set the CPU status to "Ready"
	mov al, 00000001b		; Bit 0 set for "Present", Bit 1 clear for "Ready"
	stosb				; Set status to Ready for this CPU

	sti				; Re-enable interrupts

	; Clear registers. Gives us a clean slate to work with
	xor rax, rax			; aka r0
	xor rcx, rcx			; aka r1
	xor rdx, rdx			; aka r2
	xor rbx, rbx			; aka r3
	xor rbp, rbp			; aka r5, We skip RSP (aka r4) as it was previously set
	xor rsi, rsi			; aka r6
	xor rdi, rdi			; aka r7
	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15

ap_spin:				; Spin until there is a workload in the queue
	cmp word [os_QueueLen], 0	; Check the length of the queue
	je ap_pause			; If the queue was empty then jump to the PAUSE
	call os_smp_dequeue		; Try to pull a workload out of the queue
	jnc ap_process			; Carry clear if successful, jump to ap_process

ap_pause:				; Pause for a bit
	pause				; If carry was set we fall through to the PAUSE
	jmp ap_spin			; Try again

ap_process:				; Set the status byte to "Busy" and run the code
	push rax			; Push RAX since os_smp_get_id uses it
	mov rdi, cpustatus
	call os_smp_get_id		; Set RAX to the APIC ID
	add rdi, rax
	mov al, 00000011b		; Bit 0 set for "Present", Bit 1 set for "Busy"
	stosb
	xor rdi, rdi
	pop rax				; Pop RAX (holds the workload code address)

	call rax			; Run the code

	jmp ap_clear			; Reset the stack, clear the registers, and wait for something else to work on


; Includes
%include "init_64.asm"
%include "init_hdd.asm"
%include "syscalls.asm"
%include "drivers.asm"
%include "interrupt.asm"
%include "cli.asm"
%include "sysvar.asm"			; Include this last to keep the read/write variables away from the code

times 16384-($-$$) db 0			; Set the compiled kernel binary to at least this size in bytes


; =============================================================================
; EOF
