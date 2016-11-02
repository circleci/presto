#!/bin/bash

ARRAY=(    
    'TEST_MODULES="!presto-tests,!presto-kafka,!presto-redis,!presto-cassandra,!presto-raptor,!presto-postgresql,!presto-mysql,!presto-accumulo"'
    'TEST_MODULES=presto-tests'
    'TEST_MODULES=presto-accumulo'
    'TEST_MODULES=presto-raptor,presto-redis,presto-cassandra,presto-kafka,presto-postgresql,presto-mysql'
    'PRODUCT_TESTS=true'
    'INTEGRATION_TESTS=true'
)

export ${ARRAY[$CIRCLE_NODE_INDEX]}

# We need the value of $TEST_MODULES, so we will leave the test in place.
test ! -v TEST_MODULES || 
    ./mvnw test $MAVEN_SKIP_CHECKS_AND_DOCS -B -pl $TEST_MODULES

test ! -v PRODUCT_TESTS || 
    presto-product-tests/bin/run_on_docker.sh multinode -x quarantine,big_query,storage_formats,profile_specific_tests

test ! -v PRODUCT_TESTS ||
    presto-product-tests/bin/run_on_docker.sh \
        singlenode-kerberos-hdfs-impersonation -g storage_formats,cli,hdfs_impersonation,authorization

test ! -v INTEGRATION_TESTS ||
    presto-hive-hadoop2/bin/run_on_docker.sh

test ! -v INTEGRATION_TESTS ||
    ./mvnw install -DskipTests -B

# Build presto-server-rpm for later artifact upload
test ! -v DEPLOY_S3_ACCESS_KEY || test ! -v PRODUCT_TESTS ||
    ./mvnw install -DskipTests $MAVEN_SKIP_CHECKS_AND_DOCS -B -q -T C1 -pl presto-server-rpm
