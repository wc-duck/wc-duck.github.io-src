---
title: 'Why I prefer inline forward-declares in C++'
date: 2016-11-14
tags: ['code', 'c++']
---

Time for a short post on how I usually do the humble forward declare in C++. I guess this is not something new but it is something I usually do not see in
others code so it feels worth sharing.

So lets start of with just defining what we are talking about just to get everyone on the same page, we are talking about declaring only a class/struct name
to the compiler and not having to provide the entire class/struct declaration. Mostly used as a compile-time optimization or to handle circular deps etc.

A simple example:

```c++
// forward declare this struct.
struct a_forward_declared_struct;

struct my_struct
{
    a_forward_declared_struct* a_forward_declared_pointer;
};

void my_func( a_forward_declared_struct* another_pointer );
```

We're all used to see this kind of code, nothing new under the sun. I however like to write it like this:

```c++
struct my_struct
{
    struct a_forward_declared_struct* a_forward_declared_pointer;
};

void my_func( struct a_forward_declared_struct* another_pointer );
```

I don't know if inline-forward-declare is the correct term, but we'll use that until I'm told otherwise ;)

So what is better with this more verbose variant? Well, I have 2 reasons:

* It do not "leak" definitions into the global namespace.
* When usage is removed, so is the forward declare.

Lets go through them one-by-one.

It do not "leak" definitions into the global namespace.
-------------------------------------------------------

The big thing here is that we can't break other code by removing our forward declares. Say that you have this code:

<*header1.h*>
```c++
struct a_forward_declared_struct;

void my_func1( a_forward_declared_struct* another_pointer );
```

<*header2.h*>
```c++
void my_func2( a_forward_declared_struct* another_pointer ); // OH NOES, we forgot our forward declare!
```

*file.cpp*
```c++
#include "header1.h"
#include "header2.h"

#include "a_forward_declared_struct.h" // defining the actual struct.

void a_function( a_forward_declared_struct* ptr )
{
    my_func2( ptr );
}
```

Now we work with our code and refactor my_func1() to no longer take a pointer to a `a_forward_declared_struct` and removing the forward declare.
By doing this we break file.cpp since "header2.h" is now "incomplete". This might not be a big issue in a smaller code-base but in a bigger one
(especially one using unity-builds, batch-builds or whatever you want to call them ) this can pop up on another colleagues machine after you have
submitted your code.

If instead you would have used inline forward-declares header2.h would never have compiled to begin with so the initial implementer would not have
missed the needed declarations.


When usage is removed, so is the forward declare.
-------------------------------------------------

The second improvement over the "ordinary" declarations is the fact that they are automatically removed when they are no longer needed since they
are part of the actual code.

How many times haven't we all found forward declares that no one uses ( and no one want to remove due to point 1 ;) ).

*Some thing like:*

```c++
class vec3;

struct i_have_no_vec3
{
    int apa;
    int kossa;

    // I had a vec3 here a few years ago!
};
```


Final words
-----------

Are there any drawbacks? Well, except for being slightly more verbose, the only one I can think of is that it do not work together with namespaces.
For me that is no real problem since I really do not like namespaces to begin with ( topic for another rant/blog-post? ) but if you do this tip
is not as useful. If you mix and match I would still recommend using inline forward-declares where possible and fallback to namespace:d declares
when you have to.

```c++
namespace foo
{
    class bar;
};
```

Do you agree, am I totally wrong? Feel free to tell me on twitter!
