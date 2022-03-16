#!/bin/bash -e

# Export Fossil repository so it can be pushed to GitLab/GitHub

# Copyright (C) 2019  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

FOSSIL_CHECKOUT=$(dirname $(readlink -f $0))

# Populate authors list if needed
(
    cd $FOSSIL_CHECKOUT/
    if ! fossil user capabilities Beuc > /dev/null; then
	fossil user new Beuc beuc@beuc.net ''
    fi
)

# Convert commits
(cd $FOSSIL_CHECKOUT/ && fossil export --git) \
  | git fast-import
git reset HEAD .
git checkout .
