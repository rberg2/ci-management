#!/bin/bash -e

# This script publishes the docker images to Nexus3 and binaries to Nexus2 if the end-to-end-merge tests are successful.
# Currently the images and binaries are published to Nexus only from the master branch.

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit 1
ORG_NAME=hyperledger/fabric
NEXUS_URL=nexus3.hyperledger.org:10003
TAG=$GIT_COMMIT &&  COMMIT_TAG=${TAG:0:7}
ARCH=$(go env GOARCH) && echo "--------->" $ARCH
PROJECT_VERSION=1.2.0-stable
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG

cd ../fabric-ca
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA COMMIT" $CA_COMMIT
cd -

fabric_DockerTag() {
    for IMAGES in peer orderer ccenv tools; do
         echo "----------> $IMAGES"
         echo
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$COMMIT_TAG
    done
         echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

fabric_Ca_DockerTag() {
    for IMAGES in ca ca-peer ca-orderer ca-tools ca-fvt; do
         echo "----------> $IMAGES"
         echo
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$CA_COMMIT
    done
         echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

dockerFabricPush() {
    for IMAGES in peer orderer ccenv tools; do
         echo "-----------> $IMAGES"
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$COMMIT_TAG
         echo
    done
         echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

dockerFabricCaPush() {
    for IMAGES in ca ca-peer ca-orderer ca-tools ca-fvt; do
         echo "-----------> $IMAGES"
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$CA_COMMIT
         echo
    done
         echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}
# Tag Fabric Docker Images
#fabric_DockerTag
# Tag Fabric Ca Docker Images
fabric_Ca_DockerTag
# Push Fabric Docker Images to Nexus3
#dockerFabricPush
# Push Fabric Ca Docker Images to Nexus3
dockerFabricCaPush
# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
# Publish fabric binaries
: '
if [ $ARCH = "amd64" ]; then
       # Push fabric-binaries to nexus2
       for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
              cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary && tar -czf hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz *
              echo "----------> Pushing hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz to maven.."
              mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
              -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz \
              -DrepositoryId=hyperledger-releases \
              -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
              -DgroupId=org.hyperledger.fabric \
              -Dversion=$binary.$PROJECT_VERSION-$COMMIT_TAG \
              -DartifactId=hyperledger-fabric-stable \
              -DgeneratePom=true \
              -DuniqueVersion=false \
              -Dpackaging=tar.gz \
              -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
              echo "-------> DONE <----------"
       done
else
       echo "-------> Dont publish binaries from s390x platform"
fi
'
# fabric-ca binaries

if [ $ARCH = "amd64" ]; then
       # Push fabric-binaries to nexus2
       for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
              cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary && tar -czf hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz *
              echo "----------> Pushing hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz to maven.."
              mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
              -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary/hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz \
              -DrepositoryId=hyperledger-releases \
              -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
              -DgroupId=org.hyperledger.fabric-ca \
              -Dversion=$binary.$PROJECT_VERSION-$CA_COMMIT \
              -DartifactId=hyperledger-fabric-ca-stable \
              -DgeneratePom=true \
              -DuniqueVersion=false \
              -Dpackaging=tar.gz \
              -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
              echo "-------> DONE <----------"
       done
else
       echo "-------> Dont publish binaries from s390x platform"
fi
