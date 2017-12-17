#!/bin/bash

echo
echo +++++++++++++++++++++++++++ AWS DEPLOYMENT ++++++++++++++++++++++++++++++

#
# Begin functions
#

function end() {
  echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  echo
  exit
}

function create_environment() {
  aws elasticbeanstalk create-environment --cname-prefix $ENV_NAME --application-name $APP_NAME --version-label $APP_FILE_VERSIONED --environment-name $ENV_NAME --solution-stack-name "$STACK" --option-settings "[
            {
                \"Namespace\": \"aws:autoscaling:launchconfiguration\",
                \"OptionName\": \"InstanceType\",
                \"Value\": \"${INSTANCE_TYPE}\"
            },
            {
                \"Namespace\": \"aws:autoscaling:launchconfiguration\",
                \"OptionName\": \"SecurityGroups\",
                \"Value\": \"${SECURITY_GROUP}\"
            },
            {
                \"Namespace\": \"aws:autoscaling:launchconfiguration\",
                \"OptionName\": \"EC2KeyName\",
                \"Value\": \"${EC2_KEY_NAME}\"
            }
        ]" >/dev/null 2>&1
}

#
# End functions
#

# Usage
if [ "${1}" != "deploy" ] && [ "${1}" != "terminate" ]; then
  echo "Usage: ./aws.sh deploy | terminate | terminate app"
  end
fi

# Get platform
PLATFORM=$(uname)

# Check platform
if [ "$PLATFORM" != "Linux" ] && [ "$PLATFORM" != "Darwin" ]; then
  echo Your platform \"$PLATFORM\" is not supported
  end
fi

# Check awscli installation
if ! hash aws 2>/dev/null; then
  echo awscli is not installed
  end
fi

# Check jq installation
if ! hash jq 2>/dev/null; then
  echo jq is not installed
  end
fi

# Check gdate (macOS only)
if [ "$PLATFORM" == "Darwin" ]; then
  if ! hash gdate 2>/dev/null; then
    echo gdate is not installed
    end
  fi
fi

# Check awscli configurations
if [ ! -f ~/.aws/config ] || [ ! -f ~/.aws/credentials ]; then
  echo awscli is not configured
  end
fi

########################
# Start configurations #
########################

# AWS application name
readonly APP_NAME="CHANGE-TO-YOUR-APP-NAME"
# Detect git branch
readonly APP_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
# Application file name
readonly APP_FILE=${APP_NAME}-${APP_BRANCH}
# Environment name (AWS Elastic Beanstalk CNAME)
readonly ENV_NAME=${APP_FILE}
# Use timestamp as unique build number
readonly BUILD_NUMBER=$(date '+%Y%m%d-%H%M%S')
# Unique file name used for versioning
readonly APP_FILE_VERSIONED=${APP_FILE}-${BUILD_NUMBER}
# Public web directory
readonly PUBLIC_WEB_DIR="public_html"
# Platform stack
readonly STACK="64bit Amazon Linux 2017.09 v2.6.0 running PHP 7.1"
# EC2 instance type
readonly INSTANCE_TYPE="t2.micro"
# Security group
readonly SECURITY_GROUP="CHANGE-TO-YOUR-SECURITY-GROUP"
# EC2 key pair name
readonly EC2_KEY_NAME="CHANGE-TO-YOUR-KEY-NAME"
# S3 bucket name
readonly S3_BUCKET="CHANGE-TO-YOUR-S3-BUCKET"
# S3 directory
readonly S3_BUCKET_DIR="apps/${APP_NAME}/${APP_BRANCH}"
# S3 file name
readonly S3_BUCKET_FILE=${S3_BUCKET_DIR}/${APP_FILE_VERSIONED}.zip
# Delete S3 file?
readonly S3_DELETE=1
# Delete S3 file "n" days old
readonly S3_DELETE_DAYS_OLD=7
# Open environment in browser after update
readonly OPEN_IN_BROWSER_AFTER_UPDATE=1

######################
# End configurations #
######################

# Whether or not anything has been updated
UPDATED=0

# Check if app exists
APP_EXISTS=($(aws elasticbeanstalk describe-application-versions --application-name $APP_NAME | jq -r '.ApplicationVersions[].ApplicationName'))
# Check if environment available
ENV_AVAILABLE=($(aws elasticbeanstalk check-dns-availability --cname-prefix $ENV_NAME | jq -r '.Available'))
# Check environment health
ENV_HEALTH=($(aws elasticbeanstalk describe-environments --environment-names $ENV_NAME | jq -r '.Environments[].Health'))

# Terminate
if [ "${1}" == "terminate" ]; then
  if [ "$APP_EXISTS" == "" ]; then
    echo "APPLICATION DOESN'T EXIST"
    end
  fi

  # Terminate application
  if [ "${2}" == "app" ]; then
    echo "APPLICATION AND ALL IT'S RUNNING ENVIRONMENTS ARE TERMINATING..."
    aws elasticbeanstalk delete-application --application-name $APP_NAME --terminate-env-by-force >/dev/null 2>&1
    end
  elif [ "$ENV_AVAILABLE" == "false" ]; then
    # Terminate environment
    if [ "$ENV_HEALTH" == "Green" ]; then
      echo "EVIRONMENT IS TERMINATING..."
      aws elasticbeanstalk terminate-environment --environment-name $ENV_NAME >/dev/null 2>&1
      end
    else
      echo "ENVIRONMENT IS NOT READY, TRY AGAIN LATER"
      end
    fi
  else
    echo "ENVIRONMENT NOT FOUND"
    end
  fi
fi

# Continue with deployment

#####################################################
# BEGIN - BUILD YOUR WEB CONTENT (public_html) HERE #
#####################################################

#####################################################
# END                                               #
#####################################################

# Remove previous build
rm -f /tmp/$APP_FILE.zip

# Zip up web content
echo ZIPPING UP WEB CONTENT IN $PUBLIC_WEB_DIR
cd ./$PUBLIC_WEB_DIR
zip -qr /tmp/$APP_FILE.zip .
cd - >/dev/null 2>&1

echo "BUILT APP LOCALLY ON /tmp/${APP_FILE}.zip"

# Send app to S3
echo "SENDING APP TO S3: ${S3_BUCKET_FILE}"
aws s3 cp --quiet /tmp/$APP_FILE.zip s3://${S3_BUCKET}/$S3_BUCKET_FILE

echo "SETTING UP..."

# App doesn't exists
if [ "$APP_EXISTS" == "" ]; then

  if [ "$ENV_AVAILABLE" == "true" ]; then
  
    # Create application and environment
    aws elasticbeanstalk create-application --application-name $APP_NAME --description "$APP_NAME" >/dev/null 2>&1
    aws elasticbeanstalk create-application-version --application-name $APP_NAME --version-label $APP_FILE_VERSIONED --description $ENV_NAME --source-bundle S3Bucket="$S3_BUCKET",S3Key="$S3_BUCKET_FILE" >/dev/null 2>&1
    create_environment

    UPDATED=1
    echo "SUCCESSFULLY CREATED APPLICATION AND ENVIRONMENT"

  else

    # Can't create
    echo "ENVIRONMENT NAME $APP_NAME IS NOT AVAILABLE"
    # Clean up
    aws s3 rm s3://${S3_BUCKET}/$S3_BUCKET_FILE >/dev/null 2>&1

  fi

else

  # App exists
  if [ "$ENV_AVAILABLE" == "true" ]; then

    # Create environment
    aws elasticbeanstalk create-application-version --application-name $APP_NAME --version-label $APP_FILE_VERSIONED --description $ENV_NAME --source-bundle S3Bucket="$S3_BUCKET",S3Key="$S3_BUCKET_FILE" >/dev/null 2>&1
    create_environment

    UPDATED=1
    echo "SUCCESSFULLY CREATED ENVIRONMENT"

  else

    # Update environment
    if [ "$ENV_HEALTH" == "Green" ]; then

      aws elasticbeanstalk create-application-version --application-name $APP_NAME --version-label $APP_FILE_VERSIONED --description $ENV_NAME --source-bundle S3Bucket="$S3_BUCKET",S3Key="$S3_BUCKET_FILE" >/dev/null 2>&1
      ENV_ID=($(aws elasticbeanstalk describe-environments --application-name $APP_NAME | jq -r '.Environments[].EnvironmentId'))
      aws elasticbeanstalk update-environment --environment-id $ENV_ID --version-label "$APP_FILE_VERSIONED" >/dev/null 2>&1

      UPDATED=1
      echo "SUCCESSFULLY UPDATED ENVIRONMENT"

    else

      echo "ENVIRONMENT IS NOT READY, TRY AGAIN LATER"
      # Clean up
      aws s3 rm s3://${S3_BUCKET}/$S3_BUCKET_FILE >/dev/null 2>&1

    fi

  fi

fi

# Clean up old app files
if [ "$S3_DELETE" -eq 1 ] && [ "$UPDATED" -eq 1 ]; then
  echo "TRY TO DELETE OLD S3 FILES($S3_DELETE_DAYS_OLD days old) at s3://${S3_BUCKET}/${S3_BUCKET_DIR}"
  ./delete-s3.sh "s3://${S3_BUCKET}/$S3_BUCKET_DIR" "${S3_DELETE_DAYS_OLD} days"
fi

if [ "$UPDATED" -eq 1 ]; then

  # Get environment URL
  ENV_URL=($(aws elasticbeanstalk describe-environments --environment-names $ENV_NAME | jq -r '.Environments[].CNAME'))
  echo "ENVIRONMENT WILL BE SHORTLY AT: http://${ENV_URL}"

  # Open in browser
  if [ "$OPEN_IN_BROWSER_AFTER_UPDATE" -eq 1 ]; then
    open http://$ENV_URL
  fi
fi

end
