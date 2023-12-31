---
title: "Simple Polling With Lambdas"
date: 2023-12-24
tags: ['code', 'c++', 'api-design']
draft: true
---

In this post I'm going to touch on a c++-technique to handle callbacks that I have not seen written about before and that many of my collegues hadn't seen before either. Probably it's not something new and some of you will probably just say "yeah yeah, nothing new under the sun" but it's probably worth a few words!

Most of us has been in situations where we need to pass a functor that use some local variables to a function. It might be that we have some kind of "for each" over some collection of things or polling events from a system.

I, for example, like to write systems that need polling that can also emit events/results that happened since the last poll for the user to react to. One conveniant way to do this is to just pass a callback to your poll-function that is called per item.
This will not "force" any storage on the user such as returning an allocated array would do and leave the actual decission on what to do with the data to the user. 

Something like this:

```c++
struct the_system_msg
{
    msg_type type;

    // ... payload goes here! ...
    union
    {
        struct event1
        {
            // ... payload if type == event1
        };

        struct event2
        {
            // ... payload if type == event2
        };
    } evt;
};

void the_system_poll(the_system sys, /*callback here*/);

void poll_me(the_system sys)
{
    some_other_system& other = get_other_system();

    // our poll-function will give you a callback for x amount of events... you don't know how many... but "a potential bunch".
    the_system_poll(sys, [&other](const the_system_msg& msg)
    {
        switch(msg.type)
        {
            case type_event1:
                other.do_stuff_with_x(msg.event1);
                break;
            case type_event2:
                other.do_stuff_with_y(msg.event2);
                break;
        }
    });
}
```

As you can see I left out 'callback' here as that is what we are about to come to now.

## std::function

The canonical way of doing this in c++ is to reach for `std::function`, something like this:

```c++
#include <functional>

void the_system_poll(the_system sys, std::function<void(const the_system_msg& msg)> cb);
```

This works... but it is not without its drawbacks!

### Memory allocations

First of, `std::function` can allocate memory on the heap, something that would be wasteful if we aren't storing our closure. It is as far as I can tell allowed to do that all the time but all modern `std::`-lib implementations seem to optimize that by putting smaller closures into the std::function object itself.

This behavior can lead to your application all of a sudden starting to allocate without you seeing it. For example you might need to "just capture one more int" or a struct "grows" witohut you seeing it. Boom, allocation creaping in!


### Compile times

Including `<functional>` on my system adds a shitton (metric!) of lines to compile to you pre-processed c++-file! How ever you turn this, throwing more code on your compiler to work with will probably not make it complete faster! We will get to numbers and comparisons later on!


### Debug performance

Thirdly, debug-performance! Yes, we should care about performance in debug-builds as optimized builds can be way harder to use when tracking down issues.

> The fact that, at work, I can run a full debug-build of Apex (the Avalanche Engine) and still reach decent performance is worth a lot to your day to day productivity!

As we can see in a previous post about [swapping memory](../swapping-memory-and-compiler-optimizations) we can see that the c++ standard library can be far from great in a non optimized build!


## Just pass the closure!
So, what can we do instead? 'Just pass the closure' is the simplest solution! This is suggested by many, for example in this [article](https://wolchok.org/posts/cxx-trap-2-std-function/).

Something like this:

```c++
template<typename FUNC>
void the_system_poll(the_system sys, FUNC&& cb)
{
    // ... implement me ...
}
```

Yay, no more `std::function`! This should solve all the lines included from `<functional>` and will probably make your perf in a `-O0` build quite a bit better!
Yet again we will come to numbers later!

So all numbers look great (trust me!), we are all happy right? RIGHT? Well not quite. What does the above code really mean? It means that all our code in `the_system_poll()` need to be inlined due to the template. For a smaller function this is just fine and maybe even desired! But in this case it might mean that we need to inline a big part of a bigger system! What if `the_system` need a lot of lines of code to implement or that the implementation of the storage for `the_system` requires a whole bunch of expensive includes to just be able to be declared. We would not want to expose that to your humble user just by including `the_system.h`!

## c-style

So how do we handle this? As usual a good way to solve this is to look at a c-style interface. This is something I personally see as the solution to many problems and maybe a topic for its own post some day :)

But how would this look if you would do it in c? Probably something like this:

```c
void the_system_poll(the_system sys, void(*cb)(the_system_msg& msg, void* userdata), void* userdata);
```

> note: yes yes, I know `&` is not c!

I.e. we would pass a function pointer and userdata as a `void*` and on the implementation side cast that `void*` back to what we originally passed in. By doing this we can put all our implementation of this function in a `.c`/'`.cpp`-file and hide all of our implementation for the user! This works but the ergonomics maybe leave a bit to be desired:

```c++
struct my_user_data
{
    int data1;
    int data2;
};

static void poll_function(const the_system_msg& msg, void* user_data)
{
    my_user_data* ud = (my_user_data*)user_data;

    use_me(ud->data1);
    use_me(ud->data2);
}

void poll_me(the_system sys)
{
    my_user_data ud;
    ud.data1 = some_value1;
    ud.data1 = some_value2;

    the_system_poll(sys, poll_function, &ud);
}
```
That is quite a bit of code and honestly quite a few things to get wrong.

## Kihlanders reverse

But what if we combine these 2 approches? I.e. use the classical c-style function + userdata to be able to hide away all implementation and use the templated closure for ergonomics! If we combine them it could look something like this:

```c++
void the_system_poll(the_system sys, void(*cb)(the_system_msg& msg, void* userdata), void* userdata);

template<typename FUNC>
void the_system_poll(the_system sys, FUNC&& cb)
{
    // ... lets add a second wrapper-functions to handle the casting for us ...
    auto wrap = [](const the_system_msg& msg, void* userdata) {
        // ... we passed a pointer to the generated closure through our userdata-pointer ...
        FUNC& f = *(FUNC*)userdata;
        // ... and then call it ...
        f(msg);
    };

    // ... pass the wrapper as the callback to the c-function and the generated closure as userdata ...
    the_system_poll(sys, wrap, &cb);
}
```

> If this hasn't been described before I would like to dub this `Kihlanders reverse`, it has a nice ring to it right?

This would make it possible to write this:

```c++
void poll_me(the_system sys)
{
    the_system_poll(sys, [&some_value1, &some_value2]()){
        use_me(some_value1);
        use_me(some_value2);
    });
}
```

Just by introducing a 5 line wrapper we can give the user all the ergonomics of the original `std::function` without much of the cost! We also have an API that is compatible with `c` and all the languages that can call `c` by just adding an:

```c++
#if defined(__cplusplus)
// ....
#endif
```
around our generated wrapper-function!

# Numbers!

But enough talk about perf without numbers!

> Before we start, this is the standard disclaimer about micro benchmarks. They are hard and might be inacurate compared to a real world scenario etc. You know the drill!

All this work has been done on my laptop with the following specs:

> **CPU** Intel i7-10710U
>
> **RAM** 16GB LPDDR3 at 2133 MT/s (around 17GB/sec peak bandwidth)

And I'll use the compilers that I have installed, that being

> **Clang:**  14.0.0-1ubuntu1.1
>
> **GCC:** (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0

## Compile time

First of, lets look at the compile-time claim. Let's create the smallest possible test-file that we can create:

```c++
#if defined(USE_STD_FUNC)
#include <functional>
#endif

struct the_system_msg
{
    int i;
};

#if defined(USE_STD_FUNC)
void func(int sys, std::function<void(const the_system_msg&)> cb);
#else
void func(int sys, void(*)(const the_system_msg& msg, void* userdata), void* user_data);

template<typename FUNC>
void func(int sys, FUNC&& cb)
{
    auto wrap = [](const the_system_msg& msg, void* userdata) {
        FUNC& f = *(FUNC*)userdata;
        f(msg);
    };
    func(sys, wrap, &cb);
}
#endif
```

Timing this small file is probably not that realistic, but lets do it anyways and see what we end up with.
We can start with noticing that the time is basically the same across all the optimization levels (`-O0`, `-O2`, `-O3`, `-Os`). Not really surprising as we don't give the compiler anything to work with... 

But just using `time` we get roughly these numbers for clang and gcc.

```sh
wc-duck@WcLaptop:~/kod/functor_test$ time clang++ -c -O2 functor_preproc.cpp -o functor_preproc.o

real    0m0,031s
user    0m0,009s
sys     0m0,023s
wc-duck@WcLaptop:~/kod/functor_test$ time clang++ -c -O2 -D USE_STD_FUNC functor_preproc.cpp -o functor_preproc.o

real    0m0,105s
user    0m0,084s
sys	    0m0,021s
wc-duck@WcLaptop:~/kod/functor_test$ time g++ -c -O2 functor_preproc.cpp -o functor_preproc.o

real    0m0,022s
user    0m0,009s
sys     0m0,008s
wc-duck@WcLaptop:~/kod/functor_test$ time g++ -c -O2 -D USE_STD_FUNC functor_preproc.cpp -o functor_preproc.o

real    0m0,174s
user    0m0,137s
sys     0m0,032s
```

This is highly unscientific, but we see a diff in cost just compiling the code and in a bigger codebase things like this tend to add up. But where is the time spent. We could dig in deeper with something like clang [-ftime-report](https://aras-p.info/blog/2019/01/12/Investigating-compile-times-and-Clang-ftime-report/) but it is probably enough to just look at the pre-processed code.

Preprocessed code for the non-`std::function` code is about the same lines that we wrote, i.e. 

```c++
# 1 "functor_preproc.cpp"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 404 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "functor_preproc.cpp" 2




struct the_system_msg
{
    int i;
};




void func(int sys, void(*)(const the_system_msg& msg, void* userdata), void* user_data);

template<typename FUNC>
void func(int sys, FUNC&& cb)
{
    auto wrap = [](const the_system_msg& msg, void* userdata) {
        FUNC& f = *(FUNC*)userdata;
        f(msg);
    };
    func(sys, wrap, &cb);
}
```

I'm pretty sure that you don't want me to paste out the thousands of lines that you get with `std::function`, depending on what c++-version you target you get these numbers, these are lines with all empty lines stripped via:

> `g++ -E functor_preproc.cpp -DUSE_STD_FUNC -std=c++98 | sed '/^\s*#/d;/^\s*$/d' | wc -l`

> It is worth noting that I dediced to strip out empty lines as the preprocessors seem to produce a lot of it. My really uneducated guess is that it is just faster for the preprocessor to strip out "ifdef":ed code by switching the lines with new-lines instead of removing them from the data properly? But that is just a guess. However I think it is much fairer to count the lines without the empty lines as a compiler probably handle these lines quickly.

|       | std=c++98 | std=c++11 | std=c++14 | std=c++17 | std=c++20 |
|-------|-----------|-----------|-----------|-----------|-----------|
| clang |       505 |      8477 |      9252 |     23622 |     27211 |
| gcc   |       505 |      8477 |      9248 |     23589 |     27180 |

That is a lot of lines compared to 14 that was the non std-one! Regardless of how you put it, that will take time to process. And this is BEFORE we have actually started to turn all these lines into instructions for the CPU to execute!


## Performance

Next up is performance, how do the different solutions stand up against each other. To test this out we'll write a benchmark app using the excelent [ubench.h](https://github.com/sheredom/ubench.h).

[functor_bench.cpp](functor_bench.cpp)

I have added a few different test-cases to benchmark, both tested with a 'small' capture and 'big' one where the 'big' one should be big enough to not trigger small-object optimization. All "calling back into user code" 1000-times per iteration.

* std::function passed to a non-inlined function
* std::function passed to an inlined function
* just pass a simple closure to an inlined function
* a c-style function passing a void* userdata
* and a kihlanders reverse one.

Let's see how they perform, these are the times captured by the benchmark.

|                             | gcc -O0 | gcc -O2 | clang -O0 | clang -O2 |
|-----------------------------|---------|---------|-----------|-----------|
| std::function small         |  32.5us |   1.3us |    24.2us |     1.5us |
| std::function big           |  29.2us |   1.3us |    23.2us |     1.5us |
| inlined std::function small |  32.9us |   1.5us |    24.2us |     1.5us |
| inlined std::function big   |  27.6us |   1.5us |    23.2us |     1.8us |
| inlined closure small       |   3.2us |  0.02us |     2.9us |    0.02us |
| inlined closure big         |   3.2us |  0.02us |     2.9us |    0.02us |
| c-style small               |   5.9us |   1.3us |     4.6us |     1.4us |
| c-style big                 |   5.9us |   1.3us |     4.4us |     1.4us |
| kihlanders reverse small    |   8.3us |   1.3us |     5.3us |     1.4us |
| kihlanders reverse big      |   8.3us |   1.3us |     5.4us |     1.4us |

> these are mean values of the above tests. To note is also that the results are not super stable but 'within reason' determined by me.

So what can we take away from these numbers.

One takeaway is, just as in [swapping memory](../swapping-memory-and-compiler-optimizations)-article, debug-performance of `std::` is just horrible. You are paying a lot for that "conviniance" in your non-optimized build.

Secondly an inline function is, obviously, faster in all builds and in `-O2` it is taken as far as both gcc and clang just calculating the answer to my benchmark right away and just store an int directly. Interrestingly they can't do the same thing with the `std::function` version even if you inline it. Throwing complexity at the compiler will force the compiler to spend time on the complexity instead of optimizing the actual code!

I also find it interresting that clang seems to do quite a bit better work with all of the code in `-O0` while gcc performs better in `-O2`.

Finally we see that Kihlanders reverse seem to add no overhead to any of the non-inlined alternatives and generally better than `std::function` in all cases.


# Conclusion

According to me this is a really nifty way to provide your users with a good API at low cost in both compile-time and performance. I, for example, use this in https://github.com/wc-duck/dirutil and it's `dir_walk()` function and also in quite a few API:s in the "Apex Engine".
It is obviously not for all your usecases as you can't store the capture and using something like this for a `sort` or similar that you want inlined is probably not a good idea.

So to close this article, was this usefull? Did I miss something? Feel free to reach out and tell me (if you are civil that is :) ).
