#!/bin/bash -e

$PSQL -t <<EOF | bash
select
  'curl -X PUT localhost:8000/_/action/'
    || id
    || ' --data ''{"targetGroup":"23"}'''
  from actiontbl where targetGroup = 'back';
EOF
