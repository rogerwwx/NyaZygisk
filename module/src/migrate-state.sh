#!/system/bin/sh

# Keep the current workdir authoritative. Import only the anonymous-memory
# preference from old configs so the new default hook engine takes effect.
# User-edited spoof.prop is a separate file and remains preserved in full.
migrate_saved_state() {
  state_work_dir=$1
  state_module_dir=${2:-.}
  state_data_root=${3:-/data}

  mkdir -p "$state_work_dir" || return 1
  for state_name in config.prop spoof.prop; do
    [ -e "$state_work_dir/$state_name" ] && continue
    for state_source_dir in \
      "$state_data_root/system/nyazygisk" \
      "$state_data_root/adb/nyazygisk" \
      "$state_data_root/adb/modules/zygisksu" \
      "$state_module_dir"; do
      [ "$state_source_dir" = "$state_work_dir" ] && continue
      [ -f "$state_source_dir/$state_name" ] || continue
      if [ "$state_name" = config.prop ]; then
        state_anonymous_memory=$(sed -n \
          's/^[[:space:]]*anonymous_memory[[:space:]]*=[[:space:]]*\([01]\)[[:space:]]*$/anonymous_memory=\1/p' \
          "$state_source_dir/$state_name" | tail -n 1)
        [ -n "$state_anonymous_memory" ] || continue
        printf '%s\n' "$state_anonymous_memory" > "$state_work_dir/$state_name.new" || return 1
      else
        cp -f "$state_source_dir/$state_name" "$state_work_dir/$state_name.new" || return 1
      fi
      mv -f "$state_work_dir/$state_name.new" "$state_work_dir/$state_name" || return 1
      printf '%s\n' "- Preserved $state_name from $state_source_dir"
      break
    done
  done
}

migrate_saved_state "$@"
