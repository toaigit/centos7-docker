# Install docker on Centos 7 behind proxy server
*   this script will install docker, docker-compose, vault, gomplate, awscli, shibboleth, ldapsearch, and python oracle driver
*   When building your docker image, you may need to add proxy environment in the Dockerfile
    *  ENV http_proxy http://proxy-server:8080
    *  ENV https_proxy https://proxy-server:8080
