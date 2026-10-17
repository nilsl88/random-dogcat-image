#!/usr/bin/env bash
set -euo pipefail

engine="${CONTAINER_ENGINE:-docker}"
image="${1:-random-dogcat:smoke}"
container_id=""
temp_dir=""

fail() {
    printf 'Smoke test failed: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    local exit_status=$?
    trap - EXIT
    if [[ -n "$container_id" ]]; then
        if [[ "$exit_status" -ne 0 ]]; then
            printf '\nContainer state:\n' >&2
            "$engine" inspect --format '{{json .State}}' "$container_id" >&2 || true
            printf '\nContainer logs:\n' >&2
            "$engine" logs "$container_id" >&2 || true
        fi
        "$engine" rm --force "$container_id" >/dev/null 2>&1 || true
    fi
    if [[ "$exit_status" -ne 0 && -n "$temp_dir" && -s "$temp_dir/curl-error" ]]; then
        printf '\nLast HTTP connection error:\n' >&2
        cat "$temp_dir/curl-error" >&2
    fi
    if [[ -n "$temp_dir" ]]; then
        rm -rf -- "$temp_dir"
    fi
    exit "$exit_status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

command -v "$engine" >/dev/null 2>&1 || fail "Container engine not found: $engine"
command -v curl >/dev/null 2>&1 || fail 'curl is required.'
[[ $# -le 1 ]] || fail 'Usage: CONTAINER_ENGINE=docker scripts/smoke-test.sh [image]'
temp_dir="$(mktemp -d)"

image_user="$("$engine" image inspect --format '{{.Config.User}}' "$image")"
[[ "$image_user" == 10001:10001 ]] \
    || fail "The image defaults to user $image_user instead of 10001:10001."

runtime_options=(
    --user 10001:10001
    --read-only
    --cap-drop=ALL
    --security-opt=no-new-privileges
    --tmpfs /tmp:rw,size=8m
)

printf 'Validating the Caddy configuration in %s...\n' "$image"
"$engine" run --rm "${runtime_options[@]}" --entrypoint /usr/bin/caddy "$image" \
    validate --config /usr/share/caddy/Caddyfile --adapter caddyfile

printf 'Starting the restricted container...\n'
container_id="$("$engine" run --detach "${runtime_options[@]}" \
    --hostname dogcat-ci --publish 127.0.0.1::8080 "$image")"
host_port="$("$engine" port "$container_id" 8080/tcp \
    | sed -n 's/^127\.0\.0\.1:\([0-9][0-9]*\)$/\1/p')"
[[ -n "$host_port" && "$host_port" != *[!0-9]* ]] \
    || fail 'Could not find the ephemeral port bound to 127.0.0.1.'
base_url="http://127.0.0.1:${host_port}"

ready=false
for ((attempt = 1; attempt <= 30; attempt++)); do
    http_status="$(curl --silent --show-error --connect-timeout 1 --max-time 2 \
        --output "$temp_dir/page.html" --write-out '%{http_code}' "$base_url/" \
        2>"$temp_dir/curl-error")" || http_status=''
    if [[ "$http_status" == 200 ]]; then
        ready=true
        break
    fi
    [[ "$("$engine" inspect --format '{{.State.Running}}' "$container_id")" == true ]] \
        || fail 'The container exited before its HTTP server became ready.'
    sleep 1
done
[[ "$ready" == true ]] || fail 'The HTTP server did not become ready after 30 attempts.'

for request_path in / /index.html; do
    http_status="$(curl --silent --show-error --connect-timeout 2 --max-time 5 \
        --output "$temp_dir/page.html" --write-out '%{http_code}' "$base_url$request_path")" \
        || fail "Could not request $request_path."
    [[ "$http_status" == 200 ]] || fail "$request_path returned HTTP $http_status instead of 200."
    grep -Fq -- 'Server: dogcat-ci' "$temp_dir/page.html" \
        || fail "$request_path is missing the container hostname."
    if grep -Fq -- '$REPLACE' "$temp_dir/page.html" || grep -Fq -- '{{' "$temp_dir/page.html"; then
        fail "$request_path contains an unreplaced hostname placeholder."
    fi
done

"$engine" exec "$container_id" /usr/bin/bash -euc \
    'printf "%s\n" "Private smoke test file" > /tmp/smoke-private.txt'

for request_path in \
    /Dockerfile /.git/config /.dockerignore /smoke-private.txt \
    /config/ /data/ /data/caddy/instance.uuid; do
    http_status="$(curl --silent --show-error --connect-timeout 2 --max-time 5 \
        --output /dev/null --write-out '%{http_code}' "$base_url$request_path")" \
        || fail "Could not request $request_path."
    [[ "$http_status" == 404 ]] || fail "$request_path returned HTTP $http_status instead of 404."
done

runtime_user="$("$engine" inspect --format '{{.Config.User}}' "$container_id")"
[[ "$runtime_user" == 10001:10001 ]] \
    || fail "The container user is $runtime_user instead of 10001:10001."
runtime_entrypoint="$("$engine" inspect --format '{{json .Config.Entrypoint}}' "$container_id")"
[[ "$runtime_entrypoint" == '["/usr/local/bin/entrypoint.sh"]' ]] \
    || fail "The container entrypoint is $runtime_entrypoint instead of entrypoint.sh."
"$engine" exec "$container_id" /usr/bin/bash -euc \
    'IFS= read -r process_name < /proc/1/comm; [[ "$process_name" == caddy ]]' \
    || fail 'The entrypoint did not replace itself with Caddy as PID 1.'

printf 'Checking graceful shutdown...\n'
"$engine" stop --time 10 "$container_id" >/dev/null
exit_code="$("$engine" inspect --format '{{.State.ExitCode}}' "$container_id")"
[[ "$exit_code" == 0 ]] || fail "The container exited with status $exit_code after shutdown."

printf 'Smoke test passed for %s: HTTP routes, hostname, UID 10001, and graceful shutdown.\n' "$image"
