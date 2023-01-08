---
title: "A Zig Diary"
date: 2023-01-08T19:34:19+01:00
tags: ['code', 'zig']
---

As it turned out I happened to help out with fixing a space to host a [zig meetup](https://www.meetup.com/zig-stockholm/) here in Stockholm at the place where I work. However I haven't written a single line of zig in my life... I felt that it might be worth doing something about that :D

> If you don't know, [zig](https://ziglang.org/) is a new systems programming language!

I have found zig quite intriguing for a while now but I haven't had the time to look into it so this sounded like an as good excuse as any!
I'll try something new with this post and just write as I go and document my success/failure/reflections, this might make it a bit "rambly" :)


# What to build?

First off, I needed to decide on what to try and build just to have a goal and not just do some aimless "twatting about", something small but that still produce something. I decided on a simple image to ascii converter. There are a multitude of these around that will probably be better than this one but who cares!

I decided on this as its small, does a bit of io, does a bit of command-line, a bit of "algorithm work" and probably some c-interop, and it could probably be optimized a bit if I want to.

Lets go!


# Step 1... build something? 

I needed to get something building! The first instinct said "Let's hit google and search for '[zig how to get started](https://www.google.com/search?channel=fs&client=ubuntu&q=zig+how+to+get+started)'".

5 minutes later I had the compiler and toolchain installed, initialized my project and have something running... impressive!

A bit more info might be interesting to you readers! So my google search turned up [https://ziglang.org/learn/getting-started/](https://ziglang.org/learn/getting-started/) as the first result, that in turns pointed me to the [downloads page](https://github.com/ziglang/zig/wiki/Install-Zig-from-a-Package-Manager).
As I'm on ubuntu I decided to do the 'snap' install via:

> snap install zig --classic --edge

After this the getting started page told me about `zig init-exe` and `zig build run` and I was off to the races!


# Step 2... syntax highlighting!

Can't write code without a decent editing environment, so let's see what we can do about that?

I know that the "getting started" page talk about this, but vscode as I use as an editor at home already points me to the marketplace, lets start there.

[![](/images/a-zig-diary/vscode-help-with-zig.png "vscode marketplace")](/images/a-zig-diary/vscode-help-with-zig.png)

Installing "Zig" and "Zig Language Server (zis) for VSCode" and lets see what happens!

Another 5 min and syntax is highlighting and some rudimentary auto-completion is in place!


# Step 3... time to write something by myself.

Reading the initial generated `main.zig`, clear and concise but short. Nice that there is a test embedded in the generated code as well. I have never been a fan of having tests and implementation in the same file but we'll see how that turns out, especially since testing seems builtin to the language. I guess there is nothing that force me to have the test in the same file as implementation?

Trying to uncomment the `.deinit()` in the test to see what happens.

```zig
    var list = std.ArrayList(i32).init(std.testing.allocator);
    // defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
```

Good to get an early introduction to memory-handling this early, otherwise it might have come as a surprise. I'm usually a fan of manual memory-management but also working in c++ all day long at work might make this something to get used to. Also what are these `try`-statements, `defer` I get (and like!), but `try` is a bit unclear, might have been good with a bit of clarification directly in the generated file? Just a quick comment like:

```zig
    // adding a 'try' here will do x/y/z.
    // Read more at 'https://ziglearn.org/chapter-1/#errors'
```

So, what is the first thing that I need? I'll need to read a data from stdin and or via an `-i`-flag. First I thought that I should use some lib, but I'm learning zig now, just do the simplest thing you can yourself in this simple case!

So getting argc/argv? A few questions and reflections popped up.

Debug-printing something and getting this callstack is kind of bad, sure it tells me what is wrong but it gives me an error in the standard-lib and not in my code where I introduced the issue. It also hides my line from the trace, so I can't even see the line where I introduced the error!

At least it mentions `-freference-trace`, but as a user this might not be what I want :)

```shell
wc-duck@WcLaptop:~/kod/zig_img_to_ascii$ zig build run
/snap/zig/6044/lib/std/fmt.zig:86:9: error: expected tuple or struct argument, found [:0]const u8
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
referenced by:
    print__anon_4373: /snap/zig/6044/lib/std/io/writer.zig:28:27
    print__anon_3784: /snap/zig/6044/lib/std/debug.zig:93:21
    remaining reference traces hidden; use '-freference-trace' to see all reference traces
```

Issue introducing this was just me being used to "c" for a long time and writing:
```zig
std.debug.print("{s}\n", arg);
```

and not:
```zig
std.debug.print("{s}\n", .{arg});
```

This line is the most important thing to me as a user, hence it should be mentioned in the actual error!

Next up, can I run `zig build run` with command line args? Couldn't find anything in the huge `zig --help`. Also tried to do something as `zig run help` to just get help on `run` but no. After a bit of guessing I found that `zig build run -- --arg --go --here` works and pass all args after `--` to your app. Not really unexpected as it is kind of a known idiom , but also not documented... as far as I can tell?

`std.debug.print()` requires args and can not just print a string... unexpected. Forcing a `.{}` is not really ergonomic :(
    
```zig
std.debug.print("I just want some output\n", .{}); // :(
```

Comparing strings threw me, as many others it seems, off as there are no standard way doing it... having to define your own `streq()` seems a bit excessive as it is not an unheard of operation!

```zig
fn streq(comptime s1 : []const u8, s2 : []const u8 ) bool {
    return std.mem.eql(u8, s1, s2);
}
```
Sure, that is just a wrapper around `std.mem.eql()`, comparing strings is far from trivial if you are to do it "correctly" etc... 

At the time of writing this post I found that there is the `std.ascii` module, but that do not have a simple `.eql()`, only `.eqlIgnoreCase()`. I guess that comes from "there should be one, and only one way, of doing one thing" and `std.mem.eql()` already exists but I would argue that that is taking it a bit to far. From my point of view an `std.ascii.eql(s1, s2)` would provide more clarity at the callsite + making it easier to discover other "ascii"-functions etc.

But after some 'faffing about', commandline is parsing, probably really badly :)

```zig
const CmdLineArgs = struct {
    input: ?[]const u8 = null,
};

fn parse_args(alloc : std.mem.Allocator) CmdLineArgs
{
    var args = try std.process.argsWithAllocator(alloc);

    // skip my own exe name
    _ = args.skip();

    var out = CmdLineArgs{};

    while(args.next()) |arg| {
        if(streq("--input", arg) or streq("-i", arg)) {
            out.input = args.next();
        }
        else if(streq("--help", arg) or streq("-h", arg)) {
            std.debug.print("HEEELP\n", .{});
        }
        else{
            std.debug.print("unknown arg {s}\n", .{arg});
        }
    }

    return out;
}
```

# Step 4... loading images and c-interop

Time to load a source-image, and as this is not an exercise in writing an image-loader and zig prides itself with c-interop, lets drop `stb_image.h` in there and get that running!

This actually turned out a bit harder than expected, mostly due to how `stb_image.h` is implemented with having to define `STB_IMAGE_IMPLEMENTATION`. This forced me to add an `stb_image.c` that just include `stb_image.h` and set the define.

This lead me down into the zig-buildsystem and `build.zig` and add this... pretty sleek!

```zig
    exe.addCSourceFile("src/stb_image.c", &[_][]const u8{"-std=c99"});
    exe.addIncludePath("src");
    exe.linkLibC();
```

But how did I find out how to do this, it basically took googling "stb_image zig" and ending up with [Andrew:s tetris-implementation](https://github.com/andrewrk/tetris) on github. Maybe not the best and clearest documented thing. At the other hand you probably shouldn't need to officially "document" how to use a specific lib from zig :D

However a short blog-post about it, and only it, would be useful... maybe for [kihlander.net](kihlander.net)?

Left the project for a few days... 


# Step 5... produce some output!

Unfortunately my note-taking was, to put it mildly, "lacking" under the actual implementation of the to-ascii work. But it is mostly a few loops and I'm pretty sure that you can find better resources on how to convert an image to ascii that this blog :)

In short, convert image to grayscale, use average in a block of x*x pixels to map into list of character.

But I do have "The king of all cosmos" as ascii "art" at least :)

Turning this:

[![](/images/a-zig-diary/the-king.jpg "the king")](/images/a-zig-diary/the-king.jpg)

Into this:

```
.......;:.........;x:,oo..:%;.;o,................ 
..................o%;,%x,.:%o.o%:.................
..................;x:,oo,.:x;,;x:.................
..................:o,,::,,,o,,:o...........,,.....
..................;%:,xo,,:%;,o%,..........:,.....
.................,;x;:%%;,o%o:ox:.................
.................,oxoo%#o:%%%;%x:,................
..........,.....,,oo%x%#%x##xxxo;,...........,,...
.........,;,....,,xxoo%#@@@#xooxo,..........,;;...
........:oo;,...,:xxoo%#@@##xooxx,.........,;oo:..
........,;o;,..,,;xooo%#@@##xooxx,,.........:;;,..
,.,....,.:;,..,,,;xooo%#@@##xooxx,,,.........:,...
,,,,,,,,,,,,,,,,,oxxoo%#@@##xooxx:,,,,,,,,,,,,,,,,
;;;;:;;;;;::;;:;;xxooo%%###%xooox;::::::::::;:::::
;;oo;;oo;;;;;;;;;;oo;;;;ox;;;;;oo:;;;;;;;;;;o;;;;;
ooooo;oo;;;;;;;;;:x#%xo;ox;;ox%%o:;;;;;;;;;oo;;ooo
oo%xoooo;;;;;;;;:;%###%xoxox%%##x:;;;;;;;;;oo;;oxo
ooxoooooxxxxxxxo:o####%%%%%%%###%o;xxooooxxoo;ooxo
ooooooox#######x;xxxooooxxoooooxxx:x%%%%%%%xoo;ooo
ooooooxxxxxxxxxo;;::,,:::;;::,,:;;:xxxxxxxxxxooooo
ooooxxoooooooooo;:::,,,:;o;:,,,:,;:ooooooooooooooo
xxxxxooooooooooooo;;::;;x%o;:::;;o;ooooooooooooxoo
xxxxxxoooooooxo:x%%xooxxxxxxooox%%o;oooooooooooxoo
%xxxxxxxxxxxxxo;x%%%%%%oxxxx%%%%%%x:oxxxxxxxxxxxoo
#xxx%@@@@@@@@#oo%##%%%xoxxxox%%%%%%;x@@@@@@@@@%xox
%xx%%%#@@@@@@%:o%##%%%xxxxxoxx%%##%o;#@@@@@@#%%xxx
xxx%%%%%%%%%%o:x%%%%xxoxxxxooxx%%%xo:o%%%%%%%xxxxo
xxxxxxx%xxxxx;:xxxxxxooxxoxxoxxxxxxo,oxxxxx%xxooox
xxxxxxxxxxxxx;:ooooooooxo;oxooooooo;,;xoooxxxooooo
xxx%%xoxxxxxx;,;;;;o;ooo;;;oo;;;;;;;,oxxxxxooox%xo
ox%#%xoox%@@#;,;;;;;;;::::,::;;;;;;:.o####xooo%#%o
oo%@#xoox%@@#:.:;;:;:,...,...,:;,;;:.;@@@#oooo%@%o
ooxxxo;ooxxxx:.:;;:,,:;;,,,;;:,,:;;,.;xxxxo;;oxxxo
;;;oo;;oooooo,.,:;:.:o;:...:;o:.:;:, :oo;;;;;;;;;;
;;;;;;;;;;:;;. .::;:;;.,,,,,,;;:;::. ,;;:::;;;;;;;
:::;;;;;;;;;;. .,::;,:;ooooo:,::::.. ,;;:;:;;;::::
:::;;;;ooooo;    ..::,,,,,,,,:::..   .;o;;;;;;;;::
;:::;oxxxxxx;     ,;::,....,,:::.     ;xoooooo::::
;::::;;;;;;;:     ,:;;::,,:::;;:.     :::;;::;::,,
:,,:::::,,,:,     ,:;oo:. .;oo;:.     ::,,,,,,::,,
,,,::,,,,,,,,,    ,:;xx;, :oxo;:.    ,,,,,,,,,,,,,
,,,,,,,,,,,,,,,.  .,:;;;: :;;;:,.  .,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,  .,,,,, ,,,,,.  ,,,,,,,,,,,,,,,,
,,,:::;;oxxo;::::, ...... .......,::::;oxoo;:::,,,
ooxx%%%#@@@%oxx%%x;.....  .....,;x%%xxo#@@@#%%xxoo
@@@@@@@@@####@@@@@x:,..,:::, .,;%@@@@######@@@@@@@
@@@@@@@@@@@@@@@@@#%o;,;x###x;,;o%#@@@@@@@@@######@
@@@@@@@@@@@@@@@@#%xo;x#@@@@@%o;ox%##@@@@@@@@@@@@@#
%x%#@@@@@@@@@@@#%%xo;%@@@@@@@x;ox%%##@@@@@@@@@@%%x
xoox%@@@@@@@@@##%xxox##%xxx%@#o;ox%######@@@@@%ooo
```

Ugly ascii art yes... but still! And the code is as crapy as ever!

> It looks better in my terminal :D But I think it comes down to tweaking the "alphabet" used, deciding how many chars to use in width etc. Nothing really interesting for this post.


# Conclusion

Time for a few reflections and conclusions.

First off all, zig do not feel ready for "primetime" for me but I do feel that it has a promising future. It has many good ideas that sit right with me and seems well suited to the kind of work that I usually do. But would I suggest our team to go "all out zig" at this time... hell no!


## The good

### Good defaults

I like the defaults when it comes to how the language is designed and how the builds are setup with Debug/ReleaseSafe/ReleaseSmall/ReleaseFast.


### Memory allocation is explicit

As someone that has been coding c and c++ in this way for a long time (or at least tried to advocate for this style) it feel right at home having this builtin to the language with the tools needed to make it fairly streamlined.
Forcing the user to take responsibility for memory is a good thing. But that is also said as a "systems programmer", who's responsibility it is to think about these kind of things on a daily basis. Would it go over as well with one of my colleges working in gameplay where iteration time is of an essence when prototyping things and design can change, radically, from hour to hour? Probably not?


### `comptime` feels like a powerful paradigm

`comptime` feels powerful. Being able to not have to use a "special" language such as templates for your generic code, I like that! It feels clear and easy to read and understand. But how is it to debug? As it is "just zig", could there be some kind of special build or maybe a way to step through and evaluate generic code in a debugger?
This would be such a powerful feature, to be able to use your day-to-day debugger to debug your compile-time evaluated code!


### Build System

Easy to get going and builtin as a first class part of the language. Not being an afterthought.

This worked really well for me on my small test-project and I guess it would work really well for bigger projects as well. But how would it scale to really big code-bases, especially with lots of custom build steps (looking at you Apex-engine, looking at you!), that is to be seen?


### Trying to "work well with" c instead of replacing c!

I really like that zig is trying to work with the current landscape that is already there instead of trying to replace it from the ground up. There is just so much great and well established libraries and tools out there already. Making it easy to interact with these instead of trying to replace them sounds like the right choice to me.

Things like `zlib`, `curl` and `sqlite` will probably not be re-written any time soon!


## The bad

### Compile times.

The compile times are far from "good", to put it politely :( And this just for a small commandline app that would probably compile in non-noticeable time in `c`. Throwing a big project on this would probably not be sustainable today.

time to build, clean (no ./zig-cache and ./zig-out) on my machine:

> real 0m11,741s
>
> user 0m8,777s
>
> sys  0m5,789s

YAUSA!!!

time to build, small update to 'main.zig' on my machine:

>real 0m1,074s
>
>user 0m0,953s
>
>sys  0m0,183s

... for such a small change, not really "stellar" :(

I know that this is being worked upon and with the new self-hosted compiler it has become (according to "the interwebs") a lot better but im not sure how far you can take it?

With all `comptime` etc it will be a problem to get it fast. The computations will have to be done regardless and the more calculations that has to be done compile-time the more expensive it will be! But I'll be happy to be proven wrong and it's definitively possible that it can get to a decent state!


### `@compileError`, I don't want errors down in the stdlib!

Getting errors deep down in the stdlib when I made an error in my own code is not really good. See the error discussed above on sending invalid parameters to `std.debug.print()` and getting the error deep down in the stdlib.

How to address this, I don't know. This is the same problem as `static_assert()` and template-errors in c++. However zig should be able to leverage that it has proper modules instead of glorified copy-paste that is c-includes :)

I do see `@compileError` as a really good paradigm, but without this problem solved it feels like it is going to end up as the c++-style wall-of-text that you have to decipher in order to find the real error you made.

Hopefully this is at least seen as a problem by the zig-community and there should at least be things that can be done to make it less painful?


### Please give me a way to iterate over an integer range!!!

ARGH! The loops over a range of integers!

```zig
var block_h: u32 = 0;
while (block_h < block_cnt_h) : (block_h += 1) {
    var block_w: u32 = 0;
    while (block_w < block_cnt_w) : (block_w += 1) {
    }
}
```

If I had a swedish "krona" for each bug this introduced during my short time with zig I would probably be able to afford a really cheap cup of "snut-kaffe" (cop coffee in swedish). This was really cumbersome to use and far from nice. Really clunky!

However at the meetup I got to ask Loris Cro about this and got the answer that this is going to be addressed in the future, see [https://kristoff.it/blog/zig-self-hosted-now-what/](https://kristoff.it/blog/zig-self-hosted-now-what/) under "New for loop syntax"! That one seem quite nice and will hopefully remove this gripe of mine in the future!

I guess this, again, comes down to "there should be one, and only one way, of doing one thing" and in theory I find that to be a valiant goal but when it gets in the way of ergonomics like this it is far from good. However as it seems as if it is being addressed, the main developers seem open to change if it would really benefit the language as in this case! And it is always easier to give a small feature than remove something that turned out to be a mistake, so it is probably a good thing that features is just not thrown in there if they are not proven to be needed!


### Local functions

Nope, not there. This tripped me up a bit. This is honestly nothing major but personally I have started using local functions more and more and I think they make my code simpler and cleaner over all. I know that there has been discussions in the zig-community about it but I haven't tried to find what the conclusions has been.


### Documentation is good... the documentation that's there that is!

Yeah... the documentation. It is good! When you can find it and it exists :( Usually you end up in some blog, some github issue or similar. But zig is a young language, it is not that unexpected that documentation is lacking at this point in time!


## The ugly

### Still fighting the syntax

I'm still fighting the syntax. My 20 years of writing c and c++ trips me up all the time. This however I guess is more on me than the actual syntax... maybe? There are quite a lot of usage of single characters like `_`, `!`, `?`, `:` that make the code terse, but is quite the hurdle when you are new to the language.

But thanks for not using the dreaded backtick (`) for anything!!! Please go google ["backtick scandinavian keyboard"](https://www.google.com/search?channel=fs&client=ubuntu&q=backtick+swedish+keyboard) for some "opinions" from us up north!


### the preferred, idiomatic, format :)

Again this is just a choice that is neither good or bad, just a choice... that I would not have made! I don't like it, but as it is a matter of taste it is kind of silly to complain about as no one will ever prove the other right as there is no right/wrong ( except when it comes to space-vs-tab and snake_case_being_the_way_god_intended() ;) )!


# Where to next?

So where do this take me? I will still keep an eye on zig and its development. Will it become my primary language of choice? Not yet, but maybe someday. I really hope/think that zig has a future and we will see more of it.

If nothing else and zig just disappears some day (not likely!) it will at least have brought interesting ideas to the programming world and proved/disproven that they work and what they can bring to the table!

I do think that I will keep fiddling with zig in the future. I have had some thought going like "everyone has to have written an NES-emulator in their life right?", and maybe it would be worth doing that in zig just for the fun of it?

I'm also intrigued about trying out zig as a buildsystem for my data serialization library (we all got one right?) [https://github.com/wc-duck/datalibrary/]("datalibrary") and see how that turns out!

In the end... this was kind of fun, would do again! And here, finally is a link to the crappy source for the img-to-ascii converter!

[https://github.com/wc-duck/zig_img_to_ascii](https://github.com/wc-duck/zig_img_to_ascii)


# Helpful resources

* [https://ziglang.org/](https://ziglang.org/)
* [https://ziglearn.org/](https://ziglearn.org/)
* [official doc](https://ziglang.org/documentation/0.10.0/)
* [The blog of Loris Cro](https://kristoff.it/blog/) - this must have been the one of my most used resources!
