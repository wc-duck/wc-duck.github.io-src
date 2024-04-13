---
title: "Compile Time Hashes in C - Revisied"
date: 2024-04-13
tags: ['code', 'c++', 'optimization']
---

Hashing strings in c++ at compile time has been possible since c++11 but is it worth doing? Me and a few colleagues was discussed this over a few beers and it reminded me that I have already written about it [here](../compile-time-hashes-in-c-im-not-convinced) (8 years ago... ARGH I'm getting old!).

But a lot of time has passed since I wrote that... and I didn't make any measurements in that article! *shame!* *SHAME I SAY!*

So it is time to revise this and answer some questions.
* What is the overhead of hashing strings at compile time)
* Are there other pros/cons doing it at compile-time compared to some preprocessor or script?

# Generating some test code

To get some meaningful test-cases we probably need to test quite a lot of hashes and since I wasn't really in the mood hand-write that I resorted to my trusty old friend python.

And with the help of [https://github.com/AntonJohansson/StaticMurmur](https://github.com/AntonJohansson/StaticMurmur) and my own python lib [https://github.com/wc-duck/pymmh3](https://github.com/wc-duck/pymmh3) it didn't take long to whipp up a python script to generate cpp-file whit lots of hashes.

> a note on the hash function used.
> I just picked MurmurHash3 as that is what I use at home and at work mostly... is that a good one?
>
> ¯\\_(ツ)_/¯
> 
> As good as any for this test I think!

So now we have this generated code:

```c++
#include <stdint.h>
#include "StaticMurmur.hpp"

int switch_me(uint32_t val)
{
    switch(val)
    {
    #if CONSTEXPR_HASH
        case murmur::static_hash_x86_32("nlvykhgxncrkqjqg", 0): return 0;
        case murmur::static_hash_x86_32("jeqejajpfgbxadqq", 0): return 1;
        case murmur::static_hash_x86_32("psrgqorfrelbavmm", 0): return 2;

        // ... lots of cases ...

        case murmur::static_hash_x86_32("wddjastpsstmdizm", 0): return 4095;
    #else
        case 0xc045b43c: return 0;
        case 0xecf91e72: return 1;
        case 0x8239d78b: return 2;

        // ... lots of cases ...

        case 0xcf83cfd8: return 4095;
    #endif
        default:
            break;
    }
    return 0;
}
```

A single switch with 4096 different values and no variation on the string length. I would guess that the length here is "around" the average string-length that at least I would expect to find being hash at compile-time (See, here I am not collecting the real data again!).

## Getting the numbers

Since the script can generated a different amount of hashes I generated files with 16, 128, 1024, 2048 and 4096 hashes each and threw them at `g++` and `clang++` with both `-O0` and `-O2`.

> Compilers used:
> 
> `g++ --version` -> g++ (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
>
> `clang++ --version` -> Ubuntu clang version 14.0.0-1ubuntu1.1


|                         | 16     | 128    | 1024   | 2048   | 4096   |
|-------------------------|--------|--------|--------|--------|--------|
| `g++ -O0` constant      | 0.015s | 0.021s | 0.078s | 0.175s | 0.475s |
| `g++ -O0` constexpr     | 0.015s | 0.027s | 0.140s | 0.302s | 0.750s |
| `clang++ -O0` constant  | 0.023s | 0.028s | 0.056s | 0.084s | 0.153s |
| `clang++ -O0` constexpr | 0.026s | 0.047s | 0.203s | 0.386s | 0.750s |
| `g++ -O2` constant      | 0.017s | 0.036s | 0.304s | 0.920s | 4.041s |
| `g++ -O2` constexpr     | 0.018s | 0.045s | 0.371s | 1.068s | 4.370s |
| `clang++ -O2` constant  | 0.025s | 0.039s | 0.224s | 0.612s | 2.097s |
| `clang++ -O2` constexpr | 0.030s | 0.063s | 0.392s | 0.917s | 2.716s |

If we look at the table we can clearly see that we pay something for using the constexpr hashes, it would be unexpected if we didn't... but it also do not seem to be that much. We can see that in the bigger numbers that the times is quite high regardless if just generating the hashes or using the constexpr hash. We clearly see that it take quite a bit of time to compile with both approaches.

What is it that the compilers are spending their time on then? Optimizing the huge switch of course! Lets try again but this time we'll just generate the constants!

> What the compilers do with the switch/case is out of scope for this post, maybe there will be a followup? Would be interesting to dig down into the generated assembly of that.

We'll change the script to generate this instead.

```c++
#include <stdint.h>
#include "StaticMurmur.hpp"

#if CONSTEXPR_HASH
    constexpr uint32_t const_0 = murmur::static_hash_x86_32("trwlssxfykmuzljm", 0);
    constexpr uint32_t const_1 = murmur::static_hash_x86_32("wgyvldnumcqwvlmm", 0);

    // ... lots of constants ...

    constexpr uint32_t const_15 = murmur::static_hash_x86_32("vhjbpzwglrkisdvv", 0);
#else
    constexpr uint32_t const_0 = 0xc7f2b682;
    constexpr uint32_t const_1 = 0xade60248;

    // ... lots of constants ...

    constexpr uint32_t const_15 = 0xe4fa1635;
#endif
```
Compiling these in the same way gives us this:

|                         | 16     | 128    | 1024   | 2048   | 4096   |
|-------------------------|--------|--------|--------|--------|--------|
| `g++ -O0` constant      | 0.011s | 0.016s | 0.024s | 0.033s | 0.053s |
| `g++ -O0` constexpr     | 0.012s | 0.021s | 0.093s | 0.172s | 0.313s |
| `clang++ -O0` constant  | 0.026s | 0.025s | 0.035s | 0.048s | 0.072s |
| `clang++ -O0` constexpr | 0.037s | 0.043s | 0.129s | 0.293s | 0.533s |
| `g++ -O2` constant      | 0.011s | 0.017s | 0.021s | 0.026s | 0.038s |
| `g++ -O2` constexpr     | 0.012s | 0.023s | 0.089s | 0.157s | 0.305s |
| `clang++ -O2` constant  | 0.023s | 0.025s | 0.039s | 0.050s | 0.073s |
| `clang++ -O2` constexpr | 0.029s | 0.044s | 0.142s | 0.272s | 0.517s |

Way faster!

Most overhead seems to be in "optimizing the switch()". Doing some quick math just dividing the diff between constant and constexpr we see that when the amount of hashes rise the time-per-hash flattens out to a constant, 0.06ms for gcc and 0.1ms on my machine. On the lower numbers I guess that the overhead on "everything except hashes" skews the numbers to make them unreliable.

It is kind of interesting that clang is that much slower than gcc but that just mean that there are room for improvements right? Is it worth it to compare with a compiled version of the hash-function? I did a really unscientific test with many factors that might skew the result gives us these numbers.

Test app:
```c++
#include <stdint.h>
#include <stdlib.h>

#include "StaticMurmur.hpp"

const uint8_t* gen(uint32_t s)
{
    srand(1337);

    uint8_t* buf = (uint8_t*)malloc(s);
    for(uint32_t i = 0; i < s; ++i)
        buf[i] = (uint8_t)rand();

    return buf;
}

int main(int, const char**)
{
    const uint8_t* buf = gen(1024 * 1024 * 128);
    uint32_t hash = murmur::MurmurHash3_x86_32((const char*)buf, s, 0);
    return hash;
}   
```

That result in a speed of 0.8us per char while the gcc does it in compile time at a paltry 37.5us per char. Not a fair comparison at all, but worth putting in here just for visibility.


## Conclusions

So what have I learned? I don't want to say 'we' as you might come to other conclusions from these numbers than I did! Lets draw up some pros and cons to come to the conclusions.

**pros of compile-time hashing:**

It is easy to add hashes to your code. In theory some kind of pre-processor or script that I described in the previous post will always be the "fastest" solution to build. However from what I have seen in real code bases is that it is a significant hurdle to go and add a new .hash-file, or add your hash to a previous file. Maybe not so much a technical hurdle as a mental one.

This usually lead to code like this, something I am also guilty of:

```c++
// TODO: move this to pre-compile step
static const uint32_t my_hash = hash_string("my string of doom!");
```

Surprise, surprise... it will never be moved and it will just live there with all what that mean. It will never be expensive enough for anyone to fix but it will always be there and adding to your software being ever so slightly worse.

What you also see in code using pre-compiled hash-files is that they are usually full of dead and unused hashes for everything and nothing. People have just added entries and when the code is removed they are forgotten in the source-files.

There is also the approach of having a custom preprocessor that runs over all your code before compile. I haven't worked in a codebase that does that so take my opinion here with a great scoop of salt!
I would guess that it will add some time as well and also add more complexity to build-pipelines etc. If you have a codebase where you can just throw all your files in a "compile all files at once, it compiles so fast anyways" it might be the best solution out there. But some of us just dream of that kind of luxury!


**cons of compile-time hashing:**

The compiler can be quite finicky when it actually pre-compile constexpr hashes, at least in `-O0` and it is kind of easy to get it evaluated at runtime (and one might actually argue that the compiler shouldn't optimize this for debugging your functions!).

Compare

```c++
// evaluated in runtime in -O0
const uint32_t my_hash = my_constexpr_hash_string("my string of doom!");
// evaluated in compile-time in -O0
constexpr uint32_t my_hash = my_constexpr_hash_string("my string of doom!");
```

But to be honest, what I usually see, the `static const uint32 my_hash = hash_string("str")`, will never evaluate in compile time either... so that might be a moot point? It will result in worse code as c++ guarantees that `my_hash` is only initialized once. I.e. the compiler need to implement some kind of locking mechanism here. A quick [godbolt](https://godbolt.org/z/ohxbqfEhc) shows us that yes, the compiler will generate an extra branch and a lock for the value, probably not that expensive as branch-prediction will almost always be a hit, but still.

A bigger problem in my book might be that you actually do not have a central point where you can "collect" hashes for things such as checking for hash-collisions and setting up tools for hash to string lookups etc.


## Final words

After looking at the actual numbers and digging into this topic a bit deeper I might have changed position here, or if nothing else altered my view on the topic a bit. Doing hashing in compile-time is probably going to be fairly low-cost. How many strings like these do you actually have per file, probably not 4096 or more :)

I would say that there is still use cases for a hash -> header generator or similar tool. If you have some code that goes into lots of other files it might be worth optimizing that case instead of everyone paying that cost all the time, and if you have some other kind of code-gen that generate hashes there is no reason at all why you wouldn't pre-compute the hash outside of your c++ compilation.

But for "a few hashes here and there" you would probably be better of with the more user friendly option that make sure that it is actually used (and cleaned out when no longer in use!).

BTW, I'm really annoyed that I didn't look into the numbers "back then" as it would be interesting digging into how compilers has evolved on this topic over the years. Maybe this was way more expensive, finicky etc back then? I could dig up old compilers and test... but no!

Am I right? Am I wrong? Ping me in the usual channels if you have any comments!

### Appendix

Here are the scripts used to generate the tests... you can probably write them yourself in a short amount of time but here you are :)

[gen.py](gen.py)
[build.sh](build.sh)
