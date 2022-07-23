---
title: 'A story about an unexpected ABI break'
date: 2017-11-15
tags: ['code', 'c++', 'war-stories']
---

This is the story of an unexpected ABI break that I thought would be worth documenting.

At Avalanche we use a small class wrapping 32bit hashes called CHashString, it is basically just a wrapper around
uint32_t and one should be able to treat it as a uint32_t in code except for operations that do not make sense on a hash-value.

Why would you want a class like this you might ask, well we use it for adding a `const char* c_str()`-function that can be
used in logging and also we use it to add custom natvis-support in visual studio so that you can just hover a CHashString
and have a lookup of the hash-value performed.

However this is not about how we use it, but how things can break in unexpected ways.

As a bit more background it should be mentioned that a big part of Avalanches internal libraries are distributed pre-compiled
to our game-projects with all the positives and negatives that brings with it. For example when deploying a middle-version fix
we "promise" to our projects that we do not break the ABI of the library, i.e. you should  be able to link with any 5.x.x if you
only depend on 5.x.x.

Our CHashString was basically defined something like this

```c++
class CHashString
{
    uint32_t m_Hash;
public:

    explicit CHashString(uint32_t hash)
        : m_Hash(hash)
    {}

    CHashString& CHashString(CHashString& other) { m_Hash = other.m_Hash; }

    ... more constructors ...

    ... more functions ...

    bool operator ==(const CHashString other) const { return m_Hash == other.m_Hash; }
}
```

As an earlier brain-fart/didn't-think-about-that someone added the copy-constructor, something that made this class non-trivially-copyable,
i.e. [std::is_trivially_copyable](http://en.cppreference.com/w/cpp/types/is_trivially_copyable) would fail.
This would lead to putting it in some containers would not make it as performant as it should have been ( and it couldn't even live in some containers ).

As the fixy kind of guy one am I said to my self "I can fix this, how hard can it be?". We decided that we should just remove that un-needed
copy-constructor since a default copy-constructor would do the same thing. Said and done, be gone with you!

check-in!

deploy!

go for coffee!

...

...

...

Come back to crashing projects!

Sad panda!

Luckily for me it is easy to lock down versions of distributed libs so we could quickly fix the issues on the projects by locking down to the 
previous version.

At this time we are scratching our heads quite a bit, our thinking being that even if one part of the code calls the old way of copy-constructing
an object the end result should be the same in memory... And to make things worse, most things seem to work.

Time to bring out the debugger!

I build a debug-build of one of our projects and after some time, thanks to some log-messages, I find a spot that behaves REALLY fishy!

```c++
CHashString one_hash(0x12345678);
CHashString another_hash(0x12345678);

// ... later in the code ...

if( one_hash == another_hash )
{
    do_stuff();
}
```

do_stuff() is NEVER called!?! I.e. stuff is never done, and we all know that our job is mostly about getting stuff done ;) 

The debugger tell me that the 2 values are the same! What is going on here?
After checking the assembly and stepping the code quite a few times we can determine that when we removed the copy-constructor MSVC decided
that it should pass CHashString in register instead of by pointer to stack. So what our `operator==` that take CHashString by-value ends up doing is 
comparing one of the hashes to half the stack-address of the other variable :)

This since this code is defined in one of our pre-compiled libraries and the implementation of `operator==` ends up in our main executable that
is built from latest the lib and the exe disagrees on how to pass values to the function!

As expected this works in a release build where the code is inlined, but in that case we had other functions where how CHashString was passed was an issue.

What can we learn from this? ABI-issues can show its ugly face when you least expect it and compilers do the darnedest things!

Well, that was part of my day, how was yours? Feel free to hit me up on twitter or something if you want to give me a comment about this!
