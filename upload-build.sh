#!/usr/bin/env bash

set -veuo pipefail

# Helper function to perform a GitHub API call
function gh_call() {
    local req="$1"
    local server="$2"
    local endpoint="$3"
    shift
    shift
    shift

    resp="$(curl -Lfu "$GH_USER:$GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -X "$req" \
        "https://$server.github.com/repos/$GH_REL_REPO/$endpoint" \
        "$@")" || \
        { ret="$?"; echo "Request failed with exit code $ret:"; cat <<< "$resp"; return $ret; }

    cat <<< "$resp"
}

# Helper function to send a Telegram message
function tg_send() {
    local msg_type="$1"
    shift

    local args=()
    for arg in "$@"; do
        args+=(-F "$arg")
    done

    curl -sf --form-string chat_id="$TG_CHAT_ID" \
        "${args[@]}" \
        "https://api.telegram.org/bot$TG_TOKEN/send$msg_type" \
        > /dev/null
}

# Generate build info
rel_date="$(date "+%Y%m%d")" # ISO 8601 format
rel_friendly_date="$(date "+%B %-d, %Y")" # "Month day, year" format

# Generate product name
clang_version="$(install/bin/clang --version | head -n1 | cut -d' ' -f4)"
product_desc="proton_clang-$clang_version-$rel_date"
product_name="$product_desc.tar.zst"

# Create tar.zst package
mv install "$product_desc"
tar cf - "$product_desc" | zstd -T0 --ultra -20 - -o "$product_name"
product_size="$(du -h --apparent-size "$product_name" | awk '{print $1}')"

# Generate release info
builder_commit="$(git rev-parse HEAD)"
pushd llvm-project
llvm_commit="$(git rev-parse HEAD)"
short_llvm_commit="$(cut -c-8 <<< $llvm_commit)"
popd

llvm_commit_url="https://github.com/llvm/llvm-project/commit/$llvm_commit"
binutils_ver="$(ls | grep "^binutils-" | sed "s/binutils-//g")"

# Update Git repository
git clone "https://$GH_USER:$GH_TOKEN@github.com/$GH_REL_REPO" rel_repo
pushd rel_repo
rm -fr *
cp -r "../$product_desc/"* .
git checkout README.md # keep this as it's not part of the toolchain itself
git add .
git commit -am "Update to $rel_date build

LLVM commit: $llvm_commit_url
binutils version: $binutils_ver
Builder commit: https://github.com/$GH_BUILD_REPO/commit/$builder_commit"
git push
popd

# Delete the existing release if necessary
resp="$(gh_call GET api "releases/tags/$rel_date" -sS)" && \
    old_rel_id="$(jq .id <<< "$resp")" && \
    gh_call DELETE api "releases/$old_rel_id" -sS

# Create new release
payload="$(cat <<END
{
    "tag_name": "$rel_date",
    "target_commitish": "master",
    "name": "$rel_friendly_date",
    "body": "Automated build of LLVM + Clang $clang_version as of commit [$short_llvm_commit]($llvm_commit_url) and binutils $binutils_ver."
}
END
)"
resp="$(gh_call POST api "releases" --data-binary "@-" -sS <<< "$payload")"
rel_url="$(jq -r .html_url <<< "$resp")"
rel_id="$(jq .id <<< "$resp")"
echo "Release created: $rel_url"
echo "Release ID: $rel_id"

# Upload build as asset
resp="$(gh_call POST uploads "releases/$rel_id/assets?name=$product_name" -H "Content-Type: application/zstd" --data-binary "@$product_name")"
asset_url="$(jq -r .browser_download_url <<< "$resp")"
echo "Direct download link: $asset_url"

# Send Telegram notification
set +u  # we're checking potentially unset variables here
if [[ -n "$TG_CHAT_ID" ]] && [[ -n "$TG_TOKEN" ]]; then
    if [[ -n "$GH_RUN_ID" ]]; then
        build_desc="[$rel_date build](https://github.com/$GH_BUILD_REPO/runs/$GH_RUN_ID)"
    else
        build_desc="*$rel_date build*"
    fi
    set -u

    tg_send Message parse_mode=Markdown disable_web_page_preview=true text="$build_desc on LLVM commit [$short_llvm_commit]($llvm_commit_url) is now available: [tarball]($asset_url) or [Git repository](https://github.com/$GH_REL_REPO)"
fi
