Title: The command-line as a poor mans config files
Date: 2016-03-01
Tags: code, c++

I like command-line arguments as mentioned in an earlier [post]({filename}./registering-command-line-args.md) about them. In this 
post I'll discuss a method to use them as simple config-files.

Let's start of with a usage example from my own code. I have a meshviewer/particleviewer that is used for, you guessed it, viewing meshes
and particle-effects. These kind of resources, at least the particle-effects, have internal paths to resources that need to be read while
loading ( particles have a material to be rendered with etc ), i.e. resources from "some game" need to be found by the particle-viewer.
Since reading resources is done via a VFS ( Virtual File System ) and paths is always specified via this VFS in resources we must just make
sure that "some game":s resources is mounted in the particle-viewer!

Luckily for me this can be done via, you guessed it, the command line!

```sh
    ./meshviewer --vfs-mount-uri=file:///path/to/assets --vfs-mount-point=/assets/ /assets/mesh/mesh_in_game_to_view.mesh
```

Nice! But writing out this when you want to just test a resource from one project might be hard to remember and a bit of a hassle =/
So lets add one more command-line switch, `--cmd-file=<path_to_file>`!
What this simply does is read the pointed to file, split it at white-space, add it to argc/argv. TADA! simple config-files done + all
that can be configurate via files can also be configurated via the command-line.

If we let `--cmd-file=<path_to_file>` be recursive, we can do sub-files as well.

The above then becomes:

```sh
    ./meshviewer --cmd-file=setup_some_game.cmd /assets/mesh/mesh_in_game_to_view.mesh
```

In this specific case it might not save you that much, but consider you having multiple games, multiple configs etc.

Do I think this would replace all configuration ever? Absolutely not, but it works great for small things as above. I would absolutely not
do this for settings that should be used in a shipped game, only for debug-settings and other settings used during development.

Short post, but hopefully someone like this and steal it :)
