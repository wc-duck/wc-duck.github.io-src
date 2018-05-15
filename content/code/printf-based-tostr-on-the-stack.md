Title: printf-based TOSTR on the stack
Date: 2018-05-15
Tags: code, c++

As I might have written before I like printf-style string-formating. It's imho the most convenient way to format strings and it can be really powerful if needed.
However something that can be a bit tedious is output:ing "composite" values such as a vec3 or quaternion as there will be quite a bunch of repetition.

```c++
printf("{ %.2f, %.2f, %.2f }", vec.x, vec.x, vec.z);
```

Doing this for multiple values really get verbose and its easy to make simple copy-paste-errors ( see above! ).

I have read/looked at a whole bunch of string-formating libs and "tostr()" implementations, usually in c++, returning an `std::string` and/or overloading `operator<<` for writing to `std::ostream` etc and not really liking any of them ( forcing dynamic allocation for known sized outputs for example, *yuck!* ). 

But complaining is easy, time to be constructive and get to some suggestions on how this can be done instead.

# BYTES2STR()

I have found that most of these problems can be solved with a small trick, introducing a struct with the storage for the string. I will start introducing this with a simple macro to turn a `size_t` to a string in the format `"234 bytes"`, `"2.9 kB"` or `"234 GB"`.

```c++
enum
{
	BYTES_PER_KB = 1024,
	BYTES_PER_MB = 1024 * BYTES_PER_KB,
	BYTES_PER_GB = 1024 * BYTES_PER_MB
};

struct _bytes_to_human
{
	char str[64];

	_bytes_to_human( size_t bytes )
	{
		if     ( bytes > BYTES_PER_GB ) snprintf( str, sizeof(str), "%.02f GB", (double)bytes * ( 1.0f / (double)BYTES_PER_GB ) );
		else if( bytes > BYTES_PER_MB ) snprintf( str, sizeof(str), "%.02f MB", (double)bytes * ( 1.0f / (double)BYTES_PER_MB ) );
		else if( bytes > BYTES_PER_KB ) snprintf( str, sizeof(str), "%.02f kB", (double)bytes * ( 1.0f / (double)BYTES_PER_KB ) );
		else                            snprintf( str, sizeof(str), "%zu bytes", bytes );
	};
};

#define BYTES2STR( bytes ) _bytes_to_human( bytes ).str
```

This can now be used simply as follows

```c++
printf("you have allocated %s", BYTES2STR(allocated_bytes));
```

What we did here is to introduce a helper-struct containing the storage for the generated string and a macro to hide a bit of ugliness. Simple and easy to read and work with and I feel fairly confident when I say that the compiler will handle this will, NICE :)


# Extending to a more general TOSTR()

But can this be extended to be a general and extensible solution? Would I write this article if I didn't believe that it was? Of course it is and with a really small amount of code as well :)

Our goal here is to be able to have one macro, `TOSTR(obj)`, that take an object that has an implementation defined with `TOSTR_DEFINE_TYPE_FUNCTION` that defines how to convert the type to string and reserve space for that string on the stack.

If you just want the code or think it is easier to read the code directly here is a link to a github repo.

https://github.com/wc-duck/tostring.

Onto the code/implementation then!

So lets say that we have a vec3-struct that we want to add TOSTR() support to. That is as simple as using the macro `TOSTR_DEFINE_TYPE_FUNCTION` as follows.

```c++
struct vec3
{
	float x;
	float y;
	float z;
};

// declare with type to implement for and the amount of bytes that 
// is needed in the output-string.
TOSTR_DEFINE_TYPE_FUNCTION(vec3, 64) 
{
	// the end of the macro-expansion expects you to declare how
	// to write the output value.
	//
	// you will get passed an output-buffer as 'out' ( with space
	// for the requested 64-chars ) and a reference to the value 
	// to print as 'value'.
	//
	// 'out' has one member-function called 'put' that has a 
	// printf-like format. ( yes, that makes it out.put :) )

	out.put("{ %.2f, %.2f, %.2f }", value.x, value.y, value.z);
}
```

The macro will declare a static constant for the declared type with the size like this, but for a few different cases ( `vec3`, `const vec3`, `vec3&` and `const vec3&` )

```c++
template<> struct _TOSTR_type_size<vec3> { enum { STRING_SIZE = 64 }; };
```

And it also declare a function with this signature ( using the code in {} after the macro as its body )

```c++
inline void _TOSTR_type_impl( _TOSTR_builder& out, const vec3& value );
```

Finally we have the `TOSTR(obj)`-macro that will create a temporary buffer on the stack, fetching its size from `_TOSTR_type_size<decltype(obj)>::STRING_SIZE` and pass that to the `_TOSTR_type_impl` that will use overloading to select the correct implementation.

What we can simply do now is just use TOSTR() as expected with vec3.


```c++
printf("player: pos = %s, velocity = %s", TOSTR(player_pos), TOSTR(player_vel));

// ... or ...

printf("player: pos = %s, velocity = %s", TOSTR(player.pos()), TOSTR(player.vel()));
```

that would output something like: `"player: pos = { 11.0, 12.99, 13.37 }, velocity = { 0.14, 2.35, 3.71 }"` ( depending on the actual position and velocity of the player hopefully ;) )

btw, they also "stack" quite well such as:

```c++
struct aabb
{
	vec3 min;
	vec3 max;
};

TOSTR_DEFINE_TYPE_FUNCTION(aabb, 128) 
{
	out.put("{ %s, %s }", TOSTR(value.min), TOSTR(value.max));
}
```


# Any negatives?

The biggest draw-back in my opinion is the fact that the lifetime of the generated string is only during the current expression, i.e. you can't "save" your string to use later. I.e. this is valid code but undefined behavior.

```c++
const char* vec_str = TOSTR(my_vec);
printf("%s", vec_str);
```

This since the macro defines a temporary variable to hold the value.

Also the fact that overflow might happen and you will get truncated output. I think this is a smaller problem as in many cases ( as the ones above and many more ) you actually know in advance the string-length that you will be generating.

If you find the overflow issue as a big issues it would be quite easy to add an "dynamic-alloc on overflow" to the system.

I also know that some has problems with printf and friends all together as it is not "typesafe" etc. Imho that is mostly a solved problem by modern compilers that do type-checks in compile-time for you on these. But that is my opinion :)

Finally there might be some objections to the template-usage in the implementation but I think it is at a reasonable level, but I guess that it can be solved in other ways if you think this is a problem.

# Conclusion

This might not be anything new but it is a small trick that I haven't seen that much in the wild and that has made my own code "better" imho. It might not be to everybodys taste but hopefully someone has got a new tool to their toolbox!

As usual, don't be afraid to reach out to me at twitter, github any other channel that you might know of!