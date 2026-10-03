#include "zn_targets.hpp"
#include <cassert>
#include <cstdio>
int main() {
    assert(zn::isArtDPath("/apex/com.android.art/bin/artd"));
    assert(zn::isArtDPath("/apex/com.android.art@371000000/bin/artd"));
    assert(zn::isArtDPath("/apex/com.android.art/bin/artd (deleted)"));
    assert(!zn::isArtDPath("/apex/com.android.art/bin/art_exec"));
    assert(!zn::isArtDPath("/apex/com.android.art/bin/dex2oat64"));
    assert(!zn::isArtDPath("/data/local/tmp/artd"));
    assert(!zn::isArtDPath("/apex/com.android.art/bin/artd_fake"));
    assert(!zn::isArtDPath("/apex/com.android.art_fake/bin/artd"));
    puts("ZN artd target selection tests passed");
}
