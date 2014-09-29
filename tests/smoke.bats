#!/usr/bin/env bats
[[ "$OSTYPE" = darwin* ]] && CPU_CORES=`sysctl hw.ncpu | awk '{print $2}'`
[[ "$OSTYPE" = linux* ]] && CPU_CORES=`nproc`
[ -z $MAX_WAIT ] && MAX_WAIT=5
[ -z $GOCD_AGENT_INSTANCES ] && GOCD_AGENT_INSTANCES=${CPU_CORES}
[ -z $GO_VERSION ] && GO_VERSION=14.2.0

assert_success()
{
   [ "$status" -eq 0 ]
}
assert_failure()
{
   [ "$status" -eq 1 ]
}

# This will leave GO_RUNNING and config.xml in the current directory.

@test "Port 8153 is open" {
   run curl --connect-timeout $MAX_WAIT --fail -qiSL --silent http://localhost:8153/ -o GO_RUNNING
   assert_success
}

@test "Go version ${GO_VERSION} found" {
   run grep "Go Version: ${GO_VERSION}" GO_RUNNING
   assert_success
}

@test "Prompted to create a new pipeline" {
   run grep "Add Pipeline - Go" GO_RUNNING
   assert_success
}

@test "Can retrieve the config" {
   run curl --connect-timeout $MAX_WAIT --fail -qiSL --silent http://localhost:8153/go/api/admin/config.xml -o config.xml
   assert_success
}

@test "${GOCD_AGENT_INSTANCES} agents exist" {
   run bash -c "grep 'agent hostname=' config.xml | wc -l | sed 's/ //g'"
   assert_success
   [ "$output" -eq "${GOCD_AGENT_INSTANCES}" ]
}
