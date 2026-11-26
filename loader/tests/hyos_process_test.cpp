#include "hyos_process.hpp"

#include <cassert>
#include <cstdio>

int main() {
    using zn::selectHyosProcessName;
    constexpr auto package = "com.miui.weather2";
    constexpr auto tail = "m.miui.weather2";

    assert(selectHyosProcessName(package, tail, package, "main") == package);
    assert(selectHyosProcessName("com.miui.weather2:remote", "weather2:remote",
                                 package, "main") == "com.miui.weather2:remote");
    // A full but stale cmdline must not replace the captured child's identity.
    assert(selectHyosProcessName("com.miui.home", tail, package, "main") == package);
    assert(selectHyosProcessName("com.miui.home", "weather:worker",
                                 package, "main") == "weather:worker");
    for (const auto* spawner : {"hyos_spawner", "/system_ext/bin/hyos_spawner",
                               "usap64", "usap32", ""}) {
        assert(selectHyosProcessName(spawner, tail, package, "main") == package);
    }
    // Without a captured suffix, a complete app cmdline remains the best source.
    assert(selectHyosProcessName("com.example.app:service", "", package, "main") ==
           "com.example.app:service");
    assert(selectHyosProcessName("", "", package, "app-worker") == "app-worker");
    assert(selectHyosProcessName("", "", package, "hyos_spawner") == package);
    assert(selectHyosProcessName("", "", "", "") == "hyos_app");
    puts("HYOS process identity tests passed");
}
