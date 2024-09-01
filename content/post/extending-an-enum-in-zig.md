---
title: "Extending an Enum in Zig"
date: 2024-09-01T08:33:59+02:00
tags: ['code', 'zig']
---

For a while now I have been dabbling with [zig](https://ziglang.org/) and as a small test writing a NES-emulator (everyone should have written an 8-bit emulator in their life right?).
While doing this I stumbled upon a kind of neat trick that you can do in zig that I thought was worth sharing... with kind of a "anti-climactic" end!


# Some background

While writing some debug-tools I decided that I wanted to switch between ppu-palettes when displaying some data. At this time the available palettes were all described with an enum.

```zig
pub const Palette = enum {
    bg0, // background palette 0
    bg1, // background palette 1
    bg2, // background palette 2
    bg3, // background palette 3
    sp0, // sprite palette 0
    sp1, // sprite palette 1
    sp2, // sprite palette 2
    sp3, // sprite palette 3
};
```

As I use [zig-gamedev](https://github.com/zig-gamedev/zig-gamedev) for window-management, rendering and ImGui the first thing to reach for is just an imgui-combo-box. Zig:s builtin compile-time reflection and some smart decisions in the zig-gamedev imgui-bindings make that a real treat:

```zig
const zgui = @import("zgui");

var Palette = .bg0;

fn drawUi()
{
    zgui.comboFromEnum("palette", &var);
}
```

This will create a combo-box with all possible values in the enum and select the names from the enum-item names.

[![](/images/extending-an-enum-in-zig/combo_1.png "initial combo")](/images/extending-an-enum-in-zig/combo_1.png)

# The problem

However, I wanted to have a "custom" selection as well? Zig has some really powerful meta-programming facilities, maybe we should try these out? I usually get a tingle of "bad things coming up" when I hear meta-programming as it brings back memories of slow compiles, hard to maintain code and c++-template-errors :D

But I'm here to learn, test and experiment, so here we go!

Lets see if we can extend `Palette` with a first option called `custom`, it is actually not that hard!

```zig
fn addCustomChoice(comptime T: anytype) type {
    // we should probably add some error-checks here that T is an enum etc!

    // use reflection to get the information of the comptime parameter T
    const enum_type = @typeInfo(T).Enum;

    // define an array, in compile time, with the fields of our new enum
    // that has room for "custom".
    comptime var fields: [enum_type.fields.len + 1]std.builtin.Type.EnumField = undefined;

    // define our first field to be "custom" and have the value "1 more than
    // the number of fields".
    fields[0] = .{ .name = "custom", .value = enum_type.fields.len };

    // copy the field from the "base" enum
    inline for (1.., enum_type.fields) |idx, f| {
        fields[idx] = f;
    }

    // and declare and return our new type!
    const enumInfo = std.builtin.Type.Enum{
        .tag_type = u8,
        .fields = &fields,
        .decls = &[0]std.builtin.Type.Declaration{},
        .is_exhaustive = true,
    };

    return @Type(std.builtin.Type{ .Enum = enumInfo });
}

// define a new value of the new type and set it to our new value.
var var_with_custom = addCustomChoice(Palette) = .custom;
```

That is actually quite readable, it is just "ordinary code" that you can read as any other.

[![](/images/extending-an-enum-in-zig/combo_2.png "combo with custom option")](/images/extending-an-enum-in-zig/combo_2.png)

But there are some problems that I have to mention.

## "custom" is hardcoded and values are hardcoded.

With this "custom" and the values of the new items are hardcoded but that could be solved by just taking that as a parameter or an array etc, nothing big!


## getting the "base" enum back

This is a bigger issue, that could probably be solved by someone better at zig than I am. The problem arises when I want to use my new enum as the "base" one, i.e. I want to pass what I selected in my combo-box to some other api. You can't just pass your new enum to the other api as the types are not the same. My first thought was to just add a function to the enum like `fn toBase(self: NewType) BaseType` but I couldn't find a good way through comptime type definitions to add a function to the declared type (probably missing something?).

So I just ended up with my own `enumCast()` declared like this:

```zig
fn isEnum(comptime T: anytype) bool {
    return switch (@typeInfo(T)) {
        .Enum => true,
        else => false,
    };
}

fn enumCast(in: anytype, comptime T: anytype) T {
    comptime {
        const in_T = @TypeOf(in);

        if (!isEnum(in_T))
            @compileError(std.fmt.comptimePrint("'in' should be an enum, '{s}' is not", .{@typeName(in_T)}));
        if (!isEnum(T))
            @compileError(std.fmt.comptimePrint("'T' should be an enum, '{s}' is not", .{@typeName(T)}));
    }

    const i = @intFromEnum(in);
    return @enumFromInt(i);
}

fn castMe() void{
    callWithBase(enumCast(var_with_custom, Palette));
}
```
I couldn't find a "neater" way of casting between 2 enums in zig, should there be one? Maybe? Also having to pass in the type to "cast" to feels "old style zig" but there seems to not be a better way at the moment.

> there is a proposal for `@Return` [https://github.com/ziglang/zig/issues/447](https://github.com/ziglang/zig/issues/447) that could be used here.

This is the point where I realized that I once again had been tricked by the temptress that is "meta programming", what was I doing? Why all this code? And I went back to just doing this.

```zig
var var_with_custom : enum(u8) {
    custom = 8,

    bg0 = @intFromEnum(Palette.bg0),
    bg1 = @intFromEnum(Palette.bg1),
    bg2 = @intFromEnum(Palette.bg2),
    bg3 = @intFromEnum(Palette.bg3),

    sp0 = @intFromEnum(Palette.sp0),
    sp1 = @intFromEnum(Palette.sp1),
    sp2 = @intFromEnum(Palette.sp2),
    sp3 = @intFromEnum(Palette.sp3),

    fn asBase(self: @This()) Palette {
        if(self == .custom)
            unreachable;
        const b = @intFromEnum(self);
        return @enumFromInt(b);
    }
} = .custom;
```

Less code, easier to understand... sure, someone might argue that this is not that reusable but honestly, the above wasn't either. Some one else might argue "what if the 'Palette' is extended?"... I'll take my chances that Nintendo will not redesign the NES any time soon!


# So what have we learned by this?

Number one is probably just because you can its not sure that you should! But also that zig:s meta-programming facilities are really powerful and easy to read/write. I really like the fact that "it is just plain zig" and that I don't have to learn that much new stuff. I'm still afraid of the day when I have to debug this kind of stuff but I'll take this over c++ templates any day of the week!

It is also obvious that zig has a long way to go... documentation is "sparse" to say the least. The above code was all figured out with googling and reading the zig std-lib. On the other hand it is quite impressive that I could do this in a really short amount of time despite the lack of docs!

In the end it was an experiment that turned out to be a dead end... but these are also worth writing about from time to time!