//! Credentials accepted for native Zygisk Next module requests.

pub const AID_SYSTEM: u32 = 1000;
const AID_ARTD: u32 = 1082;

/// artd runs as its own Android service UID, even when injection is performed by root.
/// This permission applies only to GetZnPlan and ReportZnModule.
pub fn can_access_modules(peer_uid: Option<u32>) -> bool {
    matches!(peer_uid, Some(0) | Some(AID_SYSTEM) | Some(AID_ARTD))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_native_module_hosts() {
        for uid in [0, AID_SYSTEM, AID_ARTD] {
            assert!(can_access_modules(Some(uid)), "rejected native host UID {uid}");
        }
    }

    #[test]
    fn rejects_shell_and_app_uids() {
        for uid in [1001, 1081, 1083, 2000, 10000, 101082, u32::MAX] {
            assert!(!can_access_modules(Some(uid)), "accepted untrusted UID {uid}");
        }
    }

    #[test]
    fn rejects_missing_credentials() {
        assert!(!can_access_modules(None));
    }
}
