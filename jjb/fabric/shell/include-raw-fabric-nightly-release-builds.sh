#!/bin/bash
set -o pipefail

# Checkout to fabric repository
################################
cd gopath/src/github.com/hyperledger/fabric || exit
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "----------> FABRIC_COMMIT : $FABRIC_COMMIT"
echo "FABRIC_COMMIT ----------> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

# Pull thirdparty images
make docker-thirdparty

build_Fabric() {
# Build fabric images with 1.2.0-stable tag
     for IMAGES in docker release-clean $1; do
         make $IMAGES PROJECT_VERSION=1.2.0-stable
         if [ $? != 0 ]; then
            echo "----------> make $IMAGES failed"
            exit 1
         fi
     done
echo
echo "----------> List all fabric docker images"
docker images | grep hyperledger
}
ARCH=$(go env GOARCH)
if [ "$ARCH" = "s390x" ]; then
       echo "---------> ARCH:" $ARCH
       build_Fabric dist
else
       echo "---------> ARCH:" $ARCH
       build_Fabric dist-all
fi

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD && echo "--------> $GERRIT_BRANCH"
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "---------> FABRIC_CA_COMMIT : $CA_COMMIT"
echo "CA COMMIT ------> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

build_Fabric_Ca() {
       #### Build fabric-ca docker images
       for IMAGES in docker docker-fvt release-clean $1; do
           make $IMAGES PROJECT_VERSION=1.2.0-stable
           if [ $? != 0 ]; then
               echo "-------> make $IMAGES failed"
               exit 1
           fi
               echo
               echo "-------> List fabric-ca docker images"
       done
}
docker images | grep hyperledger/fabric-ca

# Execute release-all target on x arch
ARCH=$(go env GOARCH)
if [ "$ARCH" = "s390x" ]; then
       echo "---------> ARCH:" $ARCH
       build_Fabric_Ca release
else
       echo "---------> ARCH:" $ARCH
       build_Fabric_Ca dist-all
fi
