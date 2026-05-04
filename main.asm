; ============================================================
; On-Demand Traffic Light - ATmega32 Assembly
; PIN: PA0=Car RED, PA1=Car YELLOW, PA2=Car GREEN
;      PB0=Ped RED, PB1=Ped GREEN, PD2=Button (INT0)
; ============================================================

.include "m32def.inc"

.equ CAR_RED    = 0
.equ CAR_YELLOW = 1
.equ CAR_GREEN  = 2
.equ PED_RED    = 0
.equ PED_GREEN  = 1

.dseg
ped_request: .byte 1

.cseg
.org 0x0000
    rjmp MAIN

.org 0x0002
    rjmp ISR_INT0

ISR_INT0:
    push r16
    in   r16, SREG
    push r16
    ldi  r16, 0x01
    sts  ped_request, r16
    pop  r16
    out  SREG, r16
    pop  r16
    reti

MAIN:
    ldi  r16, low(RAMEND)
    out  SPL, r16
    ldi  r16, high(RAMEND)
    out  SPH, r16
    ldi  r16, 0x07
    out  DDRA, r16
    ldi  r16, 0x03
    out  DDRB, r16
    in   r16, DDRD
    andi r16, 0xFB
    out  DDRD, r16
    in   r16, PORTD
    ori  r16, 0x04
    out  PORTD, r16
    in   r16, MCUCR
    ori  r16, 0x02
    andi r16, 0xFE
    out  MCUCR, r16
    in   r16, GICR
    ori  r16, 0x40
    out  GICR, r16
    ldi  r16, 0x00
    sts  ped_request, r16
    sei
    sbi  PORTB, 0
    sbi  PORTA, 2

LOOP:
    lds  r16, ped_request
    cpi  r16, 0x01
    brne SKIP_PED
    ldi  r16, 0x00
    sts  ped_request, r16
    rcall PEDESTRIAN_MODE
SKIP_PED:
    rcall NORMAL_MODE
    rjmp  LOOP

ALL_OFF:
    in   r16, PORTA
    andi r16, 0xF8
    out  PORTA, r16
    in   r16, PORTB
    andi r16, 0xFC
    out  PORTB, r16
    ret

PEDESTRIAN_MODE:
    rcall ALL_OFF
    sbi   PORTA, 0
    sbi   PORTB, 1
    cbi   PORTB, 0
    ldi   r20, 50
PED_WAIT:
    rcall DELAY_100MS
    dec   r20
    brne  PED_WAIT
    ldi   r20, 4
BLINK_LOOP:
    in    r16, PORTB
    ldi   r17, 0x02
    eor   r16, r17
    out   PORTB, r16
    rcall DELAY_300MS
    dec   r20
    brne  BLINK_LOOP
    rcall ALL_OFF
    sbi   PORTB, 0
    ret

NORMAL_MODE:
    rcall ALL_OFF
    sbi   PORTB, 0
    sbi   PORTA, 2
    ldi   r20, 50
GREEN_LOOP:
    rcall DELAY_100MS
    lds   r16, ped_request
    cpi   r16, 1
    breq  NORMAL_EXIT
    dec   r20
    brne  GREEN_LOOP
    rcall ALL_OFF
    sbi   PORTB, 0
    sbi   PORTA, 1
    ldi   r20, 20
YELLOW_LOOP:
    rcall DELAY_100MS
    lds   r16, ped_request
    cpi   r16, 1
    breq  NORMAL_EXIT
    dec   r20
    brne  YELLOW_LOOP
    rcall ALL_OFF
    sbi   PORTB, 0
    sbi   PORTA, 0
    ldi   r20, 30
RED_LOOP:
    rcall DELAY_100MS
    lds   r16, ped_request
    cpi   r16, 1
    breq  NORMAL_EXIT
    dec   r20
    brne  RED_LOOP
NORMAL_EXIT:
    ret

DELAY_100MS:
    ldi  r24, 21
D100_OUTER:
    ldi  r25, 238
D100_INNER:
    ldi  r26, 160
D100_INNER2:
    dec  r26
    brne D100_INNER2
    dec  r25
    brne D100_INNER
    dec  r24
    brne D100_OUTER
    ret

DELAY_300MS:
    rcall DELAY_100MS
    rcall DELAY_100MS
    rcall DELAY_100MS
    ret