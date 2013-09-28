#!/bin/bash
MSG_OK='\033[32mOK\033[0m'
MSG_NO_SFV='\033[36mNo SFV\033[0m'
MSG_FAIL='\033[31mFAIL\033[0m'

for dir in `ls -1`; do
  if [ -d "$dir" ]; then
    if [ "`ls -1 $dir/*.sfv 2>/dev/null`" == "" ]; then
      echo -e "$dir $MSG_NO_SFV"
    else
      cfv -q -p $dir

      if [ "$?" == "0" ]; then
        echo -e "$dir $MSG_OK"
      else
        echo -e "$dir $MSG_FAIL"
      fi
    fi
  fi
done
