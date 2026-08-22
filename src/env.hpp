// include/wisp/env.hpp

#pragma once

// Names of the environment variables wisp uses to hand resolved
// config values from the main process.

namespace wisp::env {


// Config
inline constexpr const char *kTimeFormat = "WISP_TIME_FORMAT";

inline constexpr const char *kAppsJson = "WISP_APPS_JSON";


// Other
inline constexpr const char *kShareDir = "WISP_SHARE_DIR";

} // namespace wisp::env
