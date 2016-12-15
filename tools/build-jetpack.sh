#!/bin/bash
RED='\033[0;31m'
trap 'exit_build' ERR

function exit_build {
    echo -e "${RED}Something went wrong and the build has stopped.  See error above for more details."
    exit 1
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
CLEANUP=0
ADD_BETA_VERSION=0

while getopts "db" opt; do
    case "$opt" in
    d)  CLEANUP=1
        ;;
    b)  ADD_BETA_VERSION=1
        ;;
    esac
done

shift $((OPTIND-1))

GET_VERSION_SCRIPT="`pwd`/tools/get-version.sh"
TARGET_BRANCH=${1:-master}
TARGET_DIR=${2:-"/tmp/jetpack"}

[ "$1" = "--" ] && shift

if [[ $CLEANUP -eq 1 ]]; then
    echo "Cleaning up existing paths.."
    rm -rf $TARGET_DIR
    echo "Done!"
fi

git clone \
    --branch $TARGET_BRANCH \
    --depth 1000 \
    https://github.com/Automattic/jetpack.git \
    $TARGET_DIR

cd $TARGET_DIR

if [[ $ADD_BETA_VERSION -eq 1 ]]; then
    echo "Changing version of the Jetpack to reflect the latest changes.."
    CURRENT_VERSION="`$GET_VERSION_SCRIPT`"

    sed -i -e 's/Version: .*$/Version: '$CURRENT_VERSION'/' jetpack.php
    echo "Now at version $CURRENT_VERSION!"
fi

npm install
npm run build-production

echo "Purging paths included in .svnignore, .gitignore and .git itself"
# check .git
for file in $( cat "$TARGET_DIR/.gitignore" | grep -v '#' 2>/dev/null ); do
    rm -rf $TARGET_DIR/$file
done
# check .svnignore
for file in $( cat "$TARGET_DIR/.svnignore" 2>/dev/null ); do
    rm -rf $TARGET_DIR/$file
done
echo "Done!"

