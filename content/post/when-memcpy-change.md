---
title: "When memcpy() change!"
date: 2022-10-23T09:38:33+02:00
draft: true
---

> To start of, yes, I know that this article touch undefined behavior and that all bets are off!

I am currently working on a bigger post on swapping memory that is THIS close to being done... any day now (he has been saying the last year!).

However this topic popped up and I was wondering if it was worth making the other post longer or just make a small one about it. As the other post is already quite big I opted for a shorter one here.

So what am I on about you might ask, weird title and all? `memcpy()` don't just change right, it is well defined what it should do! It should copy memory from buffer `a` to buffer `b`... as long as they don't overlap, then your in *undefined behavior territory* (spooky sounds go here!).

In c and c++ we basically have 2 primitives to copy memory, we have `memcpy()` and `memmove()` where `memcpy()` is "as efficient as possible" and `memmove()` also handle the case where source and destination overlap and copy the data as if a temporary buffer was used in between.

So far so good, i.e. you, as a user of the functions, is expected to know if you have overlapping buffers in your src and dst.

Well as it turns out, you and me as developers are quite bad att knowing if your buffers DO overlap or not, as seen by the kerfuffle back in 2010 when GLIBC decided to replace its old `memcpy()` that just used `memmove()` with an optimized version that really required the buffers not to overlap. "Hilarity" ensued and everyone had a great day at work... or maybe I misunderstood something? ;)

IMHO it is the right decision on a system-level to implement `memcpy()` as `memmove()` for the above mentioned reason, that reason being you and me as developers are stupid :) Many systems however don't do this so we still need to think about it.

And now to the interesting part... lets try this out on my linux-machine. Let us add a simple program like this:

> In this post I will define "the right" behavior to be memmove() all the time... if this is right can absolutely be debated and I would not be on the side that it is ALWAYS the right choice, but for the sake of this article we define that as "right".

# Trying it out

```c++
#include <string.h>
#include <stdio.h>

int main(int, const char**)
{
    int cpy[] {0, 1, 2, 3, 4, 5, 6};
    int mov[] {0, 1, 2, 3, 4, 5, 6};

    memcpy (&cpy[1], &cpy[0], 5 * sizeof(int)); // OHNO... overlap ahoy!
    memmove(&mov[1], &mov[0], 5 * sizeof(int));

    printf("cpy: ");
    for(int c : cpy) printf("%d ", c);
    printf("\n");

    printf("mov: ");
    for(int c : mov) printf("%d ", c);
    printf("\n");

    return 0;
}
```
[play along in compiler explorer](https://godbolt.org/z/jobGTbhfr)

Compile with gcc...

```console
wc-duck@WcLaptop:~/kod$ gcc test.cpp -o t
wc-duck@WcLaptop:~/kod$ ./t
cpy: 0 0 1 2 3 4 6 
mov: 0 0 1 2 3 4 6
```
... and success!

... and clang? ...

```console
wc-duck@WcLaptop:~/kod$ clang test.cpp -o t
wc-duck@WcLaptop:~/kod$ ./t
cpy: 0 0 1 1 3 3 6 
mov: 0 0 1 2 3 4 6 
```

OH NO!

If we dig in to the code that clang generates we see that clang has replaced the call to `memcpy()` and `memmove()` with its own inline implementations that DO follow the rules and expect input to memcpy() to not overlap. A valid conversion as it seems really wasteful to copy a few bytes via a function-call. (Question however, is clang really allowed to do this in a non-optimized build?)

We can also try an optimized build.

```console
wc-duck@WcLaptop:~/kod$ gcc test.cpp -o t -O2
wc-duck@WcLaptop:~/kod$ ./t
cpy: 0 0 1 2 3 3 6 
mov: 0 0 1 2 3 4 6
wc-duck@WcLaptop:~/kod$ clang test.cpp -o t -O2
wc-duck@WcLaptop:~/kod$ ./t
cpy: 0 0 1 2 3 4 6 
mov: 0 0 1 2 3 4 6
```

Now we see that gcc generate an invalid(?) result but clang generate what would be expected(?). This time gcc decided to replace `memcpy()` with an inlined version that is a "pure" `memcpy()`. But how did clang get it "right", lets dig in?

It seem like the diff on clang between -O0 and -O2 is that it uses vector-instructions to implement its inlined `memcpy()` and `memmove()` and unroll the loop here as there are no branch-instructions in the copies that should occur... I'm not really sure what is going on here, but we can at least conclude that in this case clang generate different code that result in different semantics depending on optimization flags. I guess we are in undefined behavior land now *¯\\_(ツ)_/¯*

# Conclusions?

So what have we learned? Don't know really... undefined behavior is undefined maybe?

On a more serious note, should we be able to expect our compilers to generate equivalent code depending optimization level? One might think so but I guess that would have a lot of repercussions in other areas.

And in cases like this where the compiler could easily see that the buffers overlap, should they generate `memmove()`-semantics code here? I know that some static-analyzers warn about this, but for all old code, why not try to at least save them from them self (and emit a warning)? I would be surprised to find code where the undefined behavior of `memcpy()` would be what you actually wanted?

Regardless, I found this little "thing" was worth a few words in blog-form just for the sake of it... hope you found it at least worth your time reading it :)
