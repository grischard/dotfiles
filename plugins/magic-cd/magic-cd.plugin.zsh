

alias ds='pushd'
alias dp='popd'
alias cd..="cd .."

local colored="$(tput setaf 7 2>/dev/null)"
local resetcolor="$(tput sgr0 2>/dev/null)"

# simple method to handle multiple cd customizations
function _next_cd() { _next_cd_false=1 ; }
function _next_cd_reset() { _next_cd_false=0 ; }
function _next_cd_test() { return ${_next_cd_false} ; }
_next_cd_false=1

if [[ -n "$ZSH_VERSION" ]] ; then
    function _multidot_cd() {
        # allow cd ... and such
        if [[ -n "$1" && "$1" =~ (^\\.+$) && (( "${#1}" > 2 )) ]] ; then
            local n
            local d
            n=${#1}
            for i in $(eval echo "{2..$n}") ; do
                d=$d"../"
            done
            echo $d 1>&2
            _real_cd "$d"
        else
            _next_cd "$@"
        fi
    }
else

function _multidot_cd() {
    # allow cd ... and such
    if [[ -n "$1" && "$1" =~ (^\.+$) && (( "${#1}" > 2 )) ]] ; then
        local n
        local d
        n=${#1}
        for i in $(eval echo "{2..$n}") ; do
            d=$d"../"
        done
        echo $d 1>&2
        _real_cd "$d"
    else
        _next_cd "$@"
    fi
}
fi

function _git_cd() {
  if [[ "$1" != "" ]]; then
    _next_cd "$@"
  else
    local OUTPUT
    OUTPUT="$(git rev-parse --show-toplevel 2>/dev/null)"
    [[ "$OUTPUT" == "$PWD" ]] && OUTPUT="$(cd ..; git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -e "$OUTPUT" ]]; then _real_cd "$OUTPUT" ; else _next_cd ; fi
  fi
}

function _package_cd() {
  if [[ "$1" != "" ]]; then
    _next_cd "$@"
  else
    local d
    d="$(dirname "$PWD")"
    while [[ "$d" != "/" ]]; do
      if [[ -f "$d/package.json" ]]; then
        _real_cd "$d"
        break
      fi
    done
  fi
}

function _cd_to_file() {
    if [[ -f "$1" ]]; then
        builtin cd $(dirname "$1")
    else
        _next_cd "$@"
    fi
}

function _real_cd() {
    builtin cd "$@"

    # if the new directory is a symlink, print the actual physical directory
    local REAL_PWD
    REAL_PWD=$(pwd -P)
    if [[ "$REAL_PWD" != $(pwd) ]]; then
        echo -n "${colored}${REAL_PWD}${resetcolor}" >&2
        echo >&2
        # echo " ('cd -P .' to go there)" >&2
    fi

}

function cd() {
    _next_cd_reset
    # echo d 1>&2

    _multidot_cd "$@"
    if _next_cd_test ; then return ; fi ; _next_cd_reset
    # echo c 1>&2

    _git_cd "$@"
    if _next_cd_test ; then return ; fi ; _next_cd_reset
    # echo b 1>&2

    # todo: place before git cd and fix infinite loop
    # _package_cd "$@"
    # if _next_cd_test ; then return ; fi ; _next_cd_reset

    _cd_to_file "$@"
    if _next_cd_test ; then return ; fi
    # echo a 1>&2

    # TODO: cd to zshmarks

    _real_cd "$@"
}
