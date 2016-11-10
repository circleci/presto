#!/bin/bash

ARRAY=(
    'MAVEN_CHECKS=true'
    'TEST_SPECIFIC_MODULES=presto-tests'
    'TEST_SPECIFIC_MODULES=presto-raptor'
    'TEST_SPECIFIC_MODULES=presto-accumulo'
    'TEST_SPECIFIC_MODULES=presto-cassandra,presto-hive,presto-kafka,presto-mysql,presto-postgresql,presto-redis'
    'TEST_OTHER_MODULES=!presto-tests,!presto-raptor,!presto-accumulo,!presto-cassandra,!presto-hive,!presto-kafka,!presto-mysql,!presto-postgresql,!presto-redis,!presto-docs,!presto-server,!presto-server-rpm'
    'PRODUCT_TESTS=true'
    'HIVE_TESTS=true'
)

export ${ARRAY[$CIRCLE_NODE_INDEX]}

# Installation

./mvnw -v

if [[ -v TEST_SPECIFIC_MODULES ]]; then
  ./mvnw install $MAVEN_FAST_INSTALL -pl $TEST_SPECIFIC_MODULES -am
fi

if [[ -v TEST_OTHER_MODULES ]]; then
  ./mvnw install $MAVEN_FAST_INSTALL -pl '!presto-docs,!presto-server,!presto-server-rpm'
fi

if [[ -v PRODUCT_TESTS ]]; then
  ./mvnw install $MAVEN_FAST_INSTALL -pl '!presto-docs,!presto-server-rpm'
fi

if [[ -v HIVE_TESTS ]]; then
  ./mvnw install $MAVEN_FAST_INSTALL -pl presto-hive-hadoop2 -am
fi


# Scripts

if [[ -v MAVEN_CHECKS ]]; then
  ./mvnw install -DskipTests -B -T C1
fi

if [[ -v TEST_SPECIFIC_MODULES ]]; then
  ./mvnw test $MAVEN_SKIP_CHECKS_AND_DOCS -B -pl $TEST_SPECIFIC_MODULES
fi

if [[ -v TEST_OTHER_MODULES ]]; then
  ./mvnw test $MAVEN_SKIP_CHECKS_AND_DOCS -B -pl $TEST_OTHER_MODULES
fi

if [[ -v PRODUCT_TESTS ]]; then
  presto-product-tests/bin/run_on_docker.sh \
    multinode -x quarantine,big_query,storage_formats,profile_specific_tests
fi

if [[ -v PRODUCT_TESTS ]]; then
  presto-product-tests/bin/run_on_docker.sh \
    singlenode-kerberos-hdfs-impersonation -g storage_formats,cli,hdfs_impersonation,authorization
fi

if [[ -v HIVE_TESTS ]]; then
  presto-hive-hadoop2/bin/run_on_docker.sh
fi