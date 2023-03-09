# rename this!
WCCHARTS=../wccharts/build/wcchart
IMGDIR=static/images/swapping-memory-and-compiler-optimizations
mkdir -p $IMGDIR

# generic
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --title-chart "memswap_generic, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_time.png

# memcpy
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --category memcpy --no-category ptr --title-chart "memswap_memcpy, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_memcpy_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category memcpy --no-category ptr --title-chart "memswap_memcpy, time 4MB"  --values-unit us   --output $IMGDIR/memswap_memcpy_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category memcpy --title-chart "memswap_memcpy_ptr, time 4MB"  --values-unit us   --output $IMGDIR/memswap_memcpy_ptr_time.png

# sse2
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --category memcpy --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_sse2_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, time 4MB"  --values-unit us   --output $IMGDIR/memswap_sse2_time.png

# avx
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --category avx --no-category unroll --title-chart "memswap_avx, time 4MB"  --values-unit us   --output $IMGDIR/memswap_sse2_avx_time.png

# vector unroll
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --category avx --title-chart "memswap_unroll, time 4MB"  --values-unit us   --output $IMGDIR/memswap_unroll_time.png

# all
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category swap_ranges --category generic --category avx_unroll --title-chart "memswap_all, time 4MB"  --values-unit us   --output $IMGDIR/memswap_all_time.png

# size vs speed
$WCCHARTS --type line --title-chart "size vs speed, gcc -O0"   ../memcpy_util/diff_sizes_gcc_O0_massage.csv   --output $IMGDIR/memswap_size_vs_speed_gcc_O0_all.png
$WCCHARTS --type line --title-chart "size vs speed, clang -O0" ../memcpy_util/diff_sizes_clang_O0_massage.csv --output $IMGDIR/memswap_size_vs_speed_clang_O0_all.png
$WCCHARTS --type line --title-chart "size vs speed, gcc -O2"   ../memcpy_util/diff_sizes_gcc_O2_massage.csv   --output $IMGDIR/memswap_size_vs_speed_gcc_O2_all.png
$WCCHARTS --type line --title-chart "size vs speed, clang -O2" ../memcpy_util/diff_sizes_clang_O2_massage.csv --output $IMGDIR/memswap_size_vs_speed_clang_O2_all.png
$WCCHARTS --type line --title-chart "size vs speed, gcc -O0"   ../memcpy_util/diff_sizes_gcc_O0_massage.csv   --x-range [0:12] --y-range [0:19] --no-category memcpy_only --output $IMGDIR/memswap_size_vs_speed_gcc_O0_under_12.png
$WCCHARTS --type line --title-chart "size vs speed, clang -O0" ../memcpy_util/diff_sizes_clang_O0_massage.csv --x-range [0:12] --y-range [0:19] --no-category memcpy_only --output $IMGDIR/memswap_size_vs_speed_clang_O0_under_12.png
$WCCHARTS --type line --title-chart "size vs speed, gcc -O2"   ../memcpy_util/diff_sizes_gcc_O2_massage.csv   --x-range [0:12] --y-range [0:30] --no-category memcpy_only --output $IMGDIR/memswap_size_vs_speed_gcc_O2_under_12.png
$WCCHARTS --type line --title-chart "size vs speed, clang -O2" ../memcpy_util/diff_sizes_clang_O2_massage.csv --x-range [0:12] --y-range [0:30] --no-category memcpy_only --output $IMGDIR/memswap_size_vs_speed_clang_O2_under_12.png

# codesize
$WCCHARTS --type bar-vertical --set O0 ../memcpy_util/size.csv --title-chart "code size -O0" --values-unit byte --output $IMGDIR/code_size_O0.png
$WCCHARTS --type bar-vertical --set Os ../memcpy_util/size.csv --title-chart "code size -Os" --values-unit byte --output $IMGDIR/code_size_Os.png
$WCCHARTS --type bar-vertical --set O2 ../memcpy_util/size.csv --title-chart "code size -O2" --values-unit byte --output $IMGDIR/code_size_O2.png
$WCCHARTS --type bar-vertical --set O3 ../memcpy_util/size.csv --title-chart "code size -O3" --values-unit byte --output $IMGDIR/code_size_O3.png
