.globl callf

callf:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    sd s1, 56(sp)
    sd s2, 48(sp)
    sd s3, 40(sp)
    sd s4, 32(sp)
    mv s0, a0
    mv s1, a1
    mv s2, a2
    addi t0, s1, 1
    andi t0, t0, -2
    slli s3, t0, 3
    mv t1, sp
    andi t1, t1, -16
    sub t1, t1, s3
    mv s4, sp
    mv sp, t1
    mv t3, zero

.copy_args_loop:
    beq t3, s1, .call_function
    slli t4, t3, 3
    add t5, s2, t4
    ld t6, 0(t5)
    add t0, sp, t4
    sd t6, 0(t0)
    addi t3, t3, 1
    j .copy_args_loop

.call_function:
    mv t0, s0
    mv a0, s11
    jalr t0
    mv sp, s4
    ld s4, 32(sp)
    ld s3, 40(sp)
    ld s2, 48(sp)
    ld s1, 56(sp)
    ld s0, 64(sp)
    ld ra, 72(sp)
    addi sp, sp, 80
    ret
