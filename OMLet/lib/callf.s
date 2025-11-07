.globl callf

callf:

    # --- registers and memory initialization ---

    # allocate stack space
    addi sp, sp, -80
    # save used below registers on stack
    sd ra, 72(sp)
    sd s0, 64(sp)
    sd s1, 56(sp)
    sd s2, 48(sp)
    sd s3, 40(sp)
    sd s4, 32(sp)
    # put code pointer into s0
    mv s0, a0
    # put arity into s1
    mv s1, a1
    # put arguments pointer into s2
    mv s2, a2

    # --- calculation of required stack space for arguments ---

    # calculate count of bytes for arguments, considering 16-byte alignment
    # put "arity + 1" into t0
    addi t0, s1, 1
    # round up t0 to nearest lower even number
    andi t0, t0, -2
    # put count of bytes needed (t0 * 8) into s3
    slli s3, t0, 3
    
    # --- aligning of stack pointer to 16 bytes boundary ---

    # put stack pointer into t1
    mv t1, sp
    # clear lower 4 bits to get 16-byte aligned value
    andi t1, t1, -16
    # allocate needed amount of bytes for arguments
    sub t1, t1, s3
    # save original stack pointer into s4
    mv s4, sp
    # update stack pointer with new aligned value
    mv sp, t1

    # initialize loop counter for further args copy
    mv t3, zero

.copy_args_loop:
    # --- copying arguments on stack ---

    # if our counter is equal to arity, we are done copying - then do call function
    beq t3, s1, .call_function
    # put current byte offset (t3 * 8) into t4
    slli t4, t3, 3
    # put source of argument address into t5 (args pointer + byte offset)
    add t5, s2, t4
    # load argument into t6
    ld t6, 0(t5)
    # put destination address into t0 (stack pointer + byte offset)
    add t0, sp, t4
    # store argument into destination address of stack
    sd t6, 0(t0)
    # increment loop counter
    addi t3, t3, 1
    # go on copying
    j .copy_args_loop

.call_function:
    # --- prepare registers and call the function, then clean up ---
    # put code pointer into t0
    mv t0, s0
    # put previous return value from s11 into a0
    mv a0, s11
    # jump and link to function
    jalr t0
    # restore original stack pointer
    mv sp, s4
    # restore registers
    ld s4, 32(sp)
    ld s3, 40(sp)
    ld s2, 48(sp)
    ld s1, 56(sp)
    ld s0, 64(sp)
    ld ra, 72(sp)
    # deallocate stack space
    addi sp, sp, 80
    ret
