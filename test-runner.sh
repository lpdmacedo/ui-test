#! /bin/bash
#source /commands/load_grails.sh /app/application.properties

apt-get --assume-yes  install libfontconfig1

#Initialize variables to default values.
SCRIPT_NAME=TEST-RUNNER
UI_TEST_FOLDER=/app/ui-test
APP_FOLDER=/app
OPT_ENV=local
OPT_SITE=mla
OPT_BROWSER=phantom
PATH_NODE_MODULES=./node_modules

ENV_LOCAL_REMOTE=local_remote
ENV_JENKINS=jenkins
ENV_JENKINS_REMOTE=jenkins_remote

#Help function
help() {
  echo "Help documentation for ${SCRIPT_NAME}."
  echo "Command line switches are optional. The following switches are recognized."
  echo "-e  --Sets the value for option env. Default is $OPT_ENV [$ENV_LOCAL_REMOTE - $ENV_JENKINS - $ENV_JENKINS_REMOTE]."
  echo "-s  --Sets the value for option site. Default is $OPT_SITE."
  echo "-b  --Sets the value for option browser. Default is $OPT_BROWSER."
  echo "-h  --Displays this help message."
  echo "Example: SCRIPT_NAME -e local -b chrome -s mla"
  exit 1
}

###... Wait To Start App ...###
waitForPing() {
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

###... Start Selenium Server ...###
startSeleniumServer() {
  COUNT=0
    cd $UI_TEST_FOLDER
    java -jar ./node_modules/selenium-standalone/.selenium/selenium-server/2.50.1-server.jar -browser "browserName=$OPT_BROWSER,platform=LINUX" &
    echo "Waiting for start selenium-server"
    while [ $COUNT -lt 1200 ]; do
      OUT=$(curl --write-out %{http_code} --silent --output /dev/null http://127.0.0.1:4444/wd/hub/status)
      if [ "$OUT" -eq "200" ]; then
          echo "Selenium started"
          return
      fi
      sleep 1;
      COUNT=$(( $COUNT + 1 ))
    done
    echo "Wait for /wd/hub/status timedout"
    exit 100
}

#... Install functional test dependencies ...#
installDependencies() {
    cd $UI_TEST_FOLDER
    npm cache clean
  npm install
  npm install -g nightwatch
  ./node_modules/selenium-standalone/bin/selenium-standalone install
}

###... Run Local App ...###
runApplication() {
    echo "------- Starting grails app -------"
    echo "-------" $GRAILS_OPTS
    cd $APP_FOLDER
  grails $GRAILS_OPTS run-app --non-interactive &
}


###... Test Execution ...###
executeTest() {
    echo "------- Test Execution -------"
    installDependencies
  startSeleniumServer
  runApplication

  cd $UI_TEST_FOLDER
  nightwatch -e $OPT_BROWSER

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
}

#Parse command line flags
while getopts :e:s:b:h FLAG; do
  case $FLAG in
    e)  #set option "env"
      OPT_ENV=$OPTARG
      echo "-e used: $OPTARG"
      export UI_TEST_ENV=$OPTARG
      ;;
    s)  #set option "site"
      OPT_SITE=$OPTARG
      echo "-s used: $OPTARG"
      export UI_TEST_SITE=$OPTARG
      ;;
    b)  #set option "browser"
      OPT_BROWSER=$OPTARG
      echo "-b used: $OPTARG"
      export UI_TEST_BROWSER=$OPTARG
      ;;
    h)  #show help
      help
      ;;
    \?) #unrecognized option - show help
      echo \\n"Option -$OPTARG not allowed."
      help
      ;;
  esac
done

shift $((OPTIND-1))

### End getopts code ###
executeTest
echo "Build is being generated, don't run tests..."
exit 0


