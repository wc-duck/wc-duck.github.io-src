---
title: "Software I Like"
date: 2024-03-10
toc: true
---

I'm not the one that tinkers a lot with my dev-environment but there are some tools and software that I need and find that they help a lot day to day.
And since I like to read about what others use I might as well share some tips on tools that you might also like.

My day-to-day OS of choice at home is [xubuntu](https://xubuntu.org/) and at work Windows.

> I hope to make this post a living document so it might be updated from time to time.

> Some images in this post is stolen from the tools webpages, I really hope that that is not a problem, if it is, please reach out!

## Software

### clink - readline for the windows console

[![](/images/software-i-like/clink.png "clink")](/images/software-i-like/clink.png)

The default terminal in Windos is damn near unusable, however thanks to Martin Ridgers wonderful little tool clink we can have a GNU readline based input in said terminal!
This is a must-install on any windows machine that I do some work on!

https://github.com/mridgers/clink/

> The original repository has not been updated a quite a while and there is a fork here https://github.com/chrisant996/clink that claims to be maintaining the tool. I haven't used that fork yet but I might give it a go some day.


### WinMerge - merging code

[![](/images/software-i-like/winmerge.gif "winmerge")](/images/software-i-like/winmerge.gif)

Merging/diffing code is something that you do all of the time. My weapon of choice for a really long time has been [winmerge](https://winmerge.org/). It does both code and directory diffs quite well and is the one I have stuck with and feel most comfortable with.
However I can't let go of the feeling that I should look for something new, for example WinMerge is windows only.

Maybe I should look at writing something for myself? I would like something that both support windows and linux, that can be run in the console if I want to and has syntax highlighting.

> I'll put that in the pile of 'yet another project to start and maybe finish someday... maybe... hopefully... probably not :D'


### WinDirStat - What is eating all my precious disk-space?

[![](/images/software-i-like/windirstat.jpg "windirstat")](/images/software-i-like/windirstat.jpg)

At work I have to juggle quite a few different projects, all will a lot of GB:s of data and your bound to fill up your disk:s with temporary files, models, textures, object-files, and other build-artifacts.

A great tool to visualize where you spend all these GB:s is [WinDirStat](https://windirstat.net/). It is a great tool to give you an overview of where your disk is spent and make it simple to clean out what you don't see and help you get an overview of where you can optimize!

Lately I have also started to test out [WizTree](https://diskanalyzer.com/) that is faster than WinDirStat. I however hasn't used it enough to say if I prefer it or not!


### Everything - Fast search in windows!

[![](/images/software-i-like/everything.png "everything")](/images/software-i-like/everything.png)

What if windows search didn't suck? In comes [Everything](https://www.voidtools.com/)! Lighting fast "find me the file with this name on my machine", can't live without it after starting to use it.

I am looking for an alternative to use at home on linux but haven't found anything yet but [FSearch](http://cboxdoerfer.github.io/fsearch/) might be worth testing out?


### ImHex - A great hex-editor.

[![](/images/software-i-like/imhex.png "imhex")](/images/software-i-like/imhex.png)

From time to time you need a hex-editor and I have found [ImHex](https://imhex.werwolv.net/) to be a great alternative. No installation, fast and snappy, feature-rich and no fuzz... exactly like a tool should be!


### bat - A better cat.

[![](/images/software-i-like/bat.png "bat")](/images/software-i-like/bat.png)

There is always times when you just want to check the content of a file without editing etc. The usual solution on a unix based system is to reach for `cat`. `bat` is basically `cat` with syntax highlighting!

Really nice when you just want to check out some code and I have used it together with `objdump` for better assembly output!

> `objdump -C -d file | bat -l asm`

Get it [here](https://github.com/sharkdp/bat)


### Python

[![](/images/software-i-like/python.png "bat")](/images/software-i-like/python.png)

[Python](https://www.python.org/) need no introduction, but it is my weapon of choice for "hacking together a small script" or just as a command line tool for doing quick math or converting utf8 strings to hex-bytes etc.

Would I like to write a bigger program in python? NEVER AGAIN :)


## Visual Studio Plugins

Visual Studio is what I usually write code in professionally for better and worse. I use it kind of vanilla, but there are some plugins that make it a better experience.


### Smart Command Line Arguments

[![](/images/software-i-like/vs_smart_cmd.png "Smart Command Line Arguments")](/images/software-i-like/vs_smart_cmd.png)

I work with a lot of command-line argument heavy applications so juggling command-line arguments to turn on and off features or run this or that unittest etc can get kind of daunting with the default command line interface in Visual Studio.

[Smart Command Line Arguments](https://marketplace.visualstudio.com/items?itemName=MBulli.SmartCommandlineArguments) helps out a lot and make that work a lot smoother.

> A word of warning, it will override all settings done in the ordinary vs-interface and that can bite you in the behind!


### Compile Score

[![](/images/software-i-like/vs_compile_score.png "Compile Score")](/images/software-i-like/vs_compile_score.png)

> A word of warning, this plugin can become kind of an addiction!

[Compile Score](https://marketplace.visualstudio.com/items?itemName=RamonViladomat.CompileScore) is a really neat plugin that hook into your build without any extra code or setup, works just as well with your custom buildsystem as with ordinary msbuild, and show you in a great way where you spend time compiling and what includes cost you the most etc.

Try it out but don't blame me when your hooked :)


## On the "radar"

These are tools that I haven't tried yet, isn't released yet etc but that I has some hope for.


### RAD Debugger

[![](/images/software-i-like/rad_debugger.png "RAD Debugger - Image stolen from Twitter")](/images/software-i-like/rad_debugger.png)

[RAD Debugger on GitHub](https://github.com/EpicGamesExt/raddebugger)

The world need some competition in the debugger-space and as a Linux user I definitively know!!! Professionally I use Visual Studio but it has been getting slower and slower and more bloated over time. So when Epic/RAD anounced that they are working on their own debugger and released a preview build that really made me want to try it out. Unfortunatly I haven't had the time yet, but it is there to keep an eye on!


## Disk Voyager

{{< youtube oSS_mXJJugo >}}

[Disc Voyager](https://diskvoyager.com/) is an in development replacement for windows explorer that looks really neat! Seems fast an well thought out. I would live to give it a spin and test it out some day.