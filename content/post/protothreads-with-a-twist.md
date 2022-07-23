---
title: '"ProtoThreads" with a twist.'
date: 2018-11-20
tags: ['code', 'c++', 'coroutines']
---

For a long time I'v been interested in running game-specific/entity-specific code in coroutines. 
Something like the following.

```c++
void some_game_object_behavior( entity ent, ... )
{
    pnt3 points[] = {
        {1,1,1},
        {2,2,2},
        {3,3,3},
        {4,4,4}
    };

    int pos = 0;

    while(entity_alive(ent))
    {
        // move the entity to a position and yield coroutine while movement is ongoing.
        move_to(ent, points[pos % ARRAY_LENGTH(points)]);
        pos++;

        for(int i = 0; i < 4; ++i)
        {
            shoot_bullet(ent);
            wait_sec(ent, 2); // do nothing for 2 seconds and yield the coroutine for that duration.
        }
    }
}
```

The above example is slightly simplified but I hope that it get the point across, that I want to be able
to suspend code-execution at specific points and wait for certain actions to complete. Writing  one-off 
game-code in this fashion might be a good way to work, especially when adding wait_for_any() and  wait_for_all()
etc.

So when I finally decided to take a stab at trying that out I started out by looking at how to implement the
actual coroutines. There are a couple of libraries out there that I looked at for coroutines in c/c++ such as:

- [libaco](https://github.com/hnes/libaco)
- [libdill](http://libdill.org/)
- [libmill](http://libmill.org/)

Both libdill and libmill feel too 'opinionated' on how they want you to structure your code ( not that
weird since the both sets out to re-implement go:s goroutines in c ) and also feels 'heavier' than what I
need.
libaco however sparked my interest, it looked quite lean and not too opinionated, i.e. it looks really nice! 
But there is a big BUT, no windows support yet =/ I do most of my development on Linux but throwing Windows 
support out of the "window" (**badumtish**) is not something I want to do.
According to the issue-tracker it is in "the pipe" but it is not supported as of writing this.

This lead me to fire of a question on twitter about alternatives and where [@RandyPGaul](https://twitter.com/randypgaul)
pointed out something that I had looked at before but totally forgot about, coroutines/protothreads based 
on "duff's device".

Since this technique is already well documented on the interwebs I'll just link to the original 
article here and wait until you have read it ( if you haven't already ).

[coroutines in c](https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html)

Read it yet? Good!

Here are a few other links to libs that implement these kind of coroutines.

- [protothreads](http://dunkels.com/adam/pt/)
- [zserge/pt](https://github.com/zserge/pt)
- [cute_coroutine](https://github.com/RandyGaul/cute_headers/blob/master/cute_coroutine.h)

What I like about this solution is that it is "just code" so it should in theory work on any platform without
platform-specific code. It should also work with emscripten ( that I shall get running any day now!!! ;) ).

There are however things that I am missing from these otherwise fine libraries.
A major one is based in how I plan to use them. I plan to have all my "behaviors" run one coroutine and 
have some kind of simple "scheduler" run them. Something simple as having all "active" coroutines in a list,
remove them from the list when waiting for something, and update them in a loop. However doing that with the
above libs would require me keeping track of what functions are associated with each coroutine state.

Also local variables/state is not handled by the above libs and would need to be handled by passing in some
kind of state-struct, that would need to be different for each "behavior" and also be tracked by the above
mentioned system.

2 of the 3 libs also fails to handle calling another coroutine-function from within a coroutine and by that
having the sub-call control the state of the top-level coroutine. For example if a sub-call does a yield or
wait the entire call-hierarchy should do the same (cute_coroutine.h solves this for a fixed depth of sub-calls).

So what do you do when you have an interesting itch to scratch? You scratch it of course :)


# Solving the issues!

As any decent NIH-addict I decided to try myself and see what I could do and came to the conclusion that all
the above issues can be solved by adding a small stack to each coroutine, i.e. almost do what the compiler 
does!

Introducing my boringly named coroutine lib/header, [coro](https://github.com/wc-duck/coro).

As mentioned above the only real difference between `coro` and the above mentioned libs are that each coroutine 
in coro MAY have a stack associated with it where the system itself can push data and reset when a coroutine completes.  

>
> Warning for you C-all-the-way people, there be some usage of C++ in this piece of code! But I guess it wouldn't
> be that hard to C:ify the lib if there is demand for it!
>

The library does nothing particularly fancy at its core, the simplest coroutine would be implemented and updated 
like this.

```c++
void my_coro( coro* co, void*, void* )
{
    // all coroutines need a matching co_begin/co_end-pair
    co_begin(co);

    // ... do stuff ...

    // ... yield execution of coroutine, i.e. introduce a yield-point in the
    //     function where to continue execution on the next update ...
    co_yield(co);

    co_end(co);
}

void run_it()
{
    // ... create and initialize our coroutine ...
    coro co;
    co_init(&co, nullptr, 0, my_coro);

    // ... resume until completed ...
    while(!co_completed(&co))
        co_resume(&co);
}
```

But now to the meat of this post, how will adding a stack solve the above mentioned issues?


## General coroutine update

Well, this isn't solved by the stack, this is just solved by introducing a struct for the coroutines and storing a
function-ptr in it :) Now we have that out of the way, carry on.


## Local variables

Lets get to the stack-part and start with local variables. When we have a memory-area to store data in
the problem isn't really to store the data, it is how to make it nice to use.

As all the above mentioned libs, the same goes for coro, you can't just make a local variable and expect it to work

```c++
void some_game_object_behavior( coro* co, void*, void* )
{
    int my_counter = 0;

    co_begin(co);

    printf("whoo %d\n", ++my_counter);
    co_yield(co);

    printf("whoo %d\n", ++my_counter);
    co_yield(co);

    printf("whoo %d\n", ++my_counter);
    co_yield(co);

    co_end(co);
}
```

One might expect for this to print:

> whoo 1
>
> whoo 2
>
> whoo 3

But it will print 

> whoo 1
>
> whoo 1
>
> whoo 1

Why? If you read the article [coroutines in c](https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html) ( you 
did read it right? ) then you see the problem. The coroutines build on calling the function over and over until it
exits at the end. On each call it will initialize a local variable to 0, jump to the last position in the 
function, increment and print.

Thats not good now, is it? "Didn't you mention solving this with the stack" you might think and that is correct. 
`coro` has a pair of functions (actually a macros) called `co_locals_begin()`/`co_locals_end()` that is used like this

```c++
void some_game_object_behavior( coro* co, void*, void* )
{
    co_locals_begin(co);
        int my_counter = 0; // could be any amount of variables here!
    co_locals_end(co);

    co_begin(co);

    printf("whoo %d\n", ++locals.my_counter);
    co_yield(co);

    printf("whoo %d\n", ++locals.my_counter);
    co_yield(co);

    printf("whoo %d\n", ++locals.my_counter);
    co_yield(co);

    co_end(co);
}
```

These macros will declare a local struct and instantiate a reference to one of these called `locals`, and guess where
that reference is pointing, into the stack! This variable will only be allocated from the stack when entering the 
function for the first time, in the following calls it will just be fetched from the stack.

What this means is that we will have a struct that will be the same between all calls to our coroutine, that is not 
exposed to the calling code and take the burden of keeping track of this away from the caller.

It might be interesting to have a look at how the macro work as well, if we just expand it and look at what is 
generated.

```c++
void some_game_object_behavior( coro* co, void*, void* )
{
    struct _co_locals
    {
        int my_counter = 0;
    };
    if(co->call_locals == nullptr)
    {
        co->call_locals = _co_stack_alloc( co,
                                           sizeof(_co_locals),
                                           alignof(_co_locals));
        new (co->call_locals) _co_locals;
    }
    _co_locals& CORO_LOCALS_NAME = *((_co_locals*)co->call_locals);

    co_begin(co);

    // ... function ...

    co_end(co);
}
```

As you can see it just declare a local struct and put everything between `co_locals_begin()`/`co_locals_end()` into it. Then, 
if it is the first call, allocate data from the stack at the correct size/alignment. By placing the values in a struct we 
can put all of this in one declare call + we get size/alignment of the entire block for free from the compiler.

Also, since c++ now supports 'inline' initialization ( I guess there is a fancier name for it ) of member-variables we can
just write out or variables, set initial values and use `placement new` to initialize the values.

>
> Note to the C++:ers out there, currently no destructor is run on the locals but I guess that could be implemented in co_end()
> if needed.
> 


## sub-calls

With local variables out of the way, how about calling another coroutine function from the first one? Well, just to state the
obvious calling an ordinary function is just doing the call if someone was wondering. However say that you want to call a 
function that can, by itself, yield execution?

```c++
void some_game_object_sub_behaviors1( coro* co, void*, void* )
{
    // ... do stuff ...

    wait_for_timer(); // how this is implemented is up to the user ;)

    // ... do other stuff ...
}

void some_game_object_sub_behaviors2( coro* co, void*, void* )
{
    // ... do other cool stuff ...

    wait_for_timer(); // how this is implemented is up to the user ;)

    // ... DAMN THIS IS SOME COOL STUFF GOING ON HERE ...
}

void some_game_object_behavior( coro* co, void*, void* )
{
    co_begin(co);

    // ... function ...
    if(rand() % 1)
    {
        // some_game_object_sub_behaviors1()?
    }
    else
    {
        // some_game_object_sub_behaviors2()?
    }

    co_end(co);
}
```

Lucky for us we have the stack and `co_call()`! co_call() will allocate a `coro`-struct on the coroutine-stack and execute 
that just as any other coroutine. However it has some differences from co_init()+co_resume(). First of all, if it returns 
on the first call the caller will not yield, it will just continue. If it do yield it will be resumed by co_begin() of the
caller until it completes and then the caller will continue at the yield-point introduced by co_call().
The resume of the sub-call could also have been done in the top-level co_resume() call but I decided to do it from the
caller just to preserve the callstack for debugging.
When the sub-call completes the stack will be reset to the point where `co_call()` allocated its `coro`-struct.

The above code will then be

```c++
void some_game_object_behavior( coro* co, void*, void* )
{
    co_begin(co);

    // ... function ...
    if(rand() % 1)
        co_call(co, some_game_object_sub_behaviors1);
    else
        co_call(co, some_game_object_sub_behaviors2);

    co_end(co);
}
```


## call-arguments

So how about argument to coroutines? You guessed it, lets just pass them on the stack! Both `co_init()` and `co_call()` has
versions that accepts a pointer to an argument + size/alignment. Example

```c++
void some_game_object_move_on_path( coro* co, void*, int* path_index )
{
    move_me_on_path(*path_index); // maybe this will yield until movement is complete!
}

void some_game_object_behavior( coro* co, void*, void* )
{
    int path_to_take; // need to be declared before co_begin(), see below =/

    co_begin(co);

    // ... function ...
    path_to_take = rand() % 5;
    co_call((co_func)some_game_object_move_on_path, &path_to_take, sizeof(int), alignof(int));

    co_end(co);
}
```

The above will allocate space for the int and copy it onto the stack, and run `some_game_object_move_on_path`. The last argument
to a `co_func` will be its arguments, or `nullptr` if not used.
An alert reader might have noticed that the argument is copied onto the stack and that is true... and its copied by `memcpy` so 
keep the arguments simple. I guess you could add lots of c++ magic to move types and *yada yada* but I haven't needed that. IHMO
keeping types `memcpy`-able usually keeps code simpler and easier to work with!

>
> Note: there is also a version of co_call() and co_init() that deduce sizeof() and alignof() from arg.
>

Again, no destructor will be run for the argument!
Lastly note the cast to (co_func)! I guess that this is not everyones cup of tea but personally I'd rather take the cast there 
than in the function itself but I guess that is a matter of taste.


## Running out of stack!

So what happens when/if we run out of stack, for example allocating locals, args or doing a `co_call()`? coro will handle that
gracefully and yield the coroutine at a point before the point of allocation.
When this happen `co_resume()` will return as usual and the state can be checked by `co_stack_overflowed()` and that can then be
handled by the user.
The simplest might just be to ASSERT() but there is also `co_stack_replace()` if you feel fancy and want to grow the stack.

An example of how this might work

```c++

void run_me()
{
    uint8_t original_stack[128];

    coro co;
    co_init(&co, original_stack, sizeof(original_stack), some_func);

    while(!co_completed(&co))
    {
        co_resume(&co);

        if(co_stack_overflowed(&co))
        {
            void* old = co_stack_replace(&co, malloc(co.stack_size * 2), co.stack_size * 2);
            if(old != original_stack)
                free(old);
        }
    }

    if(co.stack != original_stack)
        free(co.stack);
}

```


## a note on 'waiting'

I mentioned above that I would like to be able to do things such as `wait_for( timeout, move_to )`. That is however something
that I have mostly left out of `coro`. Why you ask? Well, I can't really know how the user structures their code, how do they
want to update the coroutines etc.
If I would have supported something like that the lib would have become bigger and more 'opinionated', maybe it would have
needed an update and a manager of some kind etc. That would have brought the lib from being a simple building-block to something
more "framework:y" and that is not my intent. Maybe someday I'll do something like that but then it will be built upon `coro` not
built into it.
There is however one small helper for building this kind of code, and that is `co_wait()`. co_wait() is basically a `co_yield()` 
that also sets a flag on the coroutine. This flag is also propagated through the currently running coroutine-callstack so that the
user can do `co_waiting(&co)` at the top-level and see if it is waiting for something. This flag will be cleared on the next
call to `co_resume()`.
I think this little addition will be enough to build your own system on top of it if needed.


# Conclusion

First of all I need to say that I'm curious to see if it really works when I actually start to use it ;)
I.e. my next task is to actually use this for something productive ( nope haven't done that yet! ). IMHO it feels promising but
we'll see.

Secondly let's take a look at some pros/cons of this approach.


## Pro: No platform specific code

This is IMHO a big win for a smaller team ( in this case me ). No need to support low-level asm-code to switch stacks and save
registers. No worries about "what happens if we start porting to a new platform, can we do the same thing there?".


## Pro: Not much code

Also it is quite small ( at the time of writing 280 lines of code + 345 lines of comments ) and that is always a good thing
for maintenance and "ease of use". 


## Con: Easy to mess up locals

It is easy to mess up your local variables as it is second nature for every one of us to just declare a variable and expect it
to keep its value :)
My guess however is that you learn quickly and hopefully `co_locals_begin()/co_locals_end()` make it a bit easier.


## Con: Macro-heavy

Personally I'm not that afraid of macros but I know some are. Also in this case they require you to follow quite a few rules and
if you break them you end up with quite hard to understand errors. Again I think this is something that you learn but the more of you
on your team the more people that have to learn and the fudge up a few times.

An macro-related error that can be quite hard to understand if you are new to the code is this

```c++
void some_game_object_behavior( coro* co, void*, void* )
{
    co_begin(co);

    // ... function ...
    int path_to_take = rand() % 5;
    printf("%d\n", path_to_take);

    co_yeald(co);

    co_end(co);
}
```

This code looks perfectly valid but generates this on my currently installed gcc.

> test/test_coro.cpp: In function ‘void some_game_object_behavior(coro*, void*, void*)’:
> test/test_coro.cpp:43:16: error: jump to case label [-fpermissive]
>      co_yield(co);
>                 ^
> test/test_coro.cpp:40:9: note:   crosses initialization of ‘int path_to_take’
>      int path_to_take = rand() % 5;

Also stepping through the co_***-macros while debugging is far from pleasant, hopefully that is my problem and not
my users :)


## Con: no type-safety for arguments

Currently there is no real type-safety between args passed to co_call()/co_init() and the actual function used as a
coroutine callback. I would like to have that but I'm not really sure that it is doable? Any ideas for solutions
would be appreciated ( easy on the meta-programming please ) !


# Final note

I think this turned out nicely and hope that its something that might be useful for some of you. On a bigger team
with more resources, would I use this? Maybe? I think a full-scale stack-register switch might be a better solution
but that has its own caveats ( TLS-variables for example ).

Any thoughts or suggestions? I would love to hear about it!
Please hit me up on twitter or post in the coro issue-tracker! And remember, there will be bugs, there always is!

Check it out [https://github.com/wc-duck/coro](https://github.com/wc-duck/coro)!