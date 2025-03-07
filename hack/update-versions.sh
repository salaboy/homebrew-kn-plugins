#! /usr/bin/env bash

# Copyright 2022 The Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

PLUGINS=("admin" "event" "quickstart" "source-kafka" "source-kamelet")
CURRENT_RELEASE=${CURRENT_RELEASE:-1.7}
PREVIOUS_RELEASE=${PREVIOUS_RELEASE:-1.6}

for plugin in "${PLUGINS[@]}"; do

    echo "Updating kn-$plugin from $PREVIOUS_RELEASE to $CURRENT_RELEASE"
    newfile="${plugin}.rb"
    oldfile="${plugin}@${PREVIOUS_RELEASE}.rb"

    echo "Create formula for previous release"
    cp "$newfile" "$oldfile"
    class_version=${PREVIOUS_RELEASE//.}
    if [[ $plugin =~ "-" ]]; then
        classparts="$plugin"
        IFS='-'
        read -ra classnameparts <<< $classparts
        class_name="${classnameparts[0]^}${classnameparts[1]^}"
        unset IFS
    else
        class_name=${plugin^}
    fi
    sed -i '' 's/class '${class_name}' < Formula/class '${class_name}'AT'$class_version' < Formula/' "$oldfile"
    echo "$oldfile created"

    echo "Creating formula for current release"
    #sed -i 's/v = "v'$PREVIOUS_RELEASE'/v = "v'$CURRENT_RELEASE'/' $newfile
    sed -i '' 's/v'${PREVIOUS_RELEASE}'/v'$CURRENT_RELEASE'/g' "$newfile"

    # change shas for mac and linux
    checksums=$(mktemp)
    old_checksums=$(mktemp)
    curl -L "https://github.com/knative-sandbox/kn-plugin-${plugin}/releases/download/knative-v${CURRENT_RELEASE}.0/checksums.txt" > "$checksums"
    curl -L "https://github.com/knative-sandbox/kn-plugin-${plugin}/releases/download/knative-v${PREVIOUS_RELEASE}.0/checksums.txt" > "$old_checksums"
    darwin_checksum=$(awk '$2=="kn-'"$plugin"'-darwin-amd64"{print $1}' $checksums)
    darwin_old_checksum=$(awk '$2=="kn-'"$plugin"'-darwin-amd64"{print $1}' $old_checksums)
    sed -i '' 's/sha256 "'$darwin_old_checksum'"/sha256 "'$darwin_checksum'"/' "$newfile"
    linux_checksum=$(awk '$2=="kn-'"$plugin"'-linux-amd64"{print $1}' $checksums)
    linux_old_checksum=$(awk '$2=="kn-'"$plugin"'-linux-amd64"{print $1}' $old_checksums)
    sed -i '' 's/sha256 "'$linux_old_checksum'"/sha256 "'$linux_checksum'"/' "$newfile"

    echo "$newfile created"

done 

echo "Have a nice day!"
