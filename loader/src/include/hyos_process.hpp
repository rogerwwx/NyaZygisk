#pragma once

#include <string_view>

namespace zn {

inline bool isHyosSpawnerName(std::string_view name) {
    return name.empty() || name == "usap64" || name == "usap32" ||
           name == "hyos_spawner" || name.ends_with("/hyos_spawner");
}

// HyperOS captures the trailing 15 characters of the child's process name.
// An inherited or stale cmdline is useful only after it matches that captured suffix.
inline std::string_view selectHyosProcessName(std::string_view cmdline,
                                             std::string_view captured,
                                             std::string_view package,
                                             std::string_view comm) {
    if (!isHyosSpawnerName(cmdline) &&
        (captured.empty() || cmdline.ends_with(captured))) {
        return cmdline;
    }
    if (!captured.empty()) {
        if (captured.size() == 15 && package.size() > 15 && package.ends_with(captured)) {
            return package;
        }
        return captured;
    }
    if (!isHyosSpawnerName(comm)) return comm;
    return package.empty() ? "hyos_app" : package;
}

}  // namespace zn
