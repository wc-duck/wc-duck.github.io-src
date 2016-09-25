Title: Compile-time hashes in c++, im not convinced!
Date: 2016-09-24
Tags: code, c++

I recently read a blogpost about [compile-time string-hashes and constexpr](http://blog.demofox.org/2016/09/23/exploring-compile-time-hashing/) and I'm still not convinced and 
see no real reason to leave my old and true friend the script :)

So first of lets look at the problem we want to solve. We want a way to do things like this and not pay the runtime cost ( and in this case just compile! ).

```c++
void my_func( uint32_t val )
{
    switch( val )
    {
        case HashOfString("some_string"):
            do_some_stuff();
            break;
        case HashOfString("some_other_string"):
            do_some_other_stuff();
            break;
    }
}
```

Simple enough. What seems to come up over and over again is ways of doing this with the compiler compile-time and now recently just marking `HashOfString` as `constexpr` and "trust the compiler".
The solution I usually fall back to is to just have a text-file where each line is hashed with a custom script and written to a .h file with values such as:

***my_hashes.hash***
```
some string
some other string
```

***my_hashes.hash.h***
```c++
#pragma once

#define HASH_some_string       0xABCD0123 // hash of "some_string"
#define HASH_some_other_string 0x0123ABCD // hash of "some_other_string"
```

***usage in code***
```c++
#include "my_hashes.hash.h"

void my_func( uint32_t val )
{
    switch( val )
    {
        case HASH_some_string:
            do_some_stuff();
            break;
        case HASH_some_other_string:
            do_some_other_stuff();
            break;
    }
}
```

With a resonable buildsystem in place this can be automated and never be in your way. I have it setup to collect all `<filename>.hash`-files and output `<filename>.hash.h`.

So lets compare the different solutions and see why I prefer the one I do by just listing my perceived pros/cons.

The biggest pro for using the c++-compiler itself for this is to not need a custom buildstep for the hashes and that is a really fair point. No need to setup a buildsystem or manually generate 
the headers can really be an important point in some cases, especially when distributing code to others. Also having the hashed string where it is used is by some considered a pro, for me it is
a + but a small one.
But that is about where the pros stop i.m.h.o.

On the cons list I think the biggest 2 are that I have to trust the compiler to do the right thing and paying the cost for generating this each time I compile my code.

Let's start of with the first one, trusting the compiler. Sure, compilers are smart etc but are we sure that the compiler will optimize a `HashOfString("some_string)` to a constant? If it does
with your current compiler, will it with another compiler? What happens when a new version of your compiler is released?
With the simple "generate a .h"-file I am quite sure that it will evaluate to a constant and I will not have to think about it.

The other issue with compile-time hashes in pure c++ is why pay for something all the time when you can pay for it once? I.e. if I put code in a .cpp to generate a hash by the compiler it will
cost time each time I compile that file. When generating a header I pay for it once, when I change the text-file with the strings to hash.

We also have some other pros that are not as big, but I might just as well list them here for completeness:

* easier to find the actual value of the hash. When generating a header you just look in the header, when doing it with the compiler... it gets harder!
* you have control over how the header is generated, you want to add registering of hash-value -> string? just add it!

So what do you think, what pros have I missed on hashing with the c++-compiler? Why am I wrong? 

