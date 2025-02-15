---
title: "c++ errors... a rant"
date: 2025-02-15T15:10:55+01:00
---

Today a small rant... with a bit of an unexpected conclusion!

> In the beginning someone decided to use `std::variant`. This has made a lot of people very angry and been widely regarded as a bad move.

So at work this week I had to look at code written with `std::variant`... a lot can be said about `std::variant` but this time it is about compile errors!

Someone had decided to use an `std::variant<x, y, z>`, probably got a really bad error-message when they tried to extract a value out of it with the type `w`, i.e. a type that is not part of the variant. Something like this, but simplified.

```c++
#include <variant>

using test = std::variant<int, float>;

template<typename T>
void get_it(test& t)
{
    // ... yes, highly unsafe, but only here to show the error ...
    int i = *std::get_if<T>(&t);
    (void)i;
};

void use_it()
{
    test t = 0;
    get_it<double>(t);
}
```

Observe that the type being requested is not present in the variant, hence the code is invalid. So what do clang and gcc spit out (don't have msvc at home but we'll get to that later).

clang 14.0.0-1ubuntu1.1
``` sh
wc-duck@WcLaptop:~/kod/varianttest$ clang++ -std=c++17 varianttest.cpp -o test
In file included from varianttest.cpp:35:
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1185:7: error: static_assert failed due to requirement '__detail::__variant::__exactly_once<double, int, float>' "T must occur exactly once in alternatives"
      static_assert(__detail::__variant::__exactly_once<_Tp, _Types...>,
      ^             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
varianttest.cpp:43:19: note: in instantiation of function template specialization 'std::get_if<double, int, float>' requested here
    int i = *std::get_if<T>(&t);
                  ^
varianttest.cpp:50:5: note: in instantiation of function template specialization 'get_it<double>' requested here
    get_it<double>(t);
    ^
In file included from varianttest.cpp:35:
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:104:7: error: implicit instantiation of undefined template 'std::variant_alternative<0, std::variant<>>'
    : variant_alternative<_Np-1, variant<_Rest...>> {};
      ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:104:7: note: in instantiation of template class 'std::variant_alternative<1, std::variant<float>>' requested here
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:111:5: note: in instantiation of template class 'std::variant_alternative<2, std::variant<int, float>>' requested here
    using variant_alternative_t =
    ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1155:29: note: in instantiation of template type alias 'variant_alternative_t' requested here
    constexpr add_pointer_t<variant_alternative_t<_Np, variant<_Types...>>>
                            ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1188:14: note: while substituting deduced template arguments into function template 'get_if' [with _Np = 2, _Types = <int, float>]
      return std::get_if<__detail::__variant::__index_of_v<_Tp, _Types...>>(
             ^
varianttest.cpp:43:19: note: in instantiation of function template specialization 'std::get_if<double, int, float>' requested here
    int i = *std::get_if<T>(&t);
                  ^
varianttest.cpp:50:5: note: in instantiation of function template specialization 'get_it<double>' requested here
    get_it<double>(t);
    ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:100:12: note: template is declared here
    struct variant_alternative;
           ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1188:14: error: no matching function for call to 'get_if'
      return std::get_if<__detail::__variant::__index_of_v<_Tp, _Types...>>(
             ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
varianttest.cpp:43:19: note: in instantiation of function template specialization 'std::get_if<double, int, float>' requested here
    int i = *std::get_if<T>(&t);
                  ^
varianttest.cpp:50:5: note: in instantiation of function template specialization 'get_it<double>' requested here
    get_it<double>(t);
    ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1156:5: note: candidate template ignored: substitution failure [with _Np = 2, _Types = <int, float>]
    get_if(variant<_Types...>* __ptr) noexcept
    ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1170:5: note: candidate template ignored: substitution failure [with _Np = 2, _Types = <int, float>]: no type named 'type' in 'std::variant_alternative<2, std::variant<int, float>>'
    get_if(const variant<_Types...>* __ptr) noexcept
    ^
/usr/bin/../lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/variant:1183:5: note: candidate template ignored: invalid explicitly-specified argument for template parameter '_Tp'
    get_if(variant<_Types...>* __ptr) noexcept
    ^
3 errors generated.
```

g++ (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
```sh
wc-duck@WcLaptop:~/kod/varianttest$ g++ -std=c++17 varianttest.cpp -o test
In file included from varianttest.cpp:35:
/usr/include/c++/11/variant: In instantiation of ‘constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*) [with _Tp = double; _Types = {int, float}; std::add_pointer_t<_Tp> = double*]’:
varianttest.cpp:43:28:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:50:19:   required from here
/usr/include/c++/11/variant:1185:42: error: static assertion failed: T must occur exactly once in alternatives
 1185 |       static_assert(__detail::__variant::__exactly_once<_Tp, _Types...>,
      |                     ~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/include/c++/11/variant:1185:42: note: ‘std::__detail::__variant::__exactly_once<double, int, float>’ evaluates to false
/usr/include/c++/11/variant: In instantiation of ‘struct std::variant_alternative<1, std::variant<float> >’:
/usr/include/c++/11/variant:103:12:   required from ‘struct std::variant_alternative<2, std::variant<int, float> >’
/usr/include/c++/11/variant:1170:5:   required by substitution of ‘template<long unsigned int _Np, class ... _Types> constexpr std::add_pointer_t<const typename std::variant_alternative<_Np, std::variant<_Types ...> >::type> std::get_if(const std::variant<_Types ...>*) [with long unsigned int _Np = 2; _Types = {int, float}]’
/usr/include/c++/11/variant:1188:76:   required from ‘constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*) [with _Tp = double; _Types = {int, float}; std::add_pointer_t<_Tp> = double*]’
varianttest.cpp:43:28:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:50:19:   required from here
/usr/include/c++/11/variant:103:12: error: invalid use of incomplete type ‘struct std::variant_alternative<0, std::variant<> >’
  103 |     struct variant_alternative<_Np, variant<_First, _Rest...>>
      |            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/include/c++/11/variant:100:12: note: declaration of ‘struct std::variant_alternative<0, std::variant<> >’
  100 |     struct variant_alternative;
      |            ^~~~~~~~~~~~~~~~~~~
/usr/include/c++/11/variant: In instantiation of ‘constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*) [with _Tp = double; _Types = {int, float}; std::add_pointer_t<_Tp> = double*]’:
varianttest.cpp:43:28:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:50:19:   required from here
/usr/include/c++/11/variant:1188:76: error: no matching function for call to ‘get_if<std::__detail::__variant::__index_of_v<double, int, float> >(std::variant<int, float>*&)’
 1188 |       return std::get_if<__detail::__variant::__index_of_v<_Tp, _Types...>>(
      |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
 1189 |           __ptr);
      |           ~~~~~~                                                            
/usr/include/c++/11/variant:1156:5: note: candidate: ‘template<long unsigned int _Np, class ... _Types> constexpr std::add_pointer_t<typename std::variant_alternative<_Np, std::variant<_Types ...> >::type> std::get_if(std::variant<_Types ...>*)’
 1156 |     get_if(variant<_Types...>* __ptr) noexcept
      |     ^~~~~~
/usr/include/c++/11/variant:1156:5: note:   template argument deduction/substitution failed:
/usr/include/c++/11/variant: In substitution of ‘template<long unsigned int _Np, class ... _Types> constexpr std::add_pointer_t<typename std::variant_alternative<_Np, std::variant<_Types ...> >::type> std::get_if(std::variant<_Types ...>*) [with long unsigned int _Np = 2; _Types = {int, float}]’:
/usr/include/c++/11/variant:1188:76:   required from ‘constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*) [with _Tp = double; _Types = {int, float}; std::add_pointer_t<_Tp> = double*]’
varianttest.cpp:43:28:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:50:19:   required from here
/usr/include/c++/11/variant:1156:5: error: no type named ‘type’ in ‘struct std::variant_alternative<2, std::variant<int, float> >’
/usr/include/c++/11/variant: In instantiation of ‘constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*) [with _Tp = double; _Types = {int, float}; std::add_pointer_t<_Tp> = double*]’:
varianttest.cpp:43:28:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:50:19:   required from here
/usr/include/c++/11/variant:1170:5: note: candidate: ‘template<long unsigned int _Np, class ... _Types> constexpr std::add_pointer_t<const typename std::variant_alternative<_Np, std::variant<_Types ...> >::type> std::get_if(const std::variant<_Types ...>*)’
 1170 |     get_if(const variant<_Types...>* __ptr) noexcept
      |     ^~~~~~
/usr/include/c++/11/variant:1170:5: note:   substitution of deduced template arguments resulted in errors seen above
/usr/include/c++/11/variant:1183:5: note: candidate: ‘template<class _Tp, class ... _Types> constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*)’
 1183 |     get_if(variant<_Types...>* __ptr) noexcept
      |     ^~~~~~
/usr/include/c++/11/variant:1183:5: note:   template argument deduction/substitution failed:
/usr/include/c++/11/variant:1188:76: error: type/value mismatch at argument 1 in template parameter list for ‘template<class _Tp, class ... _Types> constexpr std::add_pointer_t<_Tp> std::get_if(std::variant<_Types ...>*)’
 1188 |       return std::get_if<__detail::__variant::__index_of_v<_Tp, _Types...>>(
      |              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^
 1189 |           __ptr);
      |           ~~~~~~                                                            
/usr/include/c++/11/variant:1188:76: note:   expected a type, got ‘std::__detail::__variant::__index_of_v<double, int, float>’
```

ARGH!!! Sure you can decipher it... but that is a wall of text if there ever was one!

So the poor developer that initially got this wall of "characters" thrown in their face, after what I expect is more time understanding the error than could be expected of a fellow human being, decided to add a static_assert... using boost (╯°□°)╯︵ ┻━┻ to make it simpler for the next user... something like this:

```c++
#include <variant>

using test = std::variant<int, float>;

template<typename T>
void get_it(test& t)
{
    static_assert(boost::mpl::contains<test, T>::type::value, "T isn't a valid my_variant type.");
    int i = *std::get_if<T>(&t);
    (void)i;
};

void use_it()
{
    test t = 0;
    get_it<double>(t);
}
```

Now they get the same as above but at least it start with a clear error! But is this good... no! It is still a wall of text! So me and a coworker (that actually speak "modern c++"!?!) talked a bit about it... and after a bit of google came up with something like this:

```c++
#include <variant>

using test = std::variant<int, float>;

namespace woot
{
    // https://stackoverflow.com/questions/2118541/check-if-parameter-pack-contains-a-type
    template<typename What, typename ... Args>
    struct is_present {
        static constexpr bool value {(std::is_same_v<What, Args> || ...)};
    };

    template< class T, class... Types >
    constexpr std::add_pointer_t<T>
    get_if( std::variant<Types...>* pv ) noexcept
    {
        constexpr bool is_valid_type = is_present<T, Types...>::value;
        static_assert(is_valid_type, "type is not part of the specified variant or specified twice!");
        if constexpr (is_valid_type)
            return std::get_if<T>(pv);
        else
            return nullptr;
    }
}

template<typename T>
void get_it(test& t)
{
    // int i = *std::get_if<T>(&t);
    int i = *woot::get_if<T>(&t);
    (void)i;
};

void use_it()
{
    test t = 0;
    get_it<double>(t);
}
```

clang
```sh
wc-duck@WcLaptop:~/kod/varianttest$ clang++ -std=c++17 varianttest.cpp -o test
varianttest.cpp:18:9: error: static_assert failed due to requirement 'is_valid_type' "type is not part of the specified variant or specified twice!"
        static_assert(is_valid_type, "type is not part of the specified variant or specified twice!");
        ^             ~~~~~~~~~~~~~
varianttest.cpp:30:20: note: in instantiation of function template specialization 'woot::get_if<double, int, float>' requested here
    int i = *woot::get_if<T>(&t);
                   ^
varianttest.cpp:37:5: note: in instantiation of function template specialization 'get_it<double>' requested here
    get_it<double>(t);
    ^
1 error generated.
```

g++
```sh
wc-duck@WcLaptop:~/kod/varianttest$ g++ -std=c++17 varianttest.cpp -o test
varianttest.cpp: In instantiation of ‘constexpr std::add_pointer_t<_Tp> woot::get_if(std::variant<_Types ...>*) [with T = double; Types = {int, float}; std::add_pointer_t<_Tp> = double*]’:
varianttest.cpp:30:29:   required from ‘void get_it(test&) [with T = double; test = std::variant<int, float>]’
varianttest.cpp:37:19:   required from here
varianttest.cpp:18:23: error: static assertion failed: type is not part of the specified variant or specified twice!
   18 |         static_assert(is_valid_type, "type is not part of the specified variant or specified twice!");
      |                       ^~~~~~~~~~~~~
varianttest.cpp:18:23: note: ‘is_valid_type’ evaluates to false
```

A little code... a 1000% better error message! So what is the end of this story? I don't want to cast shadow on the previous developer, and neither do I think that the above is a "neat" or "good" solution, the actual conclusion is WTF can't I get this error-message from the standard libraries themself? Someone must, during development of the libs, have seen this wall of text but at no step of the way stopped and thought "well, this is kind of iffy? Me as an actual implementor of a standard library, i.e. an expert in the field, should be able to do better!".
If it is this "easy" to give us better error-messages WHY NOT DO IT... from the beginning? How many more "walls of text" could we avoid with a few static_asserts?

Would there be a downside? I don't know, maybe there is, but this kind of stuff is one of the reasons c++ is really hard to work with from time to time and that people like me rather go with a "c style" codebase!

Here is a [godbolt link](https://godbolt.org/z/fo6MsvGjq) if you want to test it yourself.

BTW... in the beginning I told you that there was an unexpected twist to this. The latest MSVC actually give you this error (from godbolt!)
```sh
example.cpp
Z:/compilers/msvc/14.41.33923-14.41.33923.0/include\variant(1257): error C2338: static_assert failed: 'get_if<T>(variant<Types...> *) requires T to occur exactly once in Types. (N4971 [variant.get]/12)'
Z:/compilers/msvc/14.41.33923-14.41.33923.0/include\variant(1257): note: the template instantiation context (the oldest one first) is
<source>(37): note: see reference to function template instantiation 'void get_it<double>(test &)' being compiled
<source>(29): note: see reference to function template instantiation 'double *std::get_if<T,int,float>(std::variant<int,float> *) noexcept' being compiled
        with
        [
            T=double
        ]
Compiler returned: 2
```
So for once msvc is actually the best one ;) (but just go back one version and we'r back to the text-wall again!)