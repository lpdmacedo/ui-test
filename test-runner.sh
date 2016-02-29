#! /bin/bash

apt-get --assume-yes  install libfontconfig1

#Initialize variables to default values.
SCRIPT_NAME=TEST-RUNNER
UI_TEST_FOLDER=/ui-test
APP_FOLDER=/app
OPT_ENV=local
OPT_SITE=mla
OPT_BROWSER=phantom
PATH_NODE_MODULES=./node_modules

ENV_LOCAL_REMOTE=local_remote
ENV_JENKINS=jenkins
ENV_JENKINS_REMOTE=jenkins_remote

#Set fonts for Help.
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`

cd $UI_TEST_FOLDER

#Help function
function HELP {
  echo  \\n"Help documentation for ${BOLD}${SCRIPT_NAME}.${NORM}"\\n
  echo "Command line switches are optional. The following switches are recognized."
  echo "${REV}-e${NORM}  --Sets the value for option ${BOLD}env${NORM}. Default is ${BOLD}$OPT_ENV [$ENV_LOCAL_REMOTE - $ENV_JENKINS - $ENV_JENKINS_REMOTE]${NORM}."
  echo "${REV}-s${NORM}  --Sets the value for option ${BOLD}site${NORM}. Default is ${BOLD}$OPT_SITE${NORM}."
  echo "${REV}-b${NORM}  --Sets the value for option ${BOLD}browser${NORM}. Default is ${BOLD}$OPT_BROWSER${NORM}."
  echo "${REV}-h${NORM}  --Displays this help message."\\n
  echo "Example: ${BOLD}$SCRIPT -e local -b chrome -s mla${NORM}"\\n
  exit 1
}

#Check the number of arguments. If none are passed, print help and exit.
NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  HELP
fi

### Start getopts code ###

#Parse command line flags
while getopts :e:s:b:h FLAG; do
  case $FLAG in
    e)  #set option "a"
      OPT_ENV=$OPTARG
      echo "-e used: $OPTARG"
      export UI_TEST_ENV=$OPTARG
      ;;
    s)  #set option "b"
      OPT_SITE=$OPTARG
      echo "-s used: $OPTARG"
      export UI_TEST_SITE=$OPTARG
      ;;
    b)  #set option "c"
      OPT_BROWSER=$OPTARG
      echo "-b used: $OPTARG"
      export UI_TEST_BROWSER=$OPTARG
      ;;
    h)  #show help
      HELP
      ;;
    \?) #unrecognized option - show help
      echo \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      HELP
      ;;
  esac
done

shift $((OPTIND-1))

### End getopts code ###

###... Wait To Start App ...###
function waitForPing() {
  COUNT=0
  echo "Waiting for app up"
  while [[ $COUNT -lt 1200 ]]; do
    OUT=$(curl -m 1 --write-out %{http_code} --silent --output /dev/null 127.0.0.1:8080/ping)
    if [[ "$OUT" == "200" ]]; then
      echo "App started"
      return
    fi
    sleep 1;
    COUNT=$(( $COUNT + 1 ))
  done
  echo "Wait for /ping timedout"
  exit 100
}

###... Wait To Start Selenium Server ...###
function waitForSeleniumServer() {
	OUNT=0
  	echo "Waiting for start selenium-server"
  	while [[ $COUNT -lt 1200 ]]; do
    	response=$(curl --write-out %{http_code} --silent --output /dev/null http://localhost:4444/wd/hub/status)
    	if [[ "$OUT" == "200" ]]; then
      		echo "Selenium started"
      		return
    	fi
    	sleep 1;
    	COUNT=$(( $COUNT + 1 ))
  	done
  echo "Wait for /wd/hub/status timedout"
  exit 100
}

###... Run Local App ...###
function run_application() {
	grails $GRAILS_OPTS run-app &
}


###... Test Execution ...###
function executeTest() {
	cd $APP_FOLDER
	grails GRAILS_OPTS test-app --non-interactive

	if [[ $OPT_ENV -eq local ]]; then
		run_application
		waitForPing
	fi

	cd $UI_TEST_FOLDER

	if [ -d $PATH_NODE_MODULES ]; then
		nightwatch -e $OPT_BROWSER
  	else
  		npm run e2e
		nightwatch -e $OPT_BROWSER
	fi

	status=$?
  	echo "Terminating jobs..."
  	jobs -p | xargs kill
	  running=$(jobs | wc -l)
	  count=0
	  while [ $running -gt 0 ]; do
	    if [ $count -gt 30 ]; then
	        break
	    fi
	    sleep 1
	    count=$(( $count + 1 ))
	    running=$(jobs | wc -l)
	  done
	  if [ $running -gt 0 ]; then
	      echo "Killing jobs..."
	      jobs -p | xargs kill -9
	  fi
	  exit $status
	
	#Customize script to run selenium server manually
	#npm install
	#npm install -g nightwatch
	#./node_modules/selenium-standalone/bin/selenium-standalone install
	#java -jar ./node_modules/selenium-standalone/.selenium/selenium-server/2.50.1-server.jar -browser "browserName=$OPT_BROWSER,platform=LINUX" &
	#waitForSeleniumServer
	#npm run e2e
	#nightwatch -e $OPT_BROWSER
}

if [ $NUMARGS -gt 0 ]; then
  	executeTest
else
	echo "Build is being generated, don't run tests..."
	exit 0
fi



