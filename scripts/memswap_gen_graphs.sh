# rename this!
WCCHARTS=../wccharts/build/wcchart
IMGDIR=static/images/swapping-memory-and-compiler-optimizations
mkdir -p $IMGDIR

# generic
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --title-chart "memswap_generic, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category generic --title-chart "memswap_generic, code size" --values-unit byte --output $IMGDIR/memswap_generic_size.png

# memcpy
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --category memcpy --no-category ptr --title-chart "memswap_memcpy, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_memcpy_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category generic --category memcpy --no-category ptr --title-chart "memswap_memcpy, code size" --values-unit byte --output $IMGDIR/memswap_generic_memcpy_size.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category memcpy --no-category ptr --title-chart "memswap_memcpy, time 4MB"  --values-unit us   --output $IMGDIR/memswap_memcpy_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category memcpy --no-category ptr --title-chart "memswap_memcpy, code size" --values-unit byte --output $IMGDIR/memswap_memcpy_size.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category memcpy --title-chart "memswap_memcpy_ptr, time 4MB"  --values-unit us   --output $IMGDIR/memswap_memcpy_ptr_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category memcpy --title-chart "memswap_memcpy_ptr, code size" --values-unit byte --output $IMGDIR/memswap_memcpy_ptr_size.png

# sse2
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category generic --category memcpy --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, time 4MB"  --values-unit us   --output $IMGDIR/memswap_generic_sse2_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category generic --category memcpy --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, code size" --values-unit byte --output $IMGDIR/memswap_generic_sse2_size.png
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, time 4MB"  --values-unit us   --output $IMGDIR/memswap_sse2_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category sse --no-category ptr --no-category unroll --title-chart "memswap_sse2, code size" --values-unit byte --output $IMGDIR/memswap_sse2_size.png

# avx
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --category avx --no-category unroll --title-chart "memswap_avx, time 4MB"  --values-unit us   --output $IMGDIR/memswap_sse2_avx_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category sse --category avx --no-category unroll --title-chart "memswap_avx, code size" --values-unit byte --output $IMGDIR/memswap_sse2_avx_size.png

# vector unroll
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category sse --category avx --title-chart "memswap_unroll, time 4MB"  --values-unit us   --output $IMGDIR/memswap_unroll_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category sse --category avx --title-chart "memswap_unroll, code size" --values-unit byte --output $IMGDIR/memswap_unroll_size.png

# all
$WCCHARTS --type bar-vertical ../memcpy_util/time.csv --category swap_ranges --category generic --category avx_unroll --title-chart "memswap_all, time 4MB"  --values-unit us   --output $IMGDIR/memswap_all_time.png
$WCCHARTS --type bar-vertical ../memcpy_util/size.csv --category swap_ranges --category generic --category avx_unroll --title-chart "memswap_all, code size" --values-unit byte --output $IMGDIR/memswap_all_size.png