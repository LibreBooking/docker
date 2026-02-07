APP_TAG=''
APP_REP_URL='https://api.github.com/repos/librebooking/app/tags?per_page=100'

.phony: all

all:
	@echo ${APP_TAG}
	@echo ${APP_REP_URL}
	if [ -z "${APP_TAG}" ]; then \
          APP_TAG=`curl --silent ${APP_REP_URL} \
            | sed -n 's/.*"name": "\([^"]*\)".*/\1/p' \
            | sort -V | tail -n 1)` ; fi
	echo ${APP_TAG}


