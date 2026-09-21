# OxideShelfSort

This is an arm64 iOS dylib that adds a small `SORT` control and asks the
existing `ui_tab_sort` Unity button to run. It does not change inventory data,
resource counts, networking, or account checks.

The workflow builds it on a macOS GitHub Actions runner. The dylib is unsigned
and must be embedded and signed together with the target app by the owner of
the provisioning identity.

The current build is intentionally a probe: it uses the sort button already
present in the app. If the target build does not expose the button's runtime
handler through `SendMessage`, the button will have no effect and the runtime
entry point must be identified from an authorized development build.
