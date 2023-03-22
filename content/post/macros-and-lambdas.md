---
title: "Macros and Lambdas"
date: 2022-10-16
tags: ['code', 'c++', 'tips-n-tricks']
---

Time for a short post on using lambdas to construct macros... that was a sentence that will be able to trigger 2 camps in one go :D


Defer
-----

First of, using lambdas to implement a `defer()` is really neat, however others has already written about that so that I don't have to!

[A Defer Statement For C++11](https://www.gingerbill.org/article/2015/08/19/defer-in-cpp/)


Call once
---------

So from my end I'll start of with a quick one for constructing a macro that only does something once, lets call it `IS_FIRST_CALL()`.
This can be used for things such as only logging something once or just asserting once. I'll leave it to the reader to decide if this is a "good" thing but it is absolutely things I have seen "in the wild".

```c++
// ... it can be used to implement other macros ...
#define PRINT_ONCE(s, i)          \
    do {                          \
        if(IS_FIRST_CALL())       \
            printf(s " %d\n", i); \
    } while(false)

int a_function(int i)
{
    if(i > 43)
        PRINT_ONCE("first time i was bigger than 43 it was %d", i);

    // ... or by itself ...
    if(i < 43 && IS_FIRST_CALL())
        printf("first time i was smaller than 43 it was %d", i);
}
```

A implementation of this would be something like this:

```c++
#define JOIN_2(x, y) x##y
#define JOIN_1(x, y) JOIN_2(x, y)
#define JOIN(x, y) JOIN_1(x, y)

#define IS_FIRST_CALL()                                      \
    [](){                                                    \
        static bool JOIN(call_it, __LINE__) = true;          \
        bool JOIN(call, __LINE__) = JOIN(call_it, __LINE__); \
        JOIN(call_it, __LINE__) = false;                     \
        return JOIN(call, __LINE__);                         \
    }()
```

We use a lambda (i.e. introduce a local function) to enable us to declare and check a static variable in any scope and "join" in the line-number to make sure that we don't get warnings for variable "shadowing".

Not much code, but increasing readability according to me!


Silence unused variables
------------------------

Next one!

In the codebase's where I usually work we treat unused variables as errors (for better or for worse!), imho this is usually valuable as it help with getting rid of dead code. However it do introduce issues with things such as logging and asserts where variables and functions only become unused in specific configs.

Consider something like this, where we have a PRINT() function that can be disabled with a define.

```c++
#if !defined(SHOULD_PRINT)
    #define PRINT(fmt, ...) // NOTHING!
#else
    #define PRINT(fmt, ...) printf(fmt, __VA_ARGS__)
#endif

int main(int, char**)
{
    int var = 0;

    PRINT("an int %d", var);

    return 0;
}
```

Compiling and running this works just fine ...

```
wc-duck@WcLaptop:~/kod$ clang++ t.cpp -Wall
wc-duck@WcLaptop:~/kod$ ./a.out 
an int 1337
```

... until someone disables the printing!

```
wc-duck@WcLaptop:~/kod$ clang++ t.cpp -Wall -DNO_PRINT
t.cpp:63:9: warning: unused variable 'var' [-Wunused-variable]
    int var = 1337;
        ^
1 warning generated.
```

Time to introduce `SILENCE_UNUSED(...)`

```c++
#define SILENCE_UNUSED(...)          \
    do {                             \
        if(false)                    \
            [](...){} (__VA_ARGS__); \
    } while(false)
```

This can then be used to implement `PRINT()` or by itself!

```c++
#if !defined(SHOULD_PRINT)
    #define PRINT(fmt, ...) SILENCE_UNUSED(__VA_ARGS__)
#else
    #define PRINT(fmt, ...) printf(fmt, __VA_ARGS__)
#endif
```

There are however quite a bit to unpack here, why is all the different parts needed.

First, we define a lambda taking variadic arguments, thus being able to use the argument without giving them a name... it turns out compilers have a hard time reporting warnings for variables they can't be sure that they exist ;)
This could of course also be possible with a `[[maybe_unused]] void silence_me(...) {}` but I prefer a lambda here to not "pollute" the global namespace with an implementation detail.

Secondly we need to put the call to the lambda within an `if(false)` to make sure that the actual arguments isn't evaluated. We wouldn't want a `SILENCE_UNUSED(expensive_call())` to actually call `expensive_call()` do we!

Lastly we wrap all of it in the mandatory `do {} while(false)` to make the macro into a "proper" statement that is useable within if/else etc.


Conclusion
----------

So... there we have it, some simple tools to build your macros using lambdas! Personally I find them kind of neat and I think they server a purpose!
