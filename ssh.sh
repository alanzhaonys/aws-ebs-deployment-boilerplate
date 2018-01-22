container=$(docker ps -qf "name=awsebsdeploymentboilerplate_wordpress_1")
docker exec -it $container /bin/bash
