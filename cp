#!/bin/bash

if [[ $1 == '-r' ]]; then
  1>&2 echo ""
  1>&2 echo "*********************** BAD BOY **************************"
  1>&2 echo "* Never use 'cp -r'; use 'cp -R' instead.                *"
  1>&2 echo "* If you really meant 'cp -r', you're probably wrong,    *"
  1>&2 echo "* but you can override this check by typing '/bin/cp -r' *"
  1>&2 echo "**********************************************************"
  1>&2 echo ""
  exit 1
fi

/bin/cp "$@"
