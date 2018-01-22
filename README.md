# AWS Elastic Beanstalk Deployment Boilerplate

Do you deploy to AWS Elastic Beanstalk? Do you need to run application in
multiple environments? If both answers are yes, read on.

This is a starting point repository for web application. You can use the
included scripts to customize application building and AWS deployment processes.
You are required to have some knowledge of AWS and bash scripting to be able
to configure and add on your custom code, however I have made this boilerplate
really simple and easy to understand.

Included scripts automate tasks below for you:
* Create or update an application in AWS
* Create or update an Elastic Beanstalk environment base on your GIT branch
* Archive application files in S3, also purges old files after configurable days
* **Seamlessly deploy your production(master branch) code to EBS without downtime.** See AWS [Blue/Green deployment](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.CNAMESwap.html) and beware of the DNS caveat noted in the documentation.

You're required to:
* Add your own web content
* Add on your own custom logics for application building. For examples, you might
need to move files around or configure database credentials
* Modify deployment processes to fit your needs

## Demo

In this demo, I created a new application with 3 environments in AWS Elastic Beanstalk using commands only.

![Alt Text](https://s3.amazonaws.com/azhao-public/github/aws-ebs-deploy-demo.gif)

Click [here](https://s3.amazonaws.com/azhao-public/github/aws-ebs-deploy-demo.webm) to see a high resolution video of the demo.

## Branches

* **master** This is the branch you want to start fresh
* **wordpress** This is the branch I experiment with Wordpress
* **beta** This is the branch I commit and test features

## Quick Start

* Install `awscli`, `jq`, `gdate` (macOS only) and configure `awscli`. See installation instructions below
* Change these values in `aws.sh`: `APP_NAME`, `SECURITY_GROUP`, `EC2_KEY_NAME` and `S3_BUCKET`. See value descriptions below
* Run `./aws.sh deploy`

## Prerequisites

### awscli

#### Ubuntu Linux
`apt-get install awcli`

#### macOS
`brew install awcli`

For installation instructions, go to http://docs.aws.amazon.com/cli/latest/userguide/installing.html.

#### Configure awscli
```
$ aws configure
AWS Access Key ID [None]: [YOUR ACCESS KEY ID]
AWS Secret Access Key [None]: [YOUR SECRET ACCESS KEY]
Default region name [None]: us-east-1
Default output format [None]: json
```

For configuration instructions, go to http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html.

### jq
jq is used to parse JSON data in bash.

#### Ubuntu Linux
`apt-get install jq`

#### macOS
`brew install jq`

### gdate (macOS only)
gdate is an GNU verion of `date` for macOS

`brew install coreutils`

## How to use

### Web Content
Put all your web content inside `/public_html`. Content will get served by web server of the stack of your choice. As long as the web server supports, you can have a PHP, ASP.net or completely static site.

You might also have a seaprate process that builds the content in the directory. For example: Webpack build of a React application.

Whatever and however you want to put the content there, it's up to you.

### ./public_html/.ebextensions/default.config

You can further configure a Elastic Beanstalk envionrment using the configuration files in `.ebextensions` directory.

For more details, go to http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/ebextensions.html.

### ./aws.sh

Below are the ariables you can customize in `aws.sh`.

Name | Description | Default Value           
--- | --- | ---
APP_NAME | Application name | **MUST CHANGE**
APP_BRANCH | GIT branch name | The script auto detects the branch name
APP_FILE | Application file name | Concatenation of `APP_FILE` and `APP_BRANCH`
ENV_NAME | Elastic Beanstalk domain name (`CNAME`). It's possible that your CNAME might be taken, if so you have to name it differently | Same as `APP_FILE`
BUILD_NUMBER | A unique number for the build | Timestamp in YYMMDD-HHMMSS format
APP_FILE_VERSIONED | The unique file name | Concatenation of `APP_FILE` and `BUILD_NUMBER`
PUBLIC_WEB_DIR | Web content directory | `public_html`
STACK | Web server statck, run `./list-stacks.sh` to get a list of most current stacks | 64bit Amazon Linux 2017.09 v2.6.0 running PHP 7.1
INSTANCE_TYPE | EC2 instance type. Available instance types can be found here: https://aws.amazon.com/ec2/instance-types/ | t2.micro
SECURITY_GROUP | EC2 security group | **MUST CHANGE**
EC2_KEY_NAME | EC2 key pair | **MUST CHANGE**
S3_BUCKET | S3 bucket. It must exists in S3 | **MUST CHANGE**
S3_BUCKET_DIR | S3 directory for applications | `apps/${APP_NAME}/${APP_BRANCH}`
S3_BUCKET_FILE | S3 file name | `${S3_BUCKET_DIR}/${APP_FILE_VERSIONED}`
S3_DELETE | Whether or not to delete old appliation files | 1
S3_DELETE_DAYS_OLD | Delete old application `n` days old | 7
OPEN_IN_BROWSER_AFTER_UPDATE | Whether or not to open browser after update has been made, only works in Desktop environments. 1 = Yes, 0 = No | 1

### ./aws.sh deploy
This command deploys current branch to a Elastic Beanstalk environment.

If application doesn't exists, it creates the application. If environment doesn't exist, it creates the environment. If environment exists, it updates the environment.

### ./aws.sh terminate
This command terminates the environment of current branch.

### ./aws.sh terminate app
This command terminates the application and also terminates all of its environments.

### ./delete-s3.sh
*Example:* `./delete-s3.sh "s3://mys3bucket/apps/my-app/master" "7 days"`

### ./list-stacks.sh
This return a list of most current stacks available in AWS.

### 

## Tested Platforms

* Ubuntu 16 LTS
* macOS High Serria

## License
MIT - See included LICENSE.md
