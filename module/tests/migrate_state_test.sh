#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
migration_script="$repo_dir/module/src/migrate-state.sh"
fixture_dir=$(mktemp -d)
trap 'rm -rf -- "$fixture_dir"' EXIT HUP INT TERM

new_fixture() {
  case_dir="$fixture_dir/$1"
  data_dir="$case_dir/data"
  module_dir="$case_dir/staged module"
  work_dir="$data_dir/system_de/nyazygisk"
  mkdir -p "$module_dir" "$work_dir"
}

run_migration() {
  sh "$migration_script" "$work_dir" "$module_dir" "$data_dir"
}

# Import only the anonymous-memory toggle from every historical location.
# Old hook engines and unrelated config keys must not override the new defaults.
for old_location in system/nyazygisk adb/nyazygisk adb/modules/zygisksu; do
  new_fixture "legacy-$old_location"
  source_dir="$data_dir/$old_location"
  mkdir -p "$source_dir"
  printf '%s\n' 'anonymous_memory=1' 'custom_linker=1' 'plt_engine=lsplt' \
    'excluded_apps=com.example.app' 'future_key=保留' > "$source_dir/config.prop"
  printf '%s\n' 'ro.custom.preference=user-value' > "$source_dir/spoof.prop"
  printf '%s\n' 'ro.custom.preference=default' > "$module_dir/spoof.prop"
  run_migration
  test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=1'
  test "$(wc -l < "$work_dir/config.prop")" -eq 1
  cmp "$source_dir/spoof.prop" "$work_dir/spoof.prop"
  # A second install must not resurrect the old preference after the user changes it.
  printf '%s\n' 'anonymous_memory=0' > "$work_dir/config.prop"
  run_migration
  test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=0'
  test -f "$source_dir/config.prop"
done

new_fixture current
mkdir -p "$data_dir/system/nyazygisk"
printf '%s\n' 'anonymous_memory=0' > "$work_dir/config.prop"
printf '%s\n' 'anonymous_memory=1' > "$data_dir/system/nyazygisk/config.prop"
printf '%s\n' 'ro.custom.preference=current' > "$work_dir/spoof.prop"
printf '%s\n' 'ro.custom.preference=old' > "$data_dir/system/nyazygisk/spoof.prop"
run_migration
test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=0'
test "$(cat "$work_dir/spoof.prop")" = 'ro.custom.preference=current'

new_fixture priority
mkdir -p "$data_dir/system/nyazygisk" "$data_dir/adb/nyazygisk"
printf '%s\n' 'anonymous_memory=1' > "$data_dir/system/nyazygisk/config.prop"
printf '%s\n' 'anonymous_memory=0' > "$data_dir/adb/nyazygisk/config.prop"
run_migration
cmp "$data_dir/system/nyazygisk/config.prop" "$work_dir/config.prop"

new_fixture disabled
mkdir -p "$data_dir/system/nyazygisk"
printf '%s\n' 'plt_engine=bytehook' 'anonymous_memory=0' > "$data_dir/system/nyazygisk/config.prop"
run_migration
test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=0'

new_fixture invalid
mkdir -p "$data_dir/system/nyazygisk"
printf '%s\n' '# anonymous_memory=1' 'anonymous_memory=11' \
  'anonymous_memory=true' 'other_anonymous_memory=1' 'plt_engine=lsplt' \
  > "$data_dir/system/nyazygisk/config.prop"
run_migration
test ! -e "$work_dir/config.prop"

new_fixture whitespace
mkdir -p "$data_dir/system/nyazygisk"
printf 'plt_engine=lsplt\r\n anonymous_memory = 0 \r\nanonymous_memory=1\r\n' \
  > "$data_dir/system/nyazygisk/config.prop"
run_migration
test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=1'
test "$(wc -l < "$work_dir/config.prop")" -eq 1

new_fixture fallback
mkdir -p "$data_dir/system/nyazygisk" "$data_dir/adb/nyazygisk"
printf '%s\n' 'plt_engine=lsplt' > "$data_dir/system/nyazygisk/config.prop"
printf '%s\n' 'anonymous_memory=1' > "$data_dir/adb/nyazygisk/config.prop"
run_migration
test "$(cat "$work_dir/config.prop")" = 'anonymous_memory=1'

new_fixture 'fresh 中文'
printf '%s\n' 'ro.custom.preference=default' > "$module_dir/spoof.prop"
run_migration
test ! -e "$work_dir/config.prop"
cmp "$module_dir/spoof.prop" "$work_dir/spoof.prop"

new_fixture empty-current
: > "$work_dir/config.prop"
mkdir -p "$data_dir/system/nyazygisk"
printf '%s\n' 'anonymous_memory=1' > "$data_dir/system/nyazygisk/config.prop"
run_migration
test ! -s "$work_dir/config.prop"

# The boot/late-load caller supplies only the workdir and uses the module as cwd.
new_fixture bootstrap
printf '%s\n' 'ro.custom.preference=bootstrap' > "$module_dir/spoof.prop"
(cd "$module_dir" && sh "$migration_script" "$work_dir" . "$data_dir")
cmp "$module_dir/spoof.prop" "$work_dir/spoof.prop"

printf '%s\n' 'Saved state migration tests passed'
