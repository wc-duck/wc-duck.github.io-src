---
title: 'good title!!!'
date: 2022-02-13
tags: ['code', 'c++', 'optimization']
draft: true
toc: true
---

During my vacation for the holidays I thought that maybe I wanted some smaller project that you could fit in together with "family life" (not the easiest of endevours!) and I got to think about some old code that I had laying about in my own little game-engine that I have thought about making public before.
I thought it might be useful for someone else and maybe just doing some optimization work on it might be a fun little distraction!

That code was a small header called memcpy_util.h containing functions to work on memory buffers, operations such as copy, swap, rotate, flip etc.

Said and done, I did set out to work with breaking it out, updating docs, fixing some apis, adding a few more unittests and putting some benchmarks around the code as prep for having a go at optimizing the functions at hand.

Kudos to Scott Vokes for [greatest.h](https://github.com/silentbicycle/greatest) and Neil Henning for the exelent little [ubench.h](https://github.com/sheredom/ubench.h)!.

When the code will see the light of day outside my own code is still to be decided, but some quite interesting things popped out while benchmarking the code. I would say that most of this is not rocket-surgery and many of you migth not find something new in here. But what the heck, the worst thing that can happen is that someone comes around and tell me that I have done some obvious errors and I'll learn something, otherwise maybe someone else might learn a thing or two?

It should also be noted that what started as a single article might actually turn out to be a series, we'll see what happens :)

> Before we start I would like to acknowledge that I understand that writing compilers is hard and that there are a bazillion things to consider when doing so. This is only observations and not me bashing "them pesky compiler-developers"!

## Prerequisites

All this work has been done on my laptop with the following specs:

TODO: machine spec

And I'll use the compilers that I have installed, that being

> **Clang:**
>
> clang version 10.0.0-4ubuntu1 
>
> Target: x86_64-pc-linux-gnu

> **GCC:**
>
> g++ (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0

## Swapping memory buffers

So we'll start where I started, by swapping memory in 2 buffers, something that is the basis of many of the other operations in memcpy_util.h, such as flipping an image.
What I thought would be a quick introduction turned out to be the entire article, so lets get to swapping memory between 2 buffers!

The first thing to notice is that `c` do not have a `memswap()`. c++ do have `std::swap_ranges()` but we'll get back to that later!

However, just implementing your own `memswap()` is a simple operation as long as you do not want to get fancy. I would consider this the simplest thing you could do!

```c++
inline void memswap( void* ptr1, void* ptr2, size_t bytes )
{
	uint8_t* s1 = (uint8_t*)ptr1;
	uint8_t* s2 = (uint8_t*)ptr2;
	for( size_t i = 0; i < bytes; ++i )
	{
		uint8_t tmp = s1[i];
		s1[i] = s2[i];
		s2[i] = tmp;
	}
}
```

But how does such a simple function perform? It turns out "it depends" is the best answer to that question!

To answer the question we'll add 2 benchmark functions, one to swap a really small buffer and one to swap a quite large one (4MB).

```c++
UBENCH_NOINLINE void memswap_noinline(void* ptr1, void* ptr2, size_t s)
{
    memswap(ptr1, ptr2, s);
}

UBENCH_EX(swap, small)
{
	uint8_t b1[16];
    uint8_t b2[16];
    fill_with_random_data(b1);
    fill_with_random_data(b2);

	UBENCH_DO_BENCHMARK()
	{
		memswap_noinline(b1, b2, sizeof(b1));
	}
}

UBENCH_EX(swap, big)
{
    const size_t BUF_SZ = 4 * 1024 * 1024;
	uint8_t* b1 = alloc_random_buffer<uint8_t>(BUF_SZ);
    uint8_t* b2 = alloc_random_buffer<uint8_t>(BUF_SZ);

	UBENCH_DO_BENCHMARK()
	{
		memswap_noinline(b1, b2, BUF_SZ);
	}

    free(b1);
    free(b2);
}
```

Notice how memswap() was wrapped in a function marked as noinline, this as clang would just optimize the function away.

Time to take a look at the results, we'll look at perf at different optimization level (perf in debug/-O0 is also important!) as well as generated code-size.

> the variance on these are quite high, so these numbers is me 'getting feeling' and guessing at a  mean :)

![memswap_generic,time]({static}/images/memswap/memswap_generic_time.png "memswap_generic, time for 4MB")
![memswap_generic,size]({static}/images/memswap/memswap_generic_size.png "memswap_generic, codesize")

> At the time of writing I do not have access to a windows-machine for me to test out msvc on but I will add a few observations on generated code fetched via [compiler explorer](https://godbolt.org/) but no numbers.

> **dumping function size**
>
> For most readers this is nothing new, but dumping symbol/function-sizes is easily done on most unix:es with the use of 'nm'.
>
> `nm --print-size -C local/linux_x86_64/clang/O2/memcpy_util_bench | grep memswap`

Lets start with -O0 and just conclude that both clang and gcc generates, basically the same code, as would be expected. There is nothing magic here (and nor should there be!) and the code performs there after.

At -O2 we will see that clang finds that it can use the vector-registers to copy the data and gives us a huge speadup at the cost of roughly 2.5x the codesize.

If we look at the generated assembly we can see that the meat-and-potatoes of this function just falls down to copying the data with SSE vector-registers + a preamble that handles all bytes that are not an even multiple of 16, i.e. can't be handled by the vector registers.

> **looking at the generated assembly**
>
> Again most readers might be familiar with this but checking the generated asm on unix:es is easily done with 'objdump'
>
> `objdump -C -d local/linux_x86_64/gcc/O2/memcpy_util_bench | less`
>
> or using the excelent little tool [bat](https://github.com/sharkdp/bat) to get some nice syntax-highlighting
>
> `objdump -C -d local/linux_x86_64/gcc/O2/memcpy_util_bench | bat -l asm`

This code is fast! And if I were to guess there is some heuristic in clang that detects the pattern of swapping memory buffers and have a fastpath for it and that we are not seeing any "clever" auto-vectorization (said by "not an expert (tm)").

We can also observe that clang generates identical code with -O3, this is something that will show up consistently throught out this article.

Now lets look at gcc as that is way more interresting. First of we see that gcc generates really small code with -02, just 42 bytes. Code that is way slower than clang (but still a great improvement over the non optimized code). It has just generated a really simple loop and removed some general debug-overhead.

In -O3 however... now we reach the same perf as clang in -02, but with double the codesize, what is going on here?
Well, loop-unrolling :)

> using [compiler explorer](https://godbolt.org/) we can see that msvc is generating similar code as `gcc` for `/O2` and also quite similar code for `/O3`, i.e. loop-unrolling!

// TODO: some note on -Os


## memcpy() in chunks

So what can we do to generate better code on gcc in `-O2`? How about we try to just change the copy to use `memcpy()` instead? I.e. using `memcpy()` in chunks of, lets say 256 bytes?

Something like:

```c++
inline void memswap_memcpy( void* ptr1, void* ptr2, size_t bytes )
{
	uint8_t* s1 = (uint8_t*)ptr1;
	uint8_t* s2 = (uint8_t*)ptr2;

	char tmp[256];
	size_t chunks = bytes / sizeof(tmp);
	for(size_t i = 0; i < chunks; ++i)
	{
		size_t offset = i * sizeof(tmp);
		memcpy(tmp,         s1 + offset, sizeof(tmp));
		memcpy(s1 + offset, s2 + offset, sizeof(tmp));
		memcpy(s2 + offset, tmp,         sizeof(tmp));
	}

	memcpy(tmp,                       s1 + chunks * sizeof(tmp), bytes % sizeof(tmp) );
	memcpy(s1 + chunks * sizeof(tmp), s2 + chunks * sizeof(tmp), bytes % sizeof(tmp) );
	memcpy(s2 + chunks * sizeof(tmp), tmp,                       bytes % sizeof(tmp) );
}
```

![memswap_memcpy,time]({static}/images/memswap/memswap_generic_memcpy_time.png "memswap_memcpy, time for 4MB")
![memswap_memcpy,size]({static}/images/memswap/memswap_generic_memcpy_size.png "memswap_memcpy, codesize")

![memswap_memcpy,time]({static}/images/memswap/memswap_memcpy_time.png "memswap_memcpy, time for 4MB")
![memswap_memcpy,size]({static}/images/memswap/memswap_memcpy_size.png "memswap_memcpy, codesize")

Now this is better! Both for clang ang gcc we are outperforming the 'generic' implementation by a huge margin in debug, and we see that clang is close to the same perf as -O2/-O3 in debug!
One interresting observation here is that the code clang generate for -Os is quite a bit faster than the other configs!

// TODO: why is Os in clang faster here?

So, there are a few things to dig into here.

// TODO: numbers as byte-per-sec!

### what is it that gcc miss that clang don't?

As we can see, clang is generating faster code in all configs, and usually smaller as well. The only exception when it comes to size is -Os where gcc generate really small code.
But what make the clang-generated code faster? Let's start with a look at -O0 as that is where the differance is greatest. If we look at the disassembly we can see that gcc has inlined its call to `memcpy()` and replaced it with a whole bunch of unrolled 'mov' instructions while clang has decided to still generate calls to `memcpy()`.

Unfortunatly for gcc this inlined code is a lot slower than the std-lib `memcpy()` implementation. I don't know what heuristics went into this but I'll ascribe it to "it is hard to write a compiler and what is best for x is not necessarily best for y".

One interresting thing we can try is to gcc to call `memcpy()` by calling it via a pointer and by that not inline it. Something like this?

```c++
inline void memswap_memcpy( void* ptr1, void* ptr2, size_t bytes )
{
	void* (*memcpy_ptr)(void*, const void*, size_t s) = memcpy;

	uint8_t* s1 = (uint8_t*)ptr1;
	uint8_t* s2 = (uint8_t*)ptr2;

	char tmp[256];
	size_t chunks = bytes / sizeof(tmp);
	for(size_t i = 0; i < chunks; ++i)
	{
		size_t offset = i * sizeof(tmp);
		memcpy_ptr(tmp,         s1 + offset, sizeof(tmp));
		memcpy_ptr(s1 + offset, s2 + offset, sizeof(tmp));
		memcpy_ptr(s2 + offset, tmp,         sizeof(tmp));
	}

	memcpy_ptr(tmp,                       s1 + chunks * sizeof(tmp), bytes % sizeof(tmp) );
	memcpy_ptr(s1 + chunks * sizeof(tmp), s2 + chunks * sizeof(tmp), bytes % sizeof(tmp) );
	memcpy_ptr(s2 + chunks * sizeof(tmp), tmp,                       bytes % sizeof(tmp) );
}
```

First observation, clang generate the same code for all configs except `-O0`.

Secondly we see WAY better perf on gcc and slightly better on clang in `-O0`. Calling into an optimized `memcpy()` instead of a bunch of unrolled `mov` instructions seem like a smart thing to do :)

Next up we can take a look at `-O2/-O3`, here we sees that clang still decide to just call `memcpy()` and be done with it while gcc tries to be smart and add an inlined vectorized implementation using the SSE-registers (this is the same vectorization that it uses when just using pure `memcpy()`).
Unfortunatly for GCC it's generated memcpy-replacement is both slower and bulkier than just calling `memcpy()` directly resulting in both slower and bigger code :(

// TODO: what would it generate if it wasn't in a noinline function and give the compiler the oportunity to see the buffer-size?


### codesizes?

whoppa?

// observations, yet again clang faster (inspect asm to tell why)
// gcc is generating big code, why? (inlining of memcpy?)


## memcpy(), to inline or not to inline, thats the question?

calling memcpy or inlining? seems to depend on if the compiler can assume alignment of type that is copied, clang will fall back to calling memcpy() and gcc to a really inefficient loop where the call to memcpy is faster.


## Manual vectorization with SSE

Next up... we found on the generic implementations that clangs vectorization performed quite well. So lets try and do that ourself!

```c++
inline void memswap_sse2( void* ptr1, void* ptr2, size_t bytes )
{
	size_t chunks = bytes / sizeof(__m128);

	// swap as much as possible with the sse-registers ...
	for(size_t i = 0; i < chunks; ++i)
	{
		float* src1 = (float*)ptr1 + i * (sizeof(__m128) / sizeof(float));
		float* src2 = (float*)ptr2 + i * (sizeof(__m128) / sizeof(float));

		__m128 tmp =_mm_loadu_ps(src1);
		_mm_storeu_ps(src1, _mm_loadu_ps(src2));
		_mm_storeu_ps(src2, tmp);
	}

	// ... and swap the remaining bytes with the generic swap ...
	uint8_t* s1 = (uint8_t*)ptr1 + chunks * sizeof(__m128);
	uint8_t* s2 = (uint8_t*)ptr2 + chunks * sizeof(__m128);
	memswap_generic(s1, s2, bytes % sizeof(__m128));
}
```

// TODO: graphs!

Now we'r talking. By sacrificing support on all platforms and only focusing on x86 we can get both compilers to generate code that can compete with the calls to `memcpy()` in all but the `-O0` builds. IHMO that is not surprising as we are comparing an optimized `memcpy()` against unoptimized code, however 1.5ms compared to the generic implementations 9.6ms is nothing to scoff at!

> Im wondering if it is worth calling the memcpy() version in debug-builds and the sse version in the other builds but I'm not really sure as it is kind of "lying"!

Another observation is that the `-Os` build beats both `-O2` and `-O3`. But how is that? Lets dig in!

// TODO: yes, do it!


## Manual vectorization with AVX

So if going wide with SSE registers, will it perform better if we go wider with AVX? Lets try it out!

```c++
inline void memswap_avx( void* ptr1, void* ptr2, size_t bytes )
{
	size_t chunks = bytes / sizeof(__m256);

	// swap as much as possible with the avx-registers ...
	for(size_t i = 0; i < chunks; ++i)
	{
		float* src1 = (float*)ptr1 + i * (sizeof(__m256) / sizeof(float));
		float* src2 = (float*)ptr2 + i * (sizeof(__m256) / sizeof(float));
		__m256 tmp  = _mm256_loadu_ps(src1);
		_mm256_storeu_ps(src1, _mm256_loadu_ps(src2));
		_mm256_storeu_ps(src2, tmp);
	}

	// ... and swap the remaining bytes with the generic swap ...
	uint8_t* s1 = (uint8_t*)ptr1 + chunks * sizeof(__m256);
	uint8_t* s2 = (uint8_t*)ptr2 + chunks * sizeof(__m256);
	memswap_generic(s1, s2, bytes % sizeof(__m256));
}
```

// TODO: graphs! sse vs avx?

// reflections go here
// gcc -O0 is about double the perf ov clang!
// clang generate slower code in -O0 for avx vs sse!
// otherwise, clang generally faster (but not with a big margin)


## Unrolling!

faster!

Another thing we found when looking at clangs generated SSE-code was that it was unrolled to do 4 swaps each iteraton of the loop. Will that bring us better perf in our sse and avx implementations? lets try!

// TODO: code!

// TODO: graphs!

// reflections go here


## We have only tested on 4MB, how do we fare on smaller and bigger buffers?

// TODO: test perf on multiple sizes and graph time vs size


## How about std::swap_ranges() and std::swap()?

Now I guess some of you ask yourself, why doesn't he just use what is given to him by the c++ standrad library? It is after all "standard" and available to all by default!
So let's add some benchmarks and just test it out! According to all info I can find `std::swap_ranges` is the way to go.

And we add the benchmark, run them and... OH MY GOD!

// TODO: graph!

On my machine, with -Os, it runs about **x slower on clang and **x slower on gcc than the generic version we started of with! And compared to the fastest ones that we have implemented ourself its almost **x slower in debug! Even if we don't "cheat" and call into an optimized memcpy we can quite easily device a version that run around **x faster!

Even the optimized builds only reach the same perf as we do with the standard 'generic' implementation we had to begin with!

So lets dig into why the performance is so terrible in debug for `std::swap_ranges`... should we maybe blame the "lazy compiler devs"? Nah, not really, the compiler is really just doing what it was told to do, and it was told to generate a lot of function-calls.

Lets take a trip to godbolt and have a look at what assembly is actually generated for this.

https://godbolt.org/z/Mf7rPrjc1

```asm
    swap_it():
        push    rbp
        mov     rbp, rsp
        mov     eax, OFFSET FLAT:b1+4096
        mov     edx, OFFSET FLAT:b2
        mov     rsi, rax
        mov     edi, OFFSET FLAT:b1
        call    unsigned char* std::swap_ranges<unsigned char*, unsigned char*>(unsigned char*, unsigned char*, unsigned char*)
        nop
        pop     rbp
        ret
```

Only 15 lines of assembly... nothing really interresting here, we'll have to dig deaper. Time to tell godbolt to show "library functions"

```asm
unsigned char* std::swap_ranges<unsigned char*, unsigned char*>(unsigned char*, unsigned char*, unsigned char*):
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32
        mov     QWORD PTR [rbp-8], rdi
        mov     QWORD PTR [rbp-16], rsi
        mov     QWORD PTR [rbp-24], rdx
.L3:
        mov     rax, QWORD PTR [rbp-8]
        cmp     rax, QWORD PTR [rbp-16]
        je      .L2
        mov     rdx, QWORD PTR [rbp-24]
        mov     rax, QWORD PTR [rbp-8]
        mov     rsi, rdx
        mov     rdi, rax
        call    void std::iter_swap<unsigned char*, unsigned char*>(unsigned char*, unsigned char*)
        add     QWORD PTR [rbp-8], 1
        add     QWORD PTR [rbp-24], 1
        jmp     .L3
.L2:
        mov     rax, QWORD PTR [rbp-24]
        leave
        ret
swap_it():
        push    rbp
        mov     rbp, rsp
        mov     eax, OFFSET FLAT:b1+4096
        mov     edx, OFFSET FLAT:b2
        mov     rsi, rax
        mov     edi, OFFSET FLAT:b1
        call    unsigned char* std::swap_ranges<unsigned char*, unsigned char*>(unsigned char*, unsigned char*, unsigned char*)
        nop
        pop     rbp
        ret
void std::iter_swap<unsigned char*, unsigned char*>(unsigned char*, unsigned char*):
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     QWORD PTR [rbp-8], rdi
        mov     QWORD PTR [rbp-16], rsi
        mov     rdx, QWORD PTR [rbp-16]
        mov     rax, QWORD PTR [rbp-8]
        mov     rsi, rdx
        mov     rdi, rax
        call    std::enable_if<std::__and_<std::__not_<std::__is_tuple_like<unsigned char> >, std::is_move_constructible<unsigned char>, std::is_move_assignable<unsigned char> >::value, void>::type std::swap<unsigned char>(unsigned char&, unsigned char&)
        nop
        leave
        ret
std::enable_if<std::__and_<std::__not_<std::__is_tuple_like<unsigned char> >, std::is_move_constructible<unsigned char>, std::is_move_assignable<unsigned char> >::value, void>::type std::swap<unsigned char>(unsigned char&, unsigned char&):
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32
        mov     QWORD PTR [rbp-24], rdi
        mov     QWORD PTR [rbp-32], rsi
        mov     rax, QWORD PTR [rbp-24]
        mov     rdi, rax
        call    std::remove_reference<unsigned char&>::type&& std::move<unsigned char&>(unsigned char&)
        movzx   eax, BYTE PTR [rax]
        mov     BYTE PTR [rbp-1], al
        mov     rax, QWORD PTR [rbp-32]
        mov     rdi, rax
        call    std::remove_reference<unsigned char&>::type&& std::move<unsigned char&>(unsigned char&)
        movzx   edx, BYTE PTR [rax]
        mov     rax, QWORD PTR [rbp-24]
        mov     BYTE PTR [rax], dl
        lea     rax, [rbp-1]
        mov     rdi, rax
        call    std::remove_reference<unsigned char&>::type&& std::move<unsigned char&>(unsigned char&)
        movzx   edx, BYTE PTR [rax]
        mov     rax, QWORD PTR [rbp-32]
        mov     BYTE PTR [rax], dl
        nop
        leave
        ret
std::remove_reference<unsigned char&>::type&& std::move<unsigned char&>(unsigned char&):
        push    rbp
        mov     rbp, rsp
        mov     QWORD PTR [rbp-8], rdi
        mov     rax, QWORD PTR [rbp-8]
        pop     rbp
        ret
```

Ouch... we have call instructions generated for `std::remove_reference`, `std::enable_if` and `std::iter_swap`... and there is nothing wrong with that from a compiler standpoint, you told it that you had functions that needed to be called so the compiler will generate a functions call!
FYI the same code is generated for std::swap on an std::array and similar constructs as well.


## Summary

// TODO: diff between gcc/clang somewhere else?

// TODO: is it worth writing your own memcpy!?! and what do you call that?
//       that might be scary! But might be worth it in specific cases! And how come it isn't faster? If I, as a clutz could do it? What am I missing, and I guess it is something!

// quick notes on vectorization pragmas... did not work at all!

// TODO: write about comparison with memcpy, same speed, bound by RAM-speed in all tests, how do I write a test that is in cache only?!

// in the end, on bigger buffers, blocked by memory-speed

// TODO: note gcc and clang do the same optimizations on -03, but clang decides to do it on -O2 as well!
What optimizations?

optimize great on clang, but no other platform... copy by uint64_t? I guess it is some detected heuristic in clang?

I guess it is hard to write compilers!!! different optimizations == different tradeoff:s

clang in REALLY aggressive with its loop-unrolling + vectorization

--> give some numbers for msvc here, write about std::array<uint8_t>, std::vector<uint8_t> and std::swap on msvc.

gcc and noinline gain a lot of perf!?!

// TODO: something about clearing the cache!

// TODO: note about unrolled avx clang vs gcc!


## why the slow memcpy()

// noticed that my memswaps was running faster than 2*memcpy. Can we write a faster memcpy as well?
// Why can I do it faster with SSE/AVX... what did I miss? There must be a reason!


## Conclusions

// * limited by memory-speed
// * clang, in these cases never seems to make any different choices between -O2 and -O3
// * TODO: CONCLUSIONS gcc seems better at generating small code, more used on embedded?

// SOME HEADING HERE?
What rubs me the wrong way with this is that there is nothing in the spec of `std::swap_ranges` that say that it has to be implemented generically for all underlying types. If the type can be moved with a `memcpy` it could be implemented by a simple loop (or even better something optimized!).

This is code and APIs used by millions of developers around the world, all of them having less of a chance to use a debug-build to track down their hairy bugs and issues.
I can see the logic behind "just have one implementation for all cases" and how that might make sense if you look at code from a "purity" standpoint but in this case there are such a huge amount of developers that are affected that imho that "purity" is not important at all. Your assignment as standard library developers is not to write readable and "nice" code (or maybe it is and in that case that is not the right focus!) it is to write something that work well for all the ones using your code! And that goes for non-optizied builds as well!


## Apendix, numbers!

time (us), 4MB swap
-------------------
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
| clang memcpy_only       |       |       |       |       |
| gcc   memcpy_only       |       |       |       |       |



code size (bytes)
-----------------
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

* std::swap_ranges in -O0 is an estimate and sum of all non-inlined std functions, functions used are 

unsigned char* std::swap_ranges<unsigned char*, unsigned char*>(unsigned char*, unsigned char*, unsigned char*)
std::remove_reference<unsigned char&>::type&& std::move<unsigned char&>(unsigned char&)
void std::iter_swap<unsigned char*, unsigned char*>(unsigned char*, unsigned char*)

This is beyond a travesty... the compilers has generated CALLS to std::remove_reference and if compiling with c++17 support to enable_if!!!
ON GCC enable_if is 118 BYTES!!! I see why this is the case... but why did we come to this!?!

// NOTE: added a test on 4MB std::array as well and it is just implemented with swap_ranges, thus the same result! (with the added niceness of extra call-instructions to begin() and end()!)

// godbolt link!

// for the swedish readers "me: so have you tried to run this code in Debug? c++-developers: 


// TODO: add measurements of std::swap_ranges and pure memcpy!

// TODO: graphs!
