        NAME    STARTUP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   C0SMROM                                  ;
;                               Startup Template                             ;
;                    Intel C Small Memory Model, ROM Option                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains a template for the startup code used when interfacing to
; C code compiled with the Intel C compiler using the small memory model and
; ROM option.  It assumes nothing about the system hardware, it's main purpose
; is to setup the groups and segments correctly.  Note that most segments are
; empty, they are present only for the GROUP definitions.  The actual startup
; code for a system would include definitions for the global variables and all
; of the system initialization.  Note that the CONST segment does not exist
; for ROMmable code (it is automatically made part of the CODE segment by the
; compiler).
;
;
; Revision History:
;    3/7/94   Glen George       Initial revision.
;    2/28/95  Glen George       Fixed segment alignments.
;                               Fixed SP initialization.
;                               Removed CS:IP initialization (END Start -> END).
;                               Updated comments.
;    2/29/96  Glen George       Updated comments.
;    2/24/98  Glen George       Updated comments.
;   11/18/98  Glen George       Updated comments.
;   12/26/99  Glen George       Changed formatting.
;    1/30/02  Glen George       Added proper assume for ES.
;    1/27/03  Glen George       Changed to looping if main() returns instead
;                                  of halting
;    4/19/16  Tim Liu       Added initcs and created infinite loop
;    4/19/16  Tim Liu       Changed name to STARTUP
;    4/19/16  Tim Liu       Reordered assumes and group declarations
;    4/19/16  Tim Liu       Added START and END START CS:IP init
;    4/20/16  Tim Liu       Added write to LMCS before func calls
;    4/21/16  Tim Liu       Added calls to set up timer0 and buttons
;    4/28/16  Tim Liu       Temporarily replaced main call with infinite loop
; local include files

$INCLUDE(INITREG.INC)


; setup code and data groups
CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



; the actual startup code - should be executed (jumped to) after reset

CODE    SEGMENT  WORD  PUBLIC  'CODE'

; segment register assumptions

        ASSUME  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:DGROUP



        EXTRN    main:NEAR              ;declare the main function
        EXTRN    InitCS:NEAR            ;initialize chip selects
        EXTRN    ClrIRQVectors:NEAR     ;clear interrupt vector table
        EXTRN    InstallTimer0Handler:NEAR  ;install timer 0 handler
        EXTRN    InitTimer0:NEAR        ;start up timer0
        EXTRN    InitButtons:NEAR       ;initialize the buttons
        EXTRN    InitDisplayLCD:NEAR    ;initialize the LCD display

START:


BEGIN:                                  ;start the program
        CLI                             ;disable interrupts
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; user initialization code goes here ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        MOV     DX, LMCSreg             ;setup to write to MPCS register
        MOV     AX, LMCSval
        OUT     DX, AL                  ;write MPCSval to MPCS

        CALL    InitCS                  ;initialize chip selects
        CALL    ClrIRQVectors           ;clear interrupt vector table

        CALL    InitButtons             ;initialize the buttons
        CALL    InitDisplayLCD          ;initialize the LCD display

        CALL    InstallTimer0Handler    ;install handler
        CALL    InitTimer0              ;initialize timer0 for button interrupt

        STI                             ;enable interrupts

        CALL    main                    ;run the main function (no arguments)
Infinite:
        JMP    Infinite

        JMP     Start                   ;if return - reinitialize and try again


CODE    ENDS

; the stack segment - used for subroutine linkage, argument passing, and
; local variables

STACK   SEGMENT  WORD  STACK  'STACK'


        DB      80 DUP ('Stack   ')             ;320 words

TopOfStack      LABEL   WORD


STACK   ENDS

; the data segment - used for static and global variables

DATA    SEGMENT  WORD  PUBLIC  'DATA'


DATA    ENDS




        END START
