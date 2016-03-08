Title: Registering command line arguments
Date: 2016-02-27
Tags: code, c++

I really like using command line arguments. I think that it is a flexible way to interact with and configure my games/engine.
It is for example easier to just add a `--log-verbose=resource` to set all logging in the "resource"-domain to verbose or
`--memory-enable-stacktrace=render` to enable save of stacktraces for all allocations done in the "render"-allocator than to
edit some config-file somewhere. At least for things such as the ones mentioned above, that is only set once in a while.

> Note: It's also a simple replacement for config-files, but that is something for a later blog-post ;)

However it seems like there's always one problem, how to register supported command-line arguments to show --help and 
check that arguments are correctly specified?
In this blog-post I'll outline a solution that I have found works really well for me. It has its drawbacks but that is usually
the case with any solution to any problem ;)


What do I want to achieve?
--------------------------

Let's make a quick list over what I want from my system.

* Different systems to be able to register their supported command line arguments in a simple fashion.
* Automatic --help generation ( I always forget what flags are there etc, --help to the rescue )
* Systems that register args should be able to assume that all flags are valid when they get the args.


How I do it
-----------

First of all I let all systems parse their own argc/argv, in other words I just pass each system a reference to argc/argv.
This is done in different ways, but usually something like this:

```c++
    log_ctx_t logger = log_ctx_create( /*... some param ... */, argc, argv );
```

or this:

```c++
    renderer_create_info create_info;
    // ... other params ...
    create_info.argc = argc;
    create_info.argv = argv;

    renderer_t r = renderer_create(&create_info);
```

The systems get access to a const argc/argv and its their job to parse them by them self. For this I use ( shameless self-promotion comming up ) 
this getopt-parser https://github.com/wc-duck/getopt. But how does that tie in with our earlier demands on the "system".
Well, lets use some thing that some one consider the c++-equivalent of swearing in church, global constructors! Lets introduce
a simple helper-class and macro `GETOPT_ARGS_REGISTER()`.

```c++
    struct __getopt_args_register
    {
        __getopt_args_register( const char* t, const getopt_option_t* opt )
            : next( first )
            , options_title( t )
            , opts( opt )
        {
            first = this;
        }

        static __getopt_args_register* first;

        __getopt_args_register* next;
        const char*             options_title;
        const getopt_option_t*  opts;
};

#define GETOPT_ARGS_REGISTER( options_title, options ) \
	static __getopt_args_register JOIN_MACRO_TOKENS( __getopt_reg, __LINE__ )( options_title, options )
```

And we use this as follows

```c++
    static getopt_option_t options_list[] = {
        { "log-info",      0x0, GETOPT_OPTION_TYPE_OPTIONAL, 0x0, 'i', "set log-level info, globally if no domain is specified.",   "DOMAIN" },
        { "log-error",     0x0, GETOPT_OPTION_TYPE_OPTIONAL, 0x0, 'e', "set log-level error, globally if no domain is specified.",  "DOMAIN" },
        { "log-warning",   0x0, GETOPT_OPTION_TYPE_OPTIONAL, 0x0, 'w', "set log-level warning, globally if no domain is specified", "DOMAIN" },
        { "log-verbose",   'v', GETOPT_OPTION_TYPE_OPTIONAL, 0x0, 'v', "set log-level verbose, globally if no domain is specified", "DOMAIN" },
        { "log-callstack", 0x0, GETOPT_OPTION_TYPE_OPTIONAL, 0x0, 'c', "log callstacks together with messages, globally if no domain is specified", "DOMAIN" },
        { "log-domains",   0x0, GETOPT_OPTION_TYPE_NO_ARG,   0x0, 'd', "log all available domains as they are discovered." },
        GETOPT_OPTIONS_END
    };

    GETOPT_ARGS_REGISTER( "log", options_list );
```

What the above macro basically does is on old trick, building an global linked list of __getopt_args_register when running global constructors that 
can be accessed via `__getopt_args_register::first`.

When we have this info it is an easy thing to just loop over all registered args and do the error checking and --help generation etc without the systems
having to know about it. I usually do this as a really early part of `int main( int argc, const char** argv )`.
Also notice that the registered options is the same type that is used by the getopt-library so that the same setup can be used during arg-parse. Keeping the
registered args defined in one place and one place only.

One of the things I like most with this is that the registering is done link-time, so linking to a static library, in my case render, debug or vfs ( to 
mention a few ) auto-registers its options. So if a lib is not used/linked, no options is registered.


Drawbacks
---------

Well there are some of course. This will not work well together will DLL:s since the main .exe and the .dll:s will get their own instance of 
`__getopt_args_register::first` and the ones in the dll will not be accessible from the exe. It could  be solved by "pulling out" `__getopt_args_register::first` 
from each DLL and manually "link" them together but that is not something I have done or have had any need for.

Also there is the problem of colliding flag-names and that is best solved by just not sharing flag-names, I prefix my flags by system. In some cases you might even
want colliding flag-names where you have flags that should be used by multiple systems. Not sure if it is a good idea, but it is definitely something that can be
done.


Conclusion
----------

This is a technique that has served me well for this purpose and the "global linked list created with global constructors" could be a useful tool in your toolbox 
when writing c++. It need to be used restrictively, but at least for this purpose it has not been any problems for me.
