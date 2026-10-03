#pragma once
#include <string_view>

namespace zn {
inline bool isArtDPath(std::string_view path) {
    if (path.ends_with(" (deleted)")) path.remove_suffix(10);
    if (path == "/apex/com.android.art/bin/artd") return true;
    return path.starts_with("/apex/com.android.art@") && path.ends_with("/bin/artd");
}
}
