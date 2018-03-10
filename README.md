<p align="center">
    <img src="https://user-images.githubusercontent.com/1342803/36623515-7293b4ec-18d3-11e8-85ab-4e2f8fb38fbd.png" width="320" alt="API Template">
    <br>
    <br>
    <a href="http://docs.vapor.codes/3.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="http://vapor.team">
        <img src="http://vapor.team/badge.svg" alt="Slack Team">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://circleci.com/gh/vapor/api-template">
        <img src="https://circleci.com/gh/vapor/api-template.svg?style=shield" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-4.1-brightgreen.svg" alt="Swift 4.1">
    </a>
</center>

This is an API server and web app written in Swift with the Vapor web framework

## Requirements
* Swift 4.1 - <a href="https://swift.org/download/">https://swift.org/download/</a>
* Vapor - <a href="https://vapor.codes/">https://vapor.codes/</a>
* Xcode 9.2 or greater
* Docker - <a href="https://www.docker.com/docker-mac">https://www.docker.com/docker-mac</a>

## Instructions
1. Install all requirements
1. Download or clone repository
1. Open terminal and cd to location
1. Setup a MySQL Database in a Docker container
    
    `docker run --name mysql -e MYSQL_USER=root -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=vapor -p 3306:3306 -d mysql/mysql-server`
    
 1. Check to see if database is running

    `docker exec -it mysql mysql -u root -ppassword`
    
 1. Build Xcode project via Terminal with Vapor command

    `vapor xcode -y`