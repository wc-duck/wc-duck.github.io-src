---
title: "Simple Polling With Lambdas"
date: 2022-08-14T15:21:53+02:00
tags: ['code', 'c++', 'api-design']
draft: true
---

rework to something like "polling and callbacks?"

Write about being able to run:

```c++
void poll_me(the_system sys)
{
    some_other_system other = get_other_system();

    the_system_poll(sys, [&some_other_system](const the_system_msg& msg){
        // do things with message!
    });
}

```

https://github.com/wc-duck/dirutil and dir_walk()... callback to prefer as that will not decide on how and what is going to be done with the result + not forcing a way to work on the user.

not needing the extra struct etc.
