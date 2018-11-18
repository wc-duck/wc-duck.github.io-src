Title: "ProtoThreads" with a twist.
Date: 2018-11-20
Tags: code, c++, coroutines

For a long time I'v been interested in trying out to run game-specific/entity-specific code in coroutines. 
Something like the following.

```c++
void some_game_object_behaviors( entity ent, ... )
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
            wait_sec(ent, 0.5); // do nothing for 2 seconds and yield the coroutine for that duration.
        }
    }
}
```

The above example is slightly simplified but I hope that it get the point across. I think that way of writing 
one-off gamecode might be a nice thing, especially when adding wait_for_any() and wait_for_all() etc.

So when I finally decided to take a stab at trying that out I started out by looking at how to implement the
actual coroutines. There are some libraries out there that you can use to implement coroutines in c++ such as:

- [libaco(https://github.com/hnes/libaco)]
- [libdill(http://libdill.org/)]
- [libmill(http://libmill.org/)]

Both libdill and libmill feel a bit to 'opinionated' on how to structure my code for my application so libaco
sparked my interest. I think it looks really nice but there is a big BUTT, no windows support yet =/ I do
most of my development on Linux but throwing Windows support out of the "window" *badumtish* is not something
I want to do.
According to the issue-tracker it is in "the pipe" but it is not supported now.

This lead me to fire of a question on twitter about alternatives where @RandyPGaul pointed out something that I
had looked at before but totally forgotten about, coroutines/protothreads based on "duffs-device".

Since there are already good descriptions of this on the webs-of-the-inter I'll just link to the original 
article here and wait until you have read it ( if you haven't already ).

[coroutines in c(https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html)]

Read it yet? Good!

Here are a few other links to libs that implement these kind of coroutines for you if your interested.

- [protothreads(http://dunkels.com/adam/pt/)]
- [zserge/pt(https://github.com/zserge/pt)]
- [Randy Gauls version(https://github.com/RandyGaul/cute_headers/blob/master/cute_coroutine.h)]

What I like about this solution is that it is "just code" so it should in theory work on any platform without
platform-specific code etc. I should also work with emscripten ( that I shall get running any day now!!! ;) ).

There are however things that I am missing from these otherwise fine libraries.
A major one is the based on how I plan to use them, I plan to have all my "behaviors" run one coroutine and 
have some kind of simple "scheduler" run them. Something simple as having all "active" coroutines in a list,
remove them from the list when waiting for something, and update them in a loop. However doing that with the
above libs would require me keeping track of what functions are associated with each coroutine.

Also local variables/state is not handled by the above libs and would need to be handled by passing in some
kind of state-struct, that would need to be different for each "behavior" and also be tracked by the above
mentioned system.

2 of the 3 libs also fails to handle calling another coroutine-function from within a coroutine and by that
having the sub-call control the state of the top-level coroutine. For example if a sub-call does a yield or
wait the entire call-hierarchy should do the same (cute_coroutine.h solves this for a fixed depth of sub-calls).

So what do you do when you have an interesting itch to scratch? You scratch it of course :)


# Solving the issues!

As any decent NIH-addict I decided to try for myself what I could do and came to the conclusion that all
the above issues can be solved by a small stack to each coroutine, i.e. almost do what the compiler does manually!

Introducing my boringly named coroutine lib, [coro(https://github.com/wc-duck/coro)].

As mentioned above the only real difference to the above mentioned libs are that each coroutine in coro MAY have
a stack associated with it where the system itself can push data and reset when a coroutine exits.  

>
> Warning for you C-all-the-way people, there be some usage of C++ in this piece of code! But I guess it wouldn't
> be that hard to C:ify the lib if there is enought requests!
>

SOMETHING ABOUT co_begin()/co_end()/co_yield() and 'struct coro*'

So how will this solve the above mentioned issues?

## General coroutine update

Well, this isn't solved by the stack, this is just solved by introducing a struct for the coroutines :) Now we have
that out of the way.


## Local variables

Now lets get to the stack-part and lets start with local variables. When we have a memory-area to store data in that
the problem isn't really to store the data, it is how to make it nice to use.

As all the above libs the same goes for coro, you can't just make a local variable and expect it to work such as

```c++
void some_game_object_behaviors( coro* co, void*, void* )
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

Why? If you read the above mentioned article [coroutines in c(https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html)] ( you 
did read it right? ) then you see the problem. The coroutines build on calling the function over and over until it exits at the end
and on each call it will initialize a local variable to 0, jump to the last position in the function, increment and print.

Thats not good now, is it? "Didn't you mention solving this with the stack" you might think and that is correct. 'coro' has a function
(actually a macro) called co_declare_locals() that is used like this

```c++
void some_game_object_behaviors( coro* co, void*, void* )
{
    co_declare_locals(co,
        int my_counter = 0; // could be any amount of variables here!
    );

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

This macro will declare a local struct and instanciate a reference to one of these called `locals`, and guess where that reference
is pointing, into the stack! This variable will only be allocated from the stack when entering the function for the first time, in
the following calls it will just be fetched from the stack.

This means that we will have a struct that will be the same between all calls to our coroutine that is not exposed to the calling
code so we take the burden of keeping track of this away from the user.

It might be interesting to have a look at how the macro work as well, if we just expand it and look at what is generated.

```c++
// declared in coro.h but copied here for clarity
template< typename T >
static inline T* _co_declare_locals(coro* co)
{
    if(co->call_locals == nullptr)
    {
        co->call_locals = _co_stack_alloc(co, sizeof(T), alignof(T));
        new (co->call_locals) T;
    }
    return (T*)co->call_locals;
}

void some_game_object_behaviors( coro* co, void*, void* )
{
    struct _co_locals
    {
        int my_counter = 0;
    };
    _co_locals& locals = *_co_declare_locals<_co_locals>(co);

    co_begin(co);

    // ... function ...

    co_end(co);
}
```

As you can see it just declare a local struct and copies everyting from the second argument of co_declare_locals() into it. Then
we have a helper function to allocate this if it is the first call. By just placing the values in a struct we can put all of this
in one declare call + we get size/alignment for free from the compiler.

Also, since c++ now supports 'inline' initialization ( I guess there is a fancier name for it ) of member-variables we do not have
to generate a constructor but we can still set initial values for our locals as we would any other local variable. Later the function
uses `placement new` to initialize the values.

>
> Note to the C++:ers out there, currently no destructor is run on the locals but I guess that could be implemented in co_end()
> if needed.
> 


## sub-calls

With local variables out of the way, how about calling another coroutine function from the first one? Well, just to state the obvious
calling an ordinary function is just doing the call if someone was wondering. However say that you want to call a function that can,
by itself yield execution, such as this

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

void some_game_object_behaviors( coro* co, void*, void* )
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

Lucky for us we have the stack and `co_call()`! co_call() will allocate a `coro`-struct on the stack and execute that just as any
other coroutine. However it has some diffrences. First of all, if it returns on the first call the caller will not yield, it will just
continue. If it do yield it will be resumed by co_begin() until it completes and then the caller will continue after the co_call()
that triggered.
When the sub-call completes the stack will be reset to the point where `co_call()` allocated its `coro`-struct.

The above code will then be

```c++
void some_game_object_behaviors( coro* co, void*, void* )
{
    co_begin(co);

    // ... function ...
    if(rand() % 1)
    {
        co_call(co, some_game_object_sub_behaviors1);
    }
    else
    {
        co_call(co, some_game_object_sub_behaviors2);
    }

    co_end(co);
}
```


## call-arguments

So how about argument to coroutines? You guessed it, lets just pass them on the stack! Both `co_init()` and `co_call` has versions
that accepts a pointer to an argument + size/alignment. Example

```c++
void some_game_object_move_on_path( coro* co, void*, int* path_index )
{
    move_me_on_path(*path_index); // maybe this will yield until movement is complete!
}

void some_game_object_behaviors( coro* co, void*, void* )
{
    int path_to_take; // need to be pre-declared, see below =/

    co_begin(co);

    // ... function ...
    path_to_take = rand() % 5;
    co_call((co_func)some_game_object_move_on_path, &path_to_take, sizeof(int), alignof(int));

    co_end(co);
}
```

The above will allocate space for the int and copy it onto the stack, and run `some_game_object_move_on_path`. The last argument
to a `co_func` will be its arguments on `nullptr` if not used.
An alert reader might have noticed that the argument is copied and that is true... and its copied by `memcpy` so keep the arguments
simple. I guess you could add lots of c++ magic to move types and yada yada but I havn't needed it and personally I feel that the
code just is simpler if my types can be copied by `memcpy`!

>
> Note: there is also a version of co_call() and co_init() that deduce sizeof() and alignof() from arg.
>

Again, no destructor will be run for the argument!
Also not the cast to (co_func)! I guess that this is not everyones cup of tea but personally I'd rather take the cast there than
in the function itself but I guess that is a matter of taste. `co_func` declares the argument as `void*`.


# Conclusion

So in conclusion, what can be said? Well first of all I'm curious to see if it really works when I actually start to use it ;)
I.e. my next task is to actually use this for something productive ( nope haven't done that yet! ) but it feels like it is 
something that will work well! ( insert "Narrator: it didn't end well"-joke here )

But let's just take a look at some pros/cons to end this post.


## Pro: No platform specific code

This is IMHO a big win for a smaller team ( in this case me ). No need to support low-level asm-code to switch stacks and save
registers. No thoughts about "what happens if we start porting to a new platform, can we do the same thing there?".


## Pro: Not much code

Also it is quite small ( at the time of writing 435 lines of code with quite a bit of comments ) and that is always a good thing
if you just want to try it out and see if it feels good, if it does maybe move on to a "heavier" solution if needed?


## Con: Easy to mess up locals

It is easy to mess up your local variables as it is second nature for every one of us to just declare a variable and expect it
to keep its value :)
My guess is however that you learn quickly and hopefully `co_declare_locals()` make it easier.


## Con: Macro-heavy

Personally I'm not that afraid of macros but I know some are. Also in this case they require quite a bit of things and end up
producing quite hard to understand errors if you fudge up. Again I think this is something that you learn but the more of you
on a team the more people to learn and the more of you to fudge up a few times.

An macro-related error that can be quite hard to understand if you are new to the code is this

```c++
void some_game_object_behaviors( coro* co, void*, void* )
{
    co_begin(co);

    // ... function ...
    int path_to_take = rand() % 5;
    printf("%d\n", path_to_take);

    co_yeald(co);

    co_end(co);
}
```

This code looks perfectly valid but generates this on installed gcc.

> test/test_coro.cpp: In function ‘void some_game_object_behaviors(coro*, void*, void*)’:
> test/test_coro.cpp:43:16: error: jump to case label [-fpermissive]
>      co_yield(co);
>                 ^
> test/test_coro.cpp:40:9: note:   crosses initialization of ‘int path_to_take’
>      int path_to_take = rand() % 5;


## Con: no type-safety for arguments

Currently there is no real type-safety between args passed to co_call()/co_init() and the actual function used as a
coroutine callback. I would like to have that but I'm not really sure that it is doable? Any ideas for solutions
would be appreciated ( easy on the meta-programming please ) !


# Final note

Any thoughts or suggestions? Is this something that might be useful for you, I would love to hear about it!
Please hit me up on twitter or post in the coro issue-tracker! And remember, there will be bugs, there always is!