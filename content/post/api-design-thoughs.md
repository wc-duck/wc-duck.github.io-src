---
title: "Api Design Thoughs"
date: 2022-09-03T08:36:05+02:00
tags: ['code', 'c++', 'api-design']
draft: true
---

* root post go here
* written from a perspective of an game-engine developer with code running in multiple active projects at once (hard to go around and just change all uses in one go due to state of development).
* focused on c/c++ but many points goes for other languages as well.

* don't take this as hard rules, this is things that seems to work well in most cases but there is ALWAYS exceptions!

* this will not be a long list of "noexcept"-this, "rule of 3... ehhh... 5?... 7?"-that, "const"-here, "move"-there!

* Key fact in api-design, "you will get it wrong!" most of these recomendations are here to make it easier to course-correct!
    * Expose as little as you can... it is ALWAYS easier to "just expose one more thing" than it is to "revoke" things that wasn't really right (see "you will get it wrong!")
    * c-style api:s

* Key fact in api-design, "the user of your api have all the details, you don't", the user know their threading model, how they work with memory when and where they have CPU-time to do what... you don't! (post on memory-management and threading! (prefer allocators, prefer-update-functions over self-created threads, prefer utils if needed))
    * don't force a "type" on the user. Prefer size+ptr over std::vector, my_lib::array, QString etc. (this will give me some heat in the twitter-verse and from some collegues ;) ). This since you don't know where the user gets its data from, it could be from memory, from a file and you don't want to force storage upon a user.
* Key fact in api-desgin, "be consistent" (example of callbacks being called sometimes, "Carly Rae"-callbacks... as in "call me... maybe?") (prefer poll over callbacks and dispatchCallbacks() over "call from somewhere")

* Simple POD-style core types over RAII, you can always build RAII on top of simple data, not the other way around! Again, don't assume you know what your user need, they probably know better! They want ref-counting on your data-types, they can add that on top, you do not have to do it for them!

* just to annoy some collegues, "getters is the most overrated crap ever to leak into 'best practices' ever!"... no you will most likely never use the "benefits", no you don't have to "protect" your users from every way they can ever shoot themselfs in the foot and you will only produce slower debug-builds and angry old farts like me!

* links to all sub-posts go here
* Part1 - yada yada


Disclaimer, I'm old and grumpy, don't see this as the truth, see this as one man's opinions and a base for discussion. Hopefully I will learn something and maybe you will get some new ideas/thoughts as well!

Written from the pow of an game-engine dev working on an in-house engine used by projects I have full access to or private engine. Changes to usercode can still be problematic!

Optional talk-title "the user (almost) always knows best... except when they don't!"

Common knowledge, skip this
• No globals (exceptions will be covered)
  - unclear deps
  - creation destruction problems
  - globals are only allowed if they can be removed and the application still stays the same for the end-user.
• don't be smart
  - write once, debug multiple times
• enums over bools
  - readability

Clear ownership is REALLY important!
• One place of construction/destruction is easier to debug/reason about/change
• shared_ptr is just a lack of design...
• Memory management is only hard if you do it "everywhere", focus that to specific points
• inspecting a mysys->active_instances is WAY easier than trying to find all active pointers owned by users!

Globals can be needed but with rules.
• Don't allocate memory at construction
• can be removed and the app keeps working (logger, assert-handler, tweak-variables)

Think about extension point, add value to struct, new out event, new enum value. Easy to add without breaking API.
Don't code for "the future" but give a quick thought about what you might need and where that would go.

Threads
• The user (almost) always knows best!
  - threads, fibers, jobsystem, single thread
  - share threads for multiple systems
  - if the API do not dictate this it can support all of the above models

Memory
• The user (almost) always knows best!

Structs over parameters
• Easier to upgrade... If you are not confident that parameters will not change. max(a,b) would never benefit from a struct.

Expose as little as possible!
• Keep secret is easier to change

Trust RVO, leads to nicer API:a (contradiction? IMHO move was a mistake!)

Callbacks
• The user knows best, expose pollNow(), even when underlying API don't support that try and provide that to your users. (Event-queue?)

Provide utilities but build around low-level primitives, RAII is useful, but not always the right choice. You can always build RAII ontop of "raw" types.
• Adds flexibility
  - HThreadMutex vs SThreadMutex
  - callback + userdata vs poll([&whoop](){})

Don't take decisions for the user std::vector vs ptr+size, std::***ptr in interfaces

Config Marcos
• Good, you never know when a game need to ship "final" with logging
   - prefer #define APA_ENABLED that allows override
 • Bad when introducing many buildtargets define vs link!

Decisions
• Where
• What
  - will the user ever change this? If not take that decision!
• Don't impose restrictions on containers (ptr + size over vector)

My thoughts on api-design
  • design as if you will make mistakes, how to make an api where it is easier to course correct!
  •   • Never think that you know better than your users
    • Memory alloc
    • threading
  • Provide a utility layer but expose smaller building block for the case when your users know their problem better than you
  • configurable if good, not needing it is better! (enums from dl)
  • be explicit on what is done when, prefer a "poll" that dispatches events/callbacks over "sometime on some thread"
  • can the user handle threading? Let them! Provide utils to make it easy to try out.
  • prefer parameter-structs over arguments to functions... In most cases!
  • never ever ever ever use globals... Except when you have to! (Can it be removed without altering the program?)
