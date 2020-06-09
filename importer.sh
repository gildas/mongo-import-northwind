#!/usr/bin/env bash

VERBOSE=0
NOOP=
ARGS=()
MONGO_HOST=
MONGO_DB=Northwind
COLLECTIONS=()

function verbose() { [[ $VERBOSE == 1 ]] && echo -e "$@"; }
function warn()    { echo -e "\033[33mWarning: $@\033[0m"; }
function error()   { echo -e "\033[1;31mError: $@\033[0m" >&2; }
function die()     { error "$1" ; exit ${2:-1} ; }
function die_on_error() { local status=$?; [[ $status != 0 ]] && die "$@, Error: $status" $status || return 0; }
                                                                                                                                                                                                                                   
function join() { local sep="$1"; shift; echo -n "$1"; shift; printf "%s" "${@/#/$sep}"; }

function usage() { # {{{2
  echo "$(basename $0) [options]"
  echo "  Import the Northwind DB into a container running Mongo"
  echo "  Options are:"
  echo " --collections names  "
  echo "   Will import the comma separated list of collection \"names\"."
  echo "   Default: categories,customers,employee-territories,employees,northwind,order-details,"
  echo "            orders,products,regions,shippers,suppliers,territories"
  echo " --host hostname_or_ip, --mongo hostname_or_ip  "
  echo "   Will import data into the Mongo server \"hostname_or_ip\"."
  echo "   Default: none"
  echo " --db database  "
  echo "   Will import data into the Database \"database\"."
  echo "   Default: Northwind"
  echo " --help  "
  echo "   Prints some help on the output."
  echo " --noop, --dry-run  "
  echo "   Do not execute instructions that would make changes to the system (write files, install software, etc)."
  echo " --quiet  "
  echo "   Runs the script as silently as possible."
  echo " --verbose  "
  echo "   Runs the script verbosely, that's by default."
  echo " --yes, --assumeyes, -y  "
  echo "   Answers yes to any questions automatiquely."
} # 2}}}

function parse_args() { # {{{2
  while (( "$#" )); do
    # Replace --parm=arg with --parm arg
    [[ $1 == --*=* ]] && set -- "${1%%=*}" "${1#*=}" "${@:2}"
    case $1 in
      --collections)
        [[ -z $2 || ${2:0:1} == '-' ]] && die "Argument for option $1 is missing"
        readarray -td '' COLLECTIONS < <(awk '{ gsub(/, */,"\0"); print; }' <<<"$2, "); unset 'a[-1]'
        shift 2
        continue
      ;;
    --host|--mongo)
        [[ -z $2 || ${2:0:1} == '-' ]] && die "Argument for option $1 is missing"
        MONGO_HOST=$2
        shift 2
        continue
      ;;
    --db)
        [[ -z $2 || ${2:0:1} == '-' ]] && die "Argument for option $1 is missing"
        MONGO_DB=$2
        shift 2
        continue
      ;;

      # Standard options
      -h|-\?|--help)
       usage
       exit 0
       ;;
      --noop|--dry_run|--dry-run)
        warn "This program will execute in dry mode, your system will not be modified"
        NOOP=:
        ;;
     --quiet)
       VERBOSE=0
       ;;
     -v|--verbose)
       VERBOSE=$((VERBOSE + 1))
       ;;
     -?*) # Invalid options
       warn "Unknown option $1 will be ignored"
       ;;
     --) # Force end of options
       shift
       break
       ;;
     *)  # End of options
       ARGS+=( "$1" )
       break
       ;;
    esac
    shift
  done

  # Set all positional arguments back in the proper order
  eval set -- "${ARGS[@]}"

  # Validation
  [[ -z $MONGO_HOST ]] && (error "Missing Mongo Host" ; return 2)
  if [[ ${#COLLECTIONS[@]} == 0 ]]; then
    COLLECTIONS=(categories customers employees-territories employees northwind order-details orders products regions shippers suppliers territories)
  fi
  
  return 0
} # 2}}}

function main() {
  parse_args "$@" ; die_on_error "Failed to parse command line"

  verbose "Importing Mongo's Northwind Database into $MONGO_HOST"
  for collection in ${COLLECTIONS[@]}; do 
    verbose "Importing Collection $collection"
    curl -sSL https://raw.githubusercontent.com/tmcnab/northwind-mongo/master/${collection}.csv | \
      mongoimport -h $MONGO_HOST -d $MONGO_DB -c ${collection} --type csv --headerline
  done
}

main "$@"
