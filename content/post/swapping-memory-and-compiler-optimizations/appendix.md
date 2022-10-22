---
title: 'Swapping memory and compiler optimizations - Appendix'
date: 2022-02-13
draft: true
toc: true
---

Appendix for [Swapping memory and compiler optimizations](/post/swapping-memory-and-compiler-optimizations)

## Tables

### time (us), 4MB swap

|                         |   -O0 |   -Os |   -O2 |   -O3 |
|-------------------------|-------|-------|-------|-------|
| clang generic           |  9600 |  2900 |   310 |   307 |
| gcc   generic           |  9600 |  2900 |  2450 |   325 |
| clang memcpy            |   370 |   270 |   318 |   318 |
| gcc   memcpy            |   525 |   570 |   355 |   355 |
| clang memcpy ptr        |   285 |   285 |   285 |   285 |
| gcc   memcpy ptr        |   315 |   590 |   335 |   345 |
| clang sse               |  1540 |   280 |   310 |   310 |
| gcc   sse               |  1550 |   285 |   320 |   320 |
| clang avx               |  2200 |   238 |   260 |   260 |
| gcc   avx               |   900 |   232 |   310 |   305 |
| clang sse2_unroll       |  1000 |   188 |   175 |   175 |
| gcc   sse2_unroll       |  1000 |   190 |   195 |   195 |
| clang avx_unroll        |  2100 |   127 |   115 |   115 |
| gcc   avx_unroll        |   590 |   125 |   158 |   158 |
| clang std::swap_ranges  | 32000 |  2800 |   282 |   282 |
| gcc   std::swap_ranges  | 45000 |  2350 |  2300 |   282 |
| clang memcpy_only       |   144 |   136 |   144 |   144 |
| gcc   memcpy_only       |   144 |   170 |   144 |   144 |


### code size (bytes)

|                         |   -O0 |   -Os |   -O2 |   -O3 |
|-------------------------|-------|-------|-------|-------|
| clang generic           |   125 |    30 |   322 |   322 |
| gcc   generic           |   125 |    31 |    42 |   618 |
| clang memcpy            |   420 |   212 |   215 |   215 |
| gcc   memcpy            |  1176 |    77 |   942 |   942 |
| clang memcpy ptr        |   453 |    77 |   215 |   215 |
| gcc   memcpy ptr        |   513 |    77 |   942 |   942 |
| clang sse               |   306 |    78 |   312 |   312 |
| gcc   sse               |   304 |    61 |    90 |   557 |
| clang avx               |   580 |    85 |   331 |   331 |
| gcc avx                 |   379 |    65 |   130 |   721 |
| clang sse2_unroll       |   990 |   146 |   376 |   376 |
| gcc   sse2_unroll       |   975 |   119 |   146 |   611 |
| clang avx_unroll        |  1817 |   165 |   411 |   411 |
| gcc   avx_unroll        |  1125 |   135 |   282 |   881 |
| clang std::swap_ranges  |  189* |    30 |   284 |   284 |
| gcc   std::swap_ranges  |  308* |    31 |    42 |   512 |
| clang memcpy_only       |    43 |     5 |     5 |     5 |
| gcc   memcpy_only       |    50 |    10 |     9 |     9 |

* std::swap_ranges in `-O0` is an estimate and sum of all non-inlined std functions, functions used are 


## Assembly

### `memswap_generic()`, `-O0`, `clang`

```asm
<memswap_memcpy(void*, void*, unsigned long)>:
    push   %rbp
    mov    %rsp,%rbp
    sub    $0x160,%rsp
    mov    %rdi,-0x8(%rbp)
    mov    %rsi,-0x10(%rbp)
    mov    %rdx,-0x18(%rbp)
    mov    -0x8(%rbp),%rax
    mov    %rax,-0x20(%rbp)
    mov    -0x10(%rbp),%rax
    mov    %rax,-0x28(%rbp)
    mov    -0x18(%rbp),%rax
    shr    $0x8,%rax
    mov    %rax,-0x138(%rbp)
    movq   $0x0,-0x140(%rbp)
    mov    -0x140(%rbp),%rax
    cmp    -0x138(%rbp),%rax
    jae    40627c <memswap_memcpy(void*, void*, unsigned long)+0xfc>
    lea    -0x130(%rbp),%rax
    mov    -0x140(%rbp),%rcx
    shl    $0x8,%rcx
    mov    %rcx,-0x148(%rbp)
    mov    -0x20(%rbp),%rcx
    add    -0x148(%rbp),%rcx
    mov    %rax,%rdi
    mov    %rcx,%rsi
    mov    $0x100,%ecx
    mov    %rcx,%rdx
    mov    %rax,-0x150(%rbp)
    mov    %rcx,-0x158(%rbp)
    callq  401080 <memcpy@plt>
    mov    -0x20(%rbp),%rax
    add    -0x148(%rbp),%rax
    mov    -0x28(%rbp),%rcx
    add    -0x148(%rbp),%rcx
    mov    %rax,%rdi
    mov    %rcx,%rsi
    mov    -0x158(%rbp),%rdx
    callq  401080 <memcpy@plt>
    mov    -0x28(%rbp),%rax
    add    -0x148(%rbp),%rax
    mov    %rax,%rdi
    mov    -0x150(%rbp),%rsi
    mov    -0x158(%rbp),%rdx
    callq  401080 <memcpy@plt>
    mov    -0x140(%rbp),%rax
    add    $0x1,%rax
    mov    %rax,-0x140(%rbp)
    jmpq   4061c1 <memswap_memcpy(void*, void*, unsigned long)+0x41>
    lea    -0x130(%rbp),%rax
    mov    -0x20(%rbp),%rcx
    mov    -0x138(%rbp),%rdx
    shl    $0x8,%rdx
    add    %rdx,%rcx
    mov    -0x18(%rbp),%rdx
    and    $0xff,%rdx
    mov    %rax,%rdi
    mov    %rcx,%rsi
    mov    %rax,-0x160(%rbp)
    callq  401080 <memcpy@plt>
    mov    -0x20(%rbp),%rax
    mov    -0x138(%rbp),%rcx
    shl    $0x8,%rcx
    add    %rcx,%rax
    mov    -0x28(%rbp),%rcx
    mov    -0x138(%rbp),%rdx
    shl    $0x8,%rdx
    add    %rdx,%rcx
    mov    -0x18(%rbp),%rdx
    and    $0xff,%rdx
    mov    %rax,%rdi
    mov    %rcx,%rsi
    callq  401080 <memcpy@plt>
    mov    -0x28(%rbp),%rax
    mov    -0x138(%rbp),%rcx
    shl    $0x8,%rcx
    add    %rcx,%rax
    mov    -0x18(%rbp),%rcx
    and    $0xff,%rcx
    mov    %rax,%rdi
    mov    -0x160(%rbp),%rsi
    mov    %rcx,%rdx
    callq  401080 <memcpy@plt>
    add    $0x160,%rsp
    pop    %rbp
    retq   
    nopw   %cs:0x0(%rax,%rax,1)

    xchg   %ax,%ax

```


### `memswap_generic()`, `-O0`, `gcc`

```asm
<memswap_memcpy(void*, void*, unsigned long)>:
    endbr64 
    push   %rbp
    mov    %rsp,%rbp
    push   %rbx
    sub    $0x168,%rsp
    mov    %rdi,-0x158(%rbp)
    mov    %rsi,-0x160(%rbp)
    mov    %rdx,-0x168(%rbp)
    mov    %fs:0x28,%rax

    mov    %rax,-0x18(%rbp)
    xor    %eax,%eax
    mov    -0x158(%rbp),%rax
    mov    %rax,-0x140(%rbp)
    mov    -0x160(%rbp),%rax
    mov    %rax,-0x138(%rbp)
    mov    -0x168(%rbp),%rax
    shr    $0x8,%rax
    mov    %rax,-0x130(%rbp)
    movq   $0x0,-0x148(%rbp)

    mov    -0x148(%rbp),%rax
    cmp    -0x130(%rbp),%rax
    jae    668b <memswap_memcpy(void*, void*, unsigned long)+0x3cb>
    mov    -0x148(%rbp),%rax
    shl    $0x8,%rax
    mov    %rax,-0x128(%rbp)
    mov    -0x140(%rbp),%rdx
    mov    -0x128(%rbp),%rax
    add    %rdx,%rax
    mov    (%rax),%rcx
    mov    0x8(%rax),%rbx
    mov    %rcx,-0x120(%rbp)
    mov    %rbx,-0x118(%rbp)
    mov    0x10(%rax),%rcx
    mov    0x18(%rax),%rbx
    mov    %rcx,-0x110(%rbp)
    mov    %rbx,-0x108(%rbp)
    mov    0x20(%rax),%rcx
    mov    0x28(%rax),%rbx
    mov    %rcx,-0x100(%rbp)
    mov    %rbx,-0xf8(%rbp)
    mov    0x30(%rax),%rcx
    mov    0x38(%rax),%rbx
    mov    %rcx,-0xf0(%rbp)
    mov    %rbx,-0xe8(%rbp)
    mov    0x40(%rax),%rcx
    mov    0x48(%rax),%rbx
    mov    %rcx,-0xe0(%rbp)
    mov    %rbx,-0xd8(%rbp)
    mov    0x50(%rax),%rcx
    mov    0x58(%rax),%rbx
    mov    %rcx,-0xd0(%rbp)
    mov    %rbx,-0xc8(%rbp)
    mov    0x60(%rax),%rcx
    mov    0x68(%rax),%rbx
    mov    %rcx,-0xc0(%rbp)
    mov    %rbx,-0xb8(%rbp)
    mov    0x70(%rax),%rcx
    mov    0x78(%rax),%rbx
    mov    %rcx,-0xb0(%rbp)
    mov    %rbx,-0xa8(%rbp)
    mov    0x80(%rax),%rcx
    mov    0x88(%rax),%rbx
    mov    %rcx,-0xa0(%rbp)
    mov    %rbx,-0x98(%rbp)
    mov    0x90(%rax),%rcx
    mov    0x98(%rax),%rbx
    mov    %rcx,-0x90(%rbp)
    mov    %rbx,-0x88(%rbp)
    mov    0xa0(%rax),%rcx
    mov    0xa8(%rax),%rbx
    mov    %rcx,-0x80(%rbp)
    mov    %rbx,-0x78(%rbp)
    mov    0xb0(%rax),%rcx
    mov    0xb8(%rax),%rbx
    mov    %rcx,-0x70(%rbp)
    mov    %rbx,-0x68(%rbp)
    mov    0xc0(%rax),%rcx
    mov    0xc8(%rax),%rbx
    mov    %rcx,-0x60(%rbp)
    mov    %rbx,-0x58(%rbp)
    mov    0xd0(%rax),%rcx
    mov    0xd8(%rax),%rbx
    mov    %rcx,-0x50(%rbp)
    mov    %rbx,-0x48(%rbp)
    mov    0xe0(%rax),%rcx
    mov    0xe8(%rax),%rbx
    mov    %rcx,-0x40(%rbp)
    mov    %rbx,-0x38(%rbp)
    mov    0xf8(%rax),%rdx
    mov    0xf0(%rax),%rax
    mov    %rax,-0x30(%rbp)
    mov    %rdx,-0x28(%rbp)
    mov    -0x138(%rbp),%rdx
    mov    -0x128(%rbp),%rax
    lea    (%rdx,%rax,1),%rcx
    mov    -0x140(%rbp),%rdx
    mov    -0x128(%rbp),%rax
    add    %rdx,%rax
    mov    $0x100,%edx
    mov    %rcx,%rsi
    mov    %rax,%rdi
    callq  1150 <memcpy@plt>
    mov    -0x138(%rbp),%rdx
    mov    -0x128(%rbp),%rax
    add    %rdx,%rax
    mov    -0x120(%rbp),%rcx
    mov    -0x118(%rbp),%rbx
    mov    %rcx,(%rax)
    mov    %rbx,0x8(%rax)
    mov    -0x110(%rbp),%rcx
    mov    -0x108(%rbp),%rbx
    mov    %rcx,0x10(%rax)
    mov    %rbx,0x18(%rax)
    mov    -0x100(%rbp),%rcx
    mov    -0xf8(%rbp),%rbx
    mov    %rcx,0x20(%rax)
    mov    %rbx,0x28(%rax)
    mov    -0xf0(%rbp),%rcx
    mov    -0xe8(%rbp),%rbx
    mov    %rcx,0x30(%rax)
    mov    %rbx,0x38(%rax)
    mov    -0xe0(%rbp),%rcx
    mov    -0xd8(%rbp),%rbx
    mov    %rcx,0x40(%rax)
    mov    %rbx,0x48(%rax)
    mov    -0xd0(%rbp),%rcx
    mov    -0xc8(%rbp),%rbx
    mov    %rcx,0x50(%rax)
    mov    %rbx,0x58(%rax)
    mov    -0xc0(%rbp),%rcx
    mov    -0xb8(%rbp),%rbx
    mov    %rcx,0x60(%rax)
    mov    %rbx,0x68(%rax)
    mov    -0xb0(%rbp),%rcx
    mov    -0xa8(%rbp),%rbx
    mov    %rcx,0x70(%rax)
    mov    %rbx,0x78(%rax)
    mov    -0xa0(%rbp),%rcx
    mov    -0x98(%rbp),%rbx
    mov    %rcx,0x80(%rax)
    mov    %rbx,0x88(%rax)
    mov    -0x90(%rbp),%rcx
    mov    -0x88(%rbp),%rbx
    mov    %rcx,0x90(%rax)
    mov    %rbx,0x98(%rax)
    mov    -0x80(%rbp),%rcx
    mov    -0x78(%rbp),%rbx
    mov    %rcx,0xa0(%rax)
    mov    %rbx,0xa8(%rax)
    mov    -0x70(%rbp),%rcx
    mov    -0x68(%rbp),%rbx
    mov    %rcx,0xb0(%rax)
    mov    %rbx,0xb8(%rax)
    mov    -0x60(%rbp),%rcx
    mov    -0x58(%rbp),%rbx
    mov    %rcx,0xc0(%rax)
    mov    %rbx,0xc8(%rax)
    mov    -0x50(%rbp),%rcx
    mov    -0x48(%rbp),%rbx
    mov    %rcx,0xd0(%rax)
    mov    %rbx,0xd8(%rax)
    mov    -0x40(%rbp),%rcx
    mov    -0x38(%rbp),%rbx
    mov    %rcx,0xe0(%rax)
    mov    %rbx,0xe8(%rax)
    mov    -0x30(%rbp),%rcx
    mov    -0x28(%rbp),%rbx
    mov    %rcx,0xf0(%rax)
    mov    %rbx,0xf8(%rax)
    addq   $0x1,-0x148(%rbp)

    jmpq   632d <memswap_memcpy(void*, void*, unsigned long)+0x6d>
    mov    -0x168(%rbp),%rax
    movzbl %al,%edx
    mov    -0x130(%rbp),%rax
    shl    $0x8,%rax
    mov    %rax,%rcx
    mov    -0x140(%rbp),%rax
    add    %rax,%rcx
    lea    -0x120(%rbp),%rax
    mov    %rcx,%rsi
    mov    %rax,%rdi
    callq  1150 <memcpy@plt>
    mov    -0x168(%rbp),%rax
    movzbl %al,%eax
    mov    -0x130(%rbp),%rdx
    shl    $0x8,%rdx
    mov    %rdx,%rcx
    mov    -0x138(%rbp),%rdx
    lea    (%rcx,%rdx,1),%rsi
    mov    -0x130(%rbp),%rdx
    shl    $0x8,%rdx
    mov    %rdx,%rcx
    mov    -0x140(%rbp),%rdx
    add    %rdx,%rcx
    mov    %rax,%rdx
    mov    %rcx,%rdi
    callq  1150 <memcpy@plt>
    mov    -0x168(%rbp),%rax
    movzbl %al,%edx
    mov    -0x130(%rbp),%rax
    shl    $0x8,%rax
    mov    %rax,%rcx
    mov    -0x138(%rbp),%rax
    add    %rax,%rcx
    lea    -0x120(%rbp),%rax
    mov    %rax,%rsi
    mov    %rcx,%rdi
    callq  1150 <memcpy@plt>
    nop
    mov    -0x18(%rbp),%rax
    xor    %fs:0x28,%rax

    je     674e <memswap_memcpy(void*, void*, unsigned long)+0x48e>
    callq  11e0 <__stack_chk_fail@plt>
    add    $0x168,%rsp
    pop    %rbx
    pop    %rbp
    retq
```

### `memswap_avx_unroll()`, `-O0`, `clang`

```asm
<memswap_avx_unroll(void*, void*, unsigned long)>:
    push   %rbp
    mov    %rsp,%rbp
    and    $0xffffffffffffffe0,%rsp
    sub    $0x520,%rsp
    mov    %rdi,0x1e8(%rsp)
    mov    %rsi,0x1e0(%rsp)
    mov    %rdx,0x1d8(%rsp)
    mov    0x1d8(%rsp),%rax
    shr    $0x5,%rax
    mov    %rax,0x1d0(%rsp)
    movq   $0x0,0x1c8(%rsp)
    mov    0x1c8(%rsp),%rax
    mov    0x1d0(%rsp),%rcx
    shr    $0x2,%rcx
    cmp    %rcx,%rax
    jae    407329 <memswap_avx_unroll(void*, void*, unsigned long)+0x6b9>
    mov    0x1e8(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x0,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x1c0(%rsp)
    mov    0x1e8(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x1,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x1b8(%rsp)
    mov    0x1e8(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x2,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x1b0(%rsp)
    mov    0x1e8(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x3,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x1a8(%rsp)
    mov    0x1e0(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x0,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x1a0(%rsp)
    mov    0x1e0(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x1,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x198(%rsp)
    mov    0x1e0(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x2,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x190(%rsp)
    mov    0x1e0(%rsp),%rax
    mov    0x1c8(%rsp),%rcx
    add    $0x3,%rcx
    shl    $0x3,%rcx
    shl    $0x2,%rcx
    add    %rcx,%rax
    mov    %rax,0x188(%rsp)
    mov    0x1c0(%rsp),%rax
    mov    %rax,0x1f0(%rsp)
    mov    0x1f0(%rsp),%rax
    vmovups (%rax),%ymm0
    vmovaps %ymm0,0x160(%rsp)
    mov    0x1b8(%rsp),%rax
    mov    %rax,0x1f8(%rsp)
    mov    0x1f8(%rsp),%rax
    vmovups (%rax),%ymm0
    vmovaps %ymm0,0x140(%rsp)
    mov    0x1b0(%rsp),%rax
    mov    %rax,0x508(%rsp)
    mov    0x508(%rsp),%rax
    vmovups (%rax),%ymm0
    vmovaps %ymm0,0x120(%rsp)
    mov    0x1a8(%rsp),%rax
    mov    %rax,0x500(%rsp)
    mov    0x500(%rsp),%rax
    vmovups (%rax),%ymm0
    vmovaps %ymm0,0x100(%rsp)
    mov    0x1c0(%rsp),%rax
    mov    0x1a0(%rsp),%rcx
    mov    %rcx,0x4f8(%rsp)
    mov    0x4f8(%rsp),%rcx
    vmovups (%rcx),%ymm0
    vmovaps %ymm0,0xe0(%rsp)
    mov    0xe0(%rsp),%rcx
    mov    %rcx,0x4a0(%rsp)
    mov    0xe8(%rsp),%rcx
    mov    %rcx,0x4a8(%rsp)
    mov    0xf0(%rsp),%rcx
    mov    %rcx,0x4b0(%rsp)
    mov    0xf8(%rsp),%rcx
    mov    %rcx,0x4b8(%rsp)
    vmovaps 0x4a0(%rsp),%ymm0
    mov    %rax,0x4f0(%rsp)
    vmovaps %ymm0,0x4c0(%rsp)
    vmovaps 0x4c0(%rsp),%ymm0
    mov    0x4f0(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x1b8(%rsp),%rax
    mov    0x198(%rsp),%rcx
    mov    %rcx,0x498(%rsp)
    mov    0x498(%rsp),%rcx
    vmovups (%rcx),%ymm0
    vmovaps %ymm0,0xc0(%rsp)
    mov    0xc0(%rsp),%rcx
    mov    %rcx,0x440(%rsp)
    mov    0xc8(%rsp),%rcx
    mov    %rcx,0x448(%rsp)
    mov    0xd0(%rsp),%rcx
    mov    %rcx,0x450(%rsp)
    mov    0xd8(%rsp),%rcx
    mov    %rcx,0x458(%rsp)
    vmovaps 0x440(%rsp),%ymm0
    mov    %rax,0x490(%rsp)
    vmovaps %ymm0,0x460(%rsp)
    vmovaps 0x460(%rsp),%ymm0
    mov    0x490(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x1b0(%rsp),%rax
    mov    0x190(%rsp),%rcx
    mov    %rcx,0x438(%rsp)
    mov    0x438(%rsp),%rcx
    vmovups (%rcx),%ymm0
    vmovaps %ymm0,0xa0(%rsp)
    mov    0xa0(%rsp),%rcx
    mov    %rcx,0x3e0(%rsp)
    mov    0xa8(%rsp),%rcx
    mov    %rcx,0x3e8(%rsp)
    mov    0xb0(%rsp),%rcx
    mov    %rcx,0x3f0(%rsp)
    mov    0xb8(%rsp),%rcx
    mov    %rcx,0x3f8(%rsp)
    vmovaps 0x3e0(%rsp),%ymm0
    mov    %rax,0x430(%rsp)
    vmovaps %ymm0,0x400(%rsp)
    vmovaps 0x400(%rsp),%ymm0
    mov    0x430(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x1a8(%rsp),%rax
    mov    0x188(%rsp),%rcx
    mov    %rcx,0x3d8(%rsp)
    mov    0x3d8(%rsp),%rcx
    vmovups (%rcx),%ymm0
    vmovaps %ymm0,0x80(%rsp)
    mov    0x80(%rsp),%rcx
    mov    %rcx,0x380(%rsp)
    mov    0x88(%rsp),%rcx
    mov    %rcx,0x388(%rsp)
    mov    0x90(%rsp),%rcx
    mov    %rcx,0x390(%rsp)
    mov    0x98(%rsp),%rcx
    mov    %rcx,0x398(%rsp)
    vmovaps 0x380(%rsp),%ymm0
    mov    %rax,0x3d0(%rsp)
    vmovaps %ymm0,0x3a0(%rsp)
    vmovaps 0x3a0(%rsp),%ymm0
    mov    0x3d0(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x1a0(%rsp),%rax
    vmovaps 0x160(%rsp),%ymm0
    vmovaps %ymm0,0x60(%rsp)
    mov    0x60(%rsp),%rcx
    mov    %rcx,0x320(%rsp)
    mov    0x68(%rsp),%rcx
    mov    %rcx,0x328(%rsp)
    mov    0x70(%rsp),%rcx
    mov    %rcx,0x330(%rsp)
    mov    0x78(%rsp),%rcx
    mov    %rcx,0x338(%rsp)
    vmovaps 0x320(%rsp),%ymm0
    mov    %rax,0x378(%rsp)
    vmovaps %ymm0,0x340(%rsp)
    vmovaps 0x340(%rsp),%ymm0
    mov    0x378(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x198(%rsp),%rax
    vmovaps 0x140(%rsp),%ymm0
    vmovaps %ymm0,0x40(%rsp)
    mov    0x40(%rsp),%rcx
    mov    %rcx,0x2c0(%rsp)
    mov    0x48(%rsp),%rcx
    mov    %rcx,0x2c8(%rsp)
    mov    0x50(%rsp),%rcx
    mov    %rcx,0x2d0(%rsp)
    mov    0x58(%rsp),%rcx
    mov    %rcx,0x2d8(%rsp)
    vmovaps 0x2c0(%rsp),%ymm0
    mov    %rax,0x318(%rsp)
    vmovaps %ymm0,0x2e0(%rsp)
    vmovaps 0x2e0(%rsp),%ymm0
    mov    0x318(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x190(%rsp),%rax
    vmovaps 0x120(%rsp),%ymm0
    vmovaps %ymm0,0x20(%rsp)
    mov    0x20(%rsp),%rcx
    mov    %rcx,0x260(%rsp)
    mov    0x28(%rsp),%rcx
    mov    %rcx,0x268(%rsp)
    mov    0x30(%rsp),%rcx
    mov    %rcx,0x270(%rsp)
    mov    0x38(%rsp),%rcx
    mov    %rcx,0x278(%rsp)
    vmovaps 0x260(%rsp),%ymm0
    mov    %rax,0x2b8(%rsp)
    vmovaps %ymm0,0x280(%rsp)
    vmovaps 0x280(%rsp),%ymm0
    mov    0x2b8(%rsp),%rax
    vmovups %ymm0,(%rax)
    mov    0x188(%rsp),%rax
    vmovaps 0x100(%rsp),%ymm0
    vmovaps %ymm0,(%rsp)
    mov    (%rsp),%rcx
    mov    %rcx,0x200(%rsp)
    mov    0x8(%rsp),%rcx
    mov    %rcx,0x208(%rsp)
    mov    0x10(%rsp),%rcx
    mov    %rcx,0x210(%rsp)
    mov    0x18(%rsp),%rcx
    mov    %rcx,0x218(%rsp)
    vmovaps 0x200(%rsp),%ymm0
    mov    %rax,0x258(%rsp)
    vmovaps %ymm0,0x220(%rsp)
  	vmovaps 0x220(%rsp),%ymm0
  	mov    0x258(%rsp),%rax
  	vmovups %ymm0,(%rax)
  	mov    0x1c8(%rsp),%rax
  	add    $0x1,%rax
  	mov    %rax,0x1c8(%rsp)
  	jmpq   406cb7 <memswap_avx_unroll(void*, void*, unsigned long)+0x47>
  	mov    0x1e8(%rsp),%rax
  	mov    0x1d0(%rsp),%rcx
  	shl    $0x3,%rcx
  	shl    $0x2,%rcx
  	add    %rcx,%rax
  	mov    0x1e0(%rsp),%rcx
  	mov    0x1d0(%rsp),%rdx
  	shl    $0x3,%rdx
  	shl    $0x2,%rdx
  	add    %rdx,%rcx
  	mov    0x1d8(%rsp),%rdx
  	mov    0x1d0(%rsp),%rsi
  	shl    $0x5,%rsi
  	sub    %rsi,%rdx
  	mov    %rax,%rdi
  	mov    %rcx,%rsi
  	vzeroupper 
  	callq  406a20 <memswap_avx(void*, void*, unsigned long)>
  	mov    %rbp,%rsp
  	pop    %rbp
  	retq
```

### `memswap_avx_unroll()`, `-O0`, `gcc`

```asm
<memswap_avx_unroll(void*, void*, unsigned long)>:
    endbr64 
    push   %rbp
    mov    %rsp,%rbp
    and    $0xffffffffffffffe0,%rsp
    sub    $0x280,%rsp
    mov    %rdi,0x28(%rsp)
    mov    %rsi,0x20(%rsp)
    mov    %rdx,0x18(%rsp)
    mov    0x18(%rsp),%rax
    shr    $0x5,%rax
    mov    %rax,0x38(%rsp)
    movq   $0x0,0x30(%rsp)
    mov    0x38(%rsp),%rax
    shr    $0x2,%rax
    cmp    %rax,0x30(%rsp)
    jae    73eb <memswap_avx_unroll(void*, void*, unsigned long)+0x418>
    mov    0x30(%rsp),%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x28(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x40(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x1,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x28(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x48(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x2,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x28(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x50(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x3,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x28(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x58(%rsp)
    mov    0x30(%rsp),%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x20(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x60(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x1,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x20(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x68(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x2,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x20(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x70(%rsp)
    mov    0x30(%rsp),%rax
    add    $0x3,%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x20(%rsp),%rax
    add    %rdx,%rax
    mov    %rax,0x78(%rsp)
    mov    0x40(%rsp),%rax
    mov    %rax,0xf8(%rsp)
    mov    0xf8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    vmovaps %ymm0,0x100(%rsp)
    mov    0x48(%rsp),%rax
    mov    %rax,0xf0(%rsp)
    mov    0xf0(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    vmovaps %ymm0,0x120(%rsp)
    mov    0x50(%rsp),%rax
    mov    %rax,0xe8(%rsp)
    mov    0xe8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    vmovaps %ymm0,0x140(%rsp)
    mov    0x58(%rsp),%rax
    mov    %rax,0xe0(%rsp)
    mov    0xe0(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    vmovaps %ymm0,0x160(%rsp)
    mov    0x60(%rsp),%rax
    mov    %rax,0xd8(%rsp)
    mov    0xd8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    mov    0x40(%rsp),%rax
    mov    %rax,0xd0(%rsp)
    vmovaps %ymm0,0x260(%rsp)
    vmovaps 0x260(%rsp),%ymm0
    mov    0xd0(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x68(%rsp),%rax
    mov    %rax,0xc8(%rsp)
    mov    0xc8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    mov    0x48(%rsp),%rax
    mov    %rax,0xc0(%rsp)
    vmovaps %ymm0,0x240(%rsp)
    vmovaps 0x240(%rsp),%ymm0
    mov    0xc0(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x70(%rsp),%rax
    mov    %rax,0xb8(%rsp)
    mov    0xb8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    mov    0x50(%rsp),%rax
    mov    %rax,0xb0(%rsp)
    vmovaps %ymm0,0x220(%rsp)
    vmovaps 0x220(%rsp),%ymm0
    mov    0xb0(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x78(%rsp),%rax
    mov    %rax,0xa8(%rsp)
    mov    0xa8(%rsp),%rax
    vmovups (%rax),%xmm0
    vinsertf128 $0x1,0x10(%rax),%ymm0,%ymm0
    mov    0x58(%rsp),%rax
    mov    %rax,0xa0(%rsp)
    vmovaps %ymm0,0x200(%rsp)
    vmovaps 0x200(%rsp),%ymm0
    mov    0xa0(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x60(%rsp),%rax
    mov    %rax,0x98(%rsp)
    vmovaps 0x100(%rsp),%ymm0
    vmovaps %ymm0,0x1e0(%rsp)
    vmovaps 0x1e0(%rsp),%ymm0
    mov    0x98(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x68(%rsp),%rax
    mov    %rax,0x90(%rsp)
    vmovaps 0x120(%rsp),%ymm0
    vmovaps %ymm0,0x1c0(%rsp)
    vmovaps 0x1c0(%rsp),%ymm0
    mov    0x90(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x70(%rsp),%rax
    mov    %rax,0x88(%rsp)
    vmovaps 0x140(%rsp),%ymm0
    vmovaps %ymm0,0x1a0(%rsp)
    vmovaps 0x1a0(%rsp),%ymm0
    mov    0x88(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    mov    0x78(%rsp),%rax
    mov    %rax,0x80(%rsp)
    vmovaps 0x160(%rsp),%ymm0
    vmovaps %ymm0,0x180(%rsp)
    vmovaps 0x180(%rsp),%ymm0
    mov    0x80(%rsp),%rax
    vmovups %xmm0,(%rax)
    vextractf128 $0x1,%ymm0,0x10(%rax)
    nop
    addq   $0x1,0x30(%rsp)
    jmpq   700c <memswap_avx_unroll(void*, void*, unsigned long)+0x39>
    mov    0x38(%rsp),%rax
    shl    $0x5,%rax
    mov    %rax,%rdx
    mov    0x18(%rsp),%rax
    sub    %rdx,%rax
    mov    %rax,%rdx
    mov    0x38(%rsp),%rax
    shl    $0x5,%rax
    mov    %rax,%rcx
    mov    0x20(%rsp),%rax
    add    %rax,%rcx
    mov    0x38(%rsp),%rax
    shl    $0x5,%rax
    mov    %rax,%rsi
    mov    0x28(%rsp),%rax
    add    %rsi,%rax
    mov    %rcx,%rsi
    mov    %rax,%rdi
    callq  6e58 <memswap_avx(void*, void*, unsigned long)>
    nop
    leaveq 
    retq
```
