#!/bin/sh

# -----------------Main function------------------------

#Check env variables
function check_env() {

    if ! check_vars "GITLAB_KEY" "${GITLAB_KEY}" ""; then
        echo "Please set gitlab key first!!"
        exit -1
    fi

    if ! check_vars "TEMPLATE_VARS_INIT_DONE" "${TEMPLATE_VARS_INIT_DONE}" ""; then
        echo "Template variables not settled , start generate default"
        create_git_variable "TEMPLATE_VARS_INIT_DONE" "true"

        if ! check_vars "HARBOR_URL" "${HARBOR_URL}" ""; then create_git_variable "HARBOR_URL" "harbor.wistron.com"; fi
        if ! check_vars "HARBOR_PASSWORD" "${HARBOR_PASSWORD}" ""; then create_git_variable "HARBOR_PASSWORD" "R%z9vH#s3h"; fi
        if ! check_vars "HARBOR_PROJECT" "${HARBOR_PROJECT}" ""; then create_git_variable "HARBOR_PROJECT" "k8sprdwihi40"; fi
        if ! check_vars "HARBOR_USER" "${HARBOR_USER}" ""; then create_git_variable "HARBOR_USER" "k8si40"; fi
        if ! check_vars "SOURCEPJ" "${SOURCEPJ}" ""; then create_git_variable "SOURCEPJ" "true"; fi
        if ! check_vars "VER_M" "${VER_M}" ""; then create_git_variable "VER_M" "1.0."; fi
        if ! check_vars "VER_S" "${VER_S}" ""; then create_git_variable "VER_S" "0"; fi
        if ! check_vars "CURRENT_QAS_VERSION" "${CURRENT_QAS_VERSION}" ""; then create_git_variable "CURRENT_QAS_VERSION" "leavemeempty"; fi

        if ! check_vars "CFG_LATEST_DEV" "${CFG_LATEST_DEV}" ""; then create_git_variable "CFG_LATEST_DEV" "{}"; fi
        if ! check_vars "CFG_LATEST_QAS" "${CFG_LATEST_QAS}" ""; then create_git_variable "CFG_LATEST_QAS" "{}"; fi
        if ! check_vars "CFG_LATEST_PRD" "${CFG_LATEST_PRD}" ""; then create_git_variable "CFG_LATEST_PRD" "{}"; fi

        if ! check_vars "CFG_RECORD_DEV" "${CFG_RECORD_DEV}" ""; then create_git_variable "CFG_RECORD_DEV" "{}"; fi
        if ! check_vars "CFG_RECORD_QAS" "${CFG_RECORD_QAS}" ""; then create_git_variable "CFG_RECORD_QAS" "{}"; fi
        if ! check_vars "CFG_RECORD_PRD" "${CFG_RECORD_PRD}" ""; then create_git_variable "CFG_RECORD_PRD" "{}"; fi

        if ! check_vars "K8S_DEV_API" "${K8S_DEV_API}" ""; then create_git_variable "K8S_DEV_API" ""; fi
        if ! check_vars "K8S_DEV_KEY" "${K8S_DEV_KEY}" ""; then create_git_variable "K8S_DEV_KEY" ""; fi

        if ! check_vars "K8S_QAS_API" "${K8S_QAS_API}" ""; then create_git_variable "K8S_QAS_API" ""; fi
        if ! check_vars "K8S_QAS_KEY" "${K8S_QAS_KEY}" ""; then create_git_variable "K8S_QAS_KEY" ""; fi

        if ! check_vars "K8S_PRD_API" "${K8S_PRD_API}" ""; then create_git_variable "K8S_PRD_API" ""; fi
        if ! check_vars "K8S_PRD_KEY" "${K8S_PRD_KEY}" ""; then create_git_variable "K8S_PRD_KEY" ""; fi

        if ! check_vars "ENANLE_ISSUEBOARD_SYNC" "${ENANLE_ISSUEBOARD_SYNC}" ""; then create_git_variable "ENANLE_ISSUEBOARD_SYNC" "false"; fi

        init_issueborad

        echo "Generate default variables done."
    fi
}

function injectScriptsPackageJson() {
    curl $1 >setting.json
    setting=$(cat setting.json)
    package_json=$(cat package.json | jq -r '.scripts=$newVal' --argjson newVal "${setting}")
    echo $package_json >package.json
}

function check_required_file() {
    if [ ! -f ${1} ]; then
        echo "File ${1} not exist , download default template !!"
        curl ${2} >${1}
        echo "Default File for ${1} : "
        cat ${1}
    fi
}

function create_git_variable() {
    echo "update variable ${1} = ${2}"
    lable_create_param="{ \"key\": \"${1}\", \"value\": \"${2}\", \"protected\": false, \"masked\": false}"
    echo $lable_create_param
    curl -H "Content-Type:application/json" --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/variables" -d "${lable_create_param}"
}

# Get version of current commit
# master: VER_M + (VER_S + 1)
# pre-production/production: trace parent commits to get version
# fix-: trace parent commits to get master version then create hotfix version
function get_version() {

    echo "Begin: get_version()"

    echo "1: Get branch"

    # Get current branch type (master, production, pre-production, or fix-)
    get_branch "${CI_COMMIT_REF_NAME}" branch

    echo "End 1: Branch: ${branch}"

    # Skip process if it's conflict commit
    echo "2: Check if it's conflict commit"
    current_commit=$(get_commit_info "${CI_COMMIT_SHORT_SHA}")
    conflict_commit=$(get_conflict_commit "${current_commit}")
    if test "$conflict_commit" != ""; then

        # Save version to file for artifact usage
        echo "export SYS_VER="NA";" >build-vars.sh

        # exit process
        echo "Skip process for conflict commit, exit"
        exit 0
    fi
    echo "End 2: Check if it's conflict commit"

    echo "3: Get version by branch"

    # Default version as NA
    version="NA"

    if test "${branch}" == "master"; then

        echo "3.1: Check inputs"

        # Check if Gitlab CI/CD variables been set.
        echo "3.2: Check Gitlab CI/CD vars"
        if ! check_vars "GITLAB_KEY" "${GITLAB_KEY}" ""; then exit 0; fi
        if ! check_vars "VER_M" "${VER_M}" ""; then exit 0; fi
        if ! check_vars "VER_S" "${VER_S}" ""; then exit 0; fi

        echo "End 3.1: Check pass."

        # New version: VER_M + (VER_S + 1)
        next_ver_s=$((${VER_S} + 1))
        version="${VER_M}${next_ver_s}"
        echo "New master version : $version"

    elif test "${branch}" == "fix-"; then

        # Get tags information from Gitlab API
        all_tags=$(get_tags)

        # Get version form existed tag (Deal with branch initial)
        get_existed_ver "${all_tags}" "${CI_COMMIT_SHORT_SHA}" version
        echo "current commit version: $version"

        # If there's no version on cuurent commit, Get version from master (x.x.x)
        if test "${version}" == ""; then
            only_get_master="true"
            get_prior_ver "${all_tags}" "${CI_COMMIT_SHORT_SHA}" "$only_get_master" version
            echo "Parent master version: $version"
        fi

        # Get (count of version: x.x.x) to construct hotfix version
        hotfixver=$(jq -r 'map(select(.name | contains ($newVal))) | length' --arg newVal "$version" <<<"${all_tags}")

        # New hotfix version: x.x.x.x
        version="hotfix-"${version}.$((${hotfixver}))
        echo "New hotfix version: $version"

    else

        # Get tags information from Gitlab API
        all_tags=$(get_tags)

        # Get version form existed tag (Deal with branch initial)
        get_existed_ver "${all_tags}" "${CI_COMMIT_SHORT_SHA}" version
        echo "current commit version: $version"

        # If there's no version on cuurent commit, Get version from master
        if test "${version}" == ""; then
            only_get_master="false"
            get_prior_ver "${all_tags}" "${CI_COMMIT_SHORT_SHA}" "$only_get_master" version
            echo "Parent version: $version"
        fi
    fi

    echo "End 3: version: ${version}"

    echo "4: Save version to file"

    # Save version to file for artifact usage
    echo "export SYS_VER=${version};" >build-vars.sh

    if test "${branch}" == "master"; then
        # Save VER_S to file for artifact usage
        echo "export SYS_VER_S=${next_ver_s};" >>build-vars.sh
    fi

    echo "End 4"

    echo "End: get_version()"
}

# Get Build & test docker image, then push to Harbor
# master/fix- of Source project: Build image by version
# others: No need to build image
function docker_build() {

    # Get SYS_VER from artifact: build-vars.sh
    version="${SYS_VER}"
    echo "(Input) Version: ${version}"

    # Get SYS_VER_S from artifact: build-vars.sh
    version_s="${SYS_VER_S}"
    if test "${version_s}" != ""; then echo "(Input) Version_s: ${version_s}"; fi

    echo "Begin: docker_build()"

    echo "1: Check input"

    # Check if Gitlab CI/CD variables been set.
    echo "1.1: Check Gitlab CI/CD vars"
    if ! check_vars "GITLAB_KEY" "${GITLAB_KEY}" ""; then exit 0; fi
    if ! check_vars "VERSION_FILE" "${VERSION_FILE}" ""; then exit 0; fi
    if ! check_vars "version" "${version}" ""; then exit 0; fi

    # Skip process if it's conflict commit
    echo "1.2: Check if it's conflict commit"
    current_commit=$(get_commit_info "${CI_COMMIT_SHORT_SHA}")
    conflict_commit=$(get_conflict_commit "${current_commit}")
    if test "$conflict_commit" != ""; then

        # Save version to file for artifact usage
        echo "export SYS_VER="NA";" >build-vars-docker_build.sh

        # exit process
        echo "Skip process for conflict commit, exit"
        exit 0
    fi

    echo "End 1: Check pass."

    echo "2: Get branch"

    # Get current branch type (master, production, pre-production, or fix-)
    get_branch "${CI_COMMIT_REF_NAME}" branch

    echo "End 2: Branch: ${branch}"

    echo "3: Define docker tag"

    # Define docker tag by branch
    get_docker_tag ${branch} tag

    echo "End3: Docker tag: ${tag}"

    echo "4. Save version to file"

    # Save version to file for artifact usage
    echo "export SYS_VER=${version};" >build-vars-docker_build.sh

    # Save version to file as version info. in container
    echo "${version}" >${VERSION_FILE}

    echo "End 4"

    echo "5. Build and push image"

    if test "${branch}" == "pre-production"; then

        # No need to build image for QAS
        echo "Skip Docker biuld and push for QAS"
        echo "5.1: Retag QAS Docker image"
        retag

    elif test "${branch}" == "production"; then

        # No need to build image for QAS
        echo "Skip Docker biuld and push for PRD"
        echo "5.1: Retag PRD Docker image"
        retag

    else

        # Check if Harbor related Gitlab CI/CD variables been set.
        echo "5.1: Check Harbor related Gitlab CI/CD vars and version_s"
        if ! check_vars "HARBOR_PROJECT" "${HARBOR_PROJECT}" ""; then exit 0; fi
        if ! check_vars "HARBOR_URL" "${HARBOR_URL}" ""; then exit 0; fi
        if ! check_vars "HARBOR_USER" "${HARBOR_USER}" ""; then exit 0; fi
        if ! check_vars "HARBOR_PASSWORD" "${HARBOR_PASSWORD}" ""; then exit 0; fi

        # Build & test Docker image
        echo "5.2: Create Docker image"
        create_image ${tag}
        echo "5.2: Retag Docker image ${tag}"
        retag ${tag}

        # Push image to harbor
        echo "5.3: Push image to harbor"
        push_image ${tag}

        # Update version & tag to Gitlab CI/CD variables
        echo "5.4: Update Gitlab variables"
        update_git_version ${branch} ${version} ${version_s}
    fi

    echo "End 5"

    echo "End: docker_build()"
}

# Zap vulnerability scan
function zap_scan() {
    # Create './report' directory
    if [ -d "./report" ]; then
        echo "Delete ./report folder"
        rm -rf ./report
    fi
    echo "Create ./report folder"

    # Create '/zap/wrk' directory
    if [ -d "/zap/wrk" ]; then
        echo "Delete /zap/wrk folder"
        rm -rf /zap/wrk
    fi
    echo "Create /zap/wrk folder"
    mkdir /zap/wrk

    echo "zap-baseline.py -I -t "http://${SERVICE_NAME}"."${SCAN_URL}" -x zapreport.xml"
    zap-baseline.py -I -t http://${SERVICE_NAME}.${SCAN_URL} -x zapreport.xml
    ls -altr /zap/wrk
    cp -pr /zap/wrk/* ./report.xml
}

# Update Rancher settings
# Optional input $1: If custom K8S vars (true/false)
function cd_update() {

    # Get SYS_VER from artifact: build-vars-docker_build.sh
    version="${SYS_VER}"
    echo "(Input) Version: ${version}"

    # Get custom_k8s_vars flag from yml
    if test "${1}" == "true"; then
        custom_k8s_vars="true"
    else
        custom_k8s_vars="false"
    fi
    echo "(Input) custom_k8s_vars: ${custom_k8s_vars}"

    echo "Begin: cd_update()"

    echo "1: Check input"

    # Check if Gitlab CI/CD variables and version been set.
    echo "1.1: Check Gitlab CI/CD vars and version"
    if ! check_vars "GITLAB_KEY" "${GITLAB_KEY}" ""; then exit 0; fi
    if ! check_vars "BUILD_IMAGE_NAME" "${BUILD_IMAGE_NAME}" ""; then exit 0; fi
    if ! check_vars "HARBOR_URL" "${HARBOR_URL}" ""; then exit 0; fi
    if ! check_vars "HARBOR_PROJECT" "${HARBOR_PROJECT}" ""; then exit 0; fi
    if ! check_vars "version" "${version}" ""; then exit 0; fi

    # Skip process if it's conflict commit
    echo "1.2: Check if it's conflict commit"
    current_commit=$(get_commit_info "${CI_COMMIT_SHORT_SHA}")
    conflict_commit=$(get_conflict_commit "${current_commit}")
    if test "$conflict_commit" != ""; then
        echo "Skip process for conflict commit, exit"
        exit 0
    fi

    # Skip cd_update if version if NA
    echo "1.3: Check if it's NA version"
    if test "${version}" == "NA"; then
        echo "No New Version to update, exit"
        exit 0
    fi

    echo "End 1: Check pass."

    echo "2: Get branch"

    # Get current branch type (master, production, pre-production, or fix-)
    get_branch "${CI_COMMIT_REF_NAME}" branch

    echo "End 2: Branch: ${branch}"

    echo "3: Define K8S env. by branch"

    # If custom_k8s_vars is true, K8S related vars should be assigned before call cd_update()
    if test "${custom_k8s_vars}" != "true"; then

        # Set below K8S related vars: K8S_API, K8S_KEY, CFG_VERSION_RECORD, CONFIG_LATEST, LATEST_VAR, RECORD_VAR
        echo "Set K8S related vars by branch"
        set_k8s_vars ${branch}

    fi

    # Check if K8S related vars exists
    echo "Check K8S related vars"
    if ! check_vars "K8S_API" "${K8S_API}" ""; then exit 0; else echo "K8S_API: $K8S_API"; fi
    if ! check_vars "K8S_KEY" "${K8S_KEY}" ""; then exit 0; else echo "K8S_KEY: $K8S_KEY"; fi
    if ! check_vars "CFG_VERSION_RECORD" "${CFG_VERSION_RECORD}" ""; then exit 0; else echo "CFG_VERSION_RECORD: $CFG_VERSION_RECORD"; fi
    if ! check_vars "CONFIG_LATEST" "${CONFIG_LATEST}" ""; then exit 0; else echo "CONFIG_LATEST: $CONFIG_LATEST"; fi
    if ! check_vars "LATEST_VAR" "${LATEST_VAR}" ""; then exit 0; else echo "LATEST_VAR: $LATEST_VAR"; fi
    if ! check_vars "RECORD_VAR" "${RECORD_VAR}" ""; then exit 0; else echo "RECORD_VAR: $RECORD_VAR"; fi

    echo "End 3"

    echo "4: Get current K8s settings "

    pod_upgrade_body=$(curl -H "Authorization:${K8S_KEY}" -H "Content-Type:application/json" -X GET ${K8S_API})

    if test "${pod_upgrade_body}" == ""; then
        echo "Failed to get current K8S settings. Please check API and token."
        exit 0
    fi

    # Turn on if need to debug in detail
    # echo "pod_upgrade_body: ${pod_upgrade_body}"

    # Retrive K8S config, volume, and prior version
    echo "Get current K8S volumes settings"
    cfg=$(jq -r '.volumes' <<<$pod_upgrade_body)
    echo "cfg: $cfg"

    echo "Get current K8S volumeMounts settings"
    vol=$(jq -r '.containers[].volumeMounts' <<<$pod_upgrade_body)
    echo "vol: $vol"

    echo "Get prior version"
    prever=$(jq -r '.containers[0].image | split(":")[1]' <<<$pod_upgrade_body)
    echo "prever: $prever"

    # Turn on if need to debug in detail
    # echo "CFG_VERSION_RECORD: $CFG_VERSION_RECORD"

    echo "check if prior version exists in config record"
    is_version_exists=$(jq --arg key "${prever}" 'has($key)' <<<$CFG_VERSION_RECORD)
    echo "is_version_exists: $is_version_exists"

    echo "End 4"

    echo "5: Update config record/latest config to Gitlab"

    # Split piror version and judge if it's hotfix
    split_ver $prever pv1 pv2 pv3 pv4
    if test "${pv4}" == "0"; then
        hotfix_pre_ver="false"
    else
        hotfix_pre_ver="true"
    fi
    echo "prever: ${pv1}.${pv2}.${pv3}.${pv4}; hotifx:$hotfix_pre_ver"

    # Split current version and judge if it's hotfix
    split_ver $version v1 v2 v3 v4
    if test "${v4}" == "0"; then
        hotfix_current_ver="false"
    else
        hotfix_current_ver="true"
    fi
    echo "version: ${v1}.${v2}.${v3}.${v4}; hotifx:$hotfix_current_ver"

    if test "${hotfix_current_ver}" != "true"; then

        # Check prior version need to update to CONFIG_LATEST
        compare_version ${pv1} ${pv2} ${pv3} ${pv4} ${v1} ${v2} ${v3} ${v4} $is_version_exists is_update_latest_config
        echo "is_update_latest_config: $is_update_latest_config"

        if test "${is_update_latest_config}" == "true"; then

            # Update Latest config to Gitlab with current commit version
            echo "Update current version into latest config"
            update_latest_cfg $version "${cfg}" "${vol}"

        fi

    fi

    if test "${hotfix_pre_ver}" != "true"; then

        echo "Update prior version into config record"
        update_cfg_record $is_version_exists $prever "${cfg}" "${vol}"

    fi

    echo "6: Get latest config"
    if test "${hotfix_current_ver}" != "true"; then

        # 如不是hotfix，找LATEST，更新CONFIG
        ConfigCfg=$(jq '.cfg' <<<$CONFIG_LATEST)
        ConfigVol=$(jq '.vol' <<<$CONFIG_LATEST)

    else

        config_version="${v1}.${v2}.${v3}"
        echo "hotfix version: $version"
        echo "config version: $config_version"

        # 如是hotfix，只抓前三版本號，找RECORD的CONFIG
        ConfigCfg=$(jq --arg key "$config_version" '.[$key].cfg' <<<$CFG_VERSION_RECORD)
        ConfigVol=$(jq --arg key "$config_version" '.[$key].vol' <<<$CFG_VERSION_RECORD)

    fi

    echo "End 6"

    echo "-------------------------------------"
    echo $ConfigCfg
    echo "-------------------------------------"
    echo $ConfigVol
    echo "-------------------------------------"

    echo "7: Update to K8S"

    # prepare script
    pod_upgrade_body=$(jq '.annotations."cattle.io/timestamp"=$newVal' --arg newVal ${CI_JOB_TIMESTAMP} <<<"$pod_upgrade_body")
    pod_upgrade_body=$(jq '.containers[].image=$newVal' --arg newVal ${HARBOR_URL}/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${version} <<<"$pod_upgrade_body")

    # Turn on if need to debug in detail
    # echo "pod_upgrade_body: ${pod_upgrade_body}"

    # Update to K8S
    echo "${pod_upgrade_body}" >json.txt
    curl -H "Authorization:${K8S_KEY}" -H "Content-Type:application/json" -d "@json.txt" -X PUT ${K8S_API}

    echo "End 7"

    echo "End: cd_update()"

}

# ----------------- Sub function: Common ------------------------

# Check if variable been null
# Input $1: key of variable
# Input $2: value of variable
# Input $3: value to compare
function check_vars() {

    if test "${2}" == "${3}"; then
        echo "Check ${1} failed: value is ${3}"
        return 1
    else
        return 0
    fi
}

# Judge branch type of current commit
# Input $1: current commit branch name
# Ouput $2: branch type
function get_branch() {

    ref_name=${1}
    all_branchs=("master" "production" "pre-production" "fix-")

    # defualt ref_name as branch type
    eval "$2=$1"

    for current_branch in "${all_branchs[@]}"; do
        prefix="${ref_name/$current_branch*/$current_branch}"
        if test $prefix == $current_branch; then

            # Set branch type
            eval "$2=$prefix"
            break
        fi
    done

}

# Get current commit info
# Input $1: current commit id
function get_commit_info() {
    url=${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/commits/$1
    echo $(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" ${url%$'\r'})
}

# Get conflict commit.
# Input $1: current commit info
function get_conflict_commit() {

    # If there's merge conflict, a reverse pipeline will be triggerd (ex production -> pre-production) before normal pipeline
    # Current check logic: If message contains "# Conflicts:"
    # Need future study for better ways to judge if it's reverse pipeline.
    echo $(jq -r 'select(.message|contains("# Conflicts:")) | .id' <<<"${1}")
}

# ----------------- Sub function: get_version ------------------------

# Get tags information from Gitlab API
# Ouput $1: tags info. from Gitlab API
function get_tags() {

    # Notice:
    # Latest 100 records should be enough.
    # Refers to below link to implement pagination if your project need more records.
    # Reference: https://docs.gitlab.com/ee/api/#pagination
    echo $(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?page=1&per_page=100")
}

# Get version form existed tag (Deal with branch initial)
# Input $1: tags info. from Gitlab API
# Input $2: current commit id
# Output $3: matched version in tags info.
function get_existed_ver() {
    eval "$3="$(jq -r 'map(select(.target | contains ($newVal))) | .[] .name' --arg newVal "$2" <<<"$1")""
}

# Get prior version for non-hofix branch
# Input $1: tags info. from Gitlab API
# Input $2: current commit id
# Input $3: If get master only.
# Output $4: matched version in tags info.
function get_prior_ver() {

    echo "Find Parent of $2"

    # Get current commit info from Gitlab API
    current_commit=$(get_commit_info "$2")

    # Get parent commit ids
    parent_commits_ids=$(jq -r '.parent_ids' <<<"${current_commit}")
    echo "parent_commits_ids: $parent_commits_ids"

    # Get last commit id index = lenght - 1
    last_commit_id_index=$(jq '. | length-1' <<<"${parent_commits_ids}")
    last_commit_id_index=${last_commit_id_index%$'\r'}
    echo "last_commit_id_index: $last_commit_id_index"

    # Return if there's no parent commit.
    if test "$last_commit_id_index" == "-1"; then
        echo "No parent commit. VER: NA"
        eval "$4="NA""
        return 0
    fi

    # Get conflict commit.
    conflict_commit=$(get_conflict_commit "${current_commit}")

    if test "$conflict_commit" != ""; then

        # If it's reverse pipeline triggerd by conflict, search first parent_commits_id, which means trace target history
        echo "Reverse pipeline. Trace first parent id (Target history)."
        parent_index=0

    else
        # If it's normal pipeline, search last parent_commits_id, which means trace source history
        echo "Normal pipeline. Trace last parent id (Source history)."
        parent_index=${last_commit_id_index}

    fi

    # Get last parent commit
    parent_commits_id=$(jq -r '.[$newVal|tonumber]' --arg newVal ${parent_index} <<<"${parent_commits_ids}")
    parent_commits_id=${parent_commits_id%$'\r'}
    echo "parent_commits_id: $parent_commits_id"

    # Get prior version
    if test "$3" == "true"; then
        # Get only master version
        parent_ver=$(jq -r 'map(select(.target | contains ($newVal))) | map(select(.name | contains ("hotfix-") | not)) | .[].name' --arg newVal "${parent_commits_id}" <<<"$1")
    else
        # Get master or hotfix version
        parent_ver=$(jq -r 'map(select(.target | contains ($newVal))) | .[].name' --arg newVal "${parent_commits_id}" <<<"$1")
    fi
    parent_ver=${parent_ver%$'\r'}
    echo "parent_ver: $parent_ver"

    # If parent commit has version, return it. Otherwise, keep tracing it's parent
    if test "${parent_ver}" == ""; then
        get_prior_ver "$1" "$parent_commits_id" "$3" parent_ver
    fi

    #return version
    eval "$4="${parent_ver}""
}

# ----------------- Sub function: docker_build ------------------------

# Define docker tag by branch
# Input $1: current branch
# Output $2: docker tag
function get_docker_tag() {

    if test "$1" == "master"; then

        # Assign tag as version
        eval $2=${version}

    elif test "${branch}" == "pre-production"; then

        # pre-production use master image instead of create it's own
        echo "QAS no need to build image."
        eval $2="NA"

    elif test "${branch}" == "production"; then

        # pre-production use master image instead of create it's own
        echo "PRD no need to build image."
        eval $2="NA"

    elif test "${branch}" == "fix-"; then

        # Assign tag as hotfix version
        eval $2=${version}
    fi
}

# Build & test Docker image
# Input $1: Docker image tag
function create_image() {

    # Build image
    echo "Build image"
    docker build -t ${BUILD_IMAGE_NAME}:${1} --rm=true .

    # Test image when goss.yaml exists
    if [ -f "goss.yaml" ]; then

        echo "Testing image..."

        if test "${TEST_PORT}" != ""; then

            echo "Port Working？"
            GOSS_FILES_STRATEGY=cp dgoss run -p ${TEST_PORT} ${BUILD_IMAGE_NAME}:${1}
        else

            echo "Job Running？"
            GOSS_FILES_STRATEGY=cp dgoss run ${BUILD_IMAGE_NAME}:${1}
        fi

        echo "Testing image OK"

    else
        echo "goss.yaml not exists. Skip image test."
    fi
}

# Push image to harbor
# Input $1: Docker image tag
function push_image() {

    #tag image
    echo "tag image"
    docker tag ${BUILD_IMAGE_NAME}:${1} ${HARBOR_URL}/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${1}

    echo "$HARBOR_PASSWORD" | docker login -u "$HARBOR_USER" --password-stdin ${HARBOR_URL}

    #push image
    echo "push image"
    docker push ${HARBOR_URL}/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${1}

}

# Update version & tag to Gitlab CI/CD variables
# Input $1: Branch of current commit (master, production, pre-production, fix)
# Input $2: version
# Input $3: small version (VER_S in Gitlab)
function update_git_version() {

    if test "${1}" == "master"; then

        echo "master: update VER_S & tag"

        # Block if small version not set
        if ! check_vars "version_s" "${3}" ""; then exit 0; fi

        # Update VER_S to Gitlab
        curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/VER_S" --form "value=${3}"

        # Create tag by version to Gitlab
        curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name=${2}&ref=${CI_COMMIT_REF_NAME}"

    elif test "${1}" == "fix-"; then

        echo "fix-: update tag"

        # Create tag by version to Gitlab
        curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name=${2}&ref=${CI_COMMIT_REF_NAME}"

    else

        # No need to update due to there's no new version been created
        echo "${1}: No need to update"

    fi
}

# ----------------- Sub function: cd_update ------------------------

# Set K8S related vars by branch
# Global vars change: K8S_API, K8S_KEY, CFG_VERSION_RECORD, CONFIG_LATEST, LATEST_VAR, RECORD_VAR
function set_k8s_vars() {

    if test "${branch}" == "master"; then
        echo "update DEV Project"
        K8S_API=${K8S_DEV_API}
        K8S_KEY=${K8S_DEV_KEY}
        CFG_VERSION_RECORD=${CFG_RECORD_DEV}
        CONFIG_LATEST=${CFG_LATEST_DEV}
        LATEST_VAR="CFG_LATEST_DEV"
        RECORD_VAR="CFG_RECORD_DEV"

    elif test "${branch}" == "pre-production"; then
        echo "update QAS Project"
        K8S_API=${K8S_QAS_API}
        K8S_KEY=${K8S_QAS_KEY}
        CFG_VERSION_RECORD=${CFG_RECORD_QAS}
        CONFIG_LATEST=${CFG_LATEST_QAS}
        LATEST_VAR="CFG_LATEST_QAS"
        RECORD_VAR="CFG_RECORD_QAS"

    elif test "${branch}" == "fix-"; then
        echo "Hotfix!! update DEV Project"
        K8S_API=${K8S_DEV_API}
        K8S_KEY=${K8S_DEV_KEY}
        CFG_VERSION_RECORD=${CFG_RECORD_DEV}
        CONFIG_LATEST=${CFG_LATEST_DEV}
        LATEST_VAR="CFG_LATEST_DEV"
        RECORD_VAR="CFG_RECORD_DEV"

    elif test "${branch}" == "production"; then
        echo "update PRD Project"
        K8S_API=${K8S_PRD_API}
        K8S_KEY=${K8S_PRD_KEY}
        CFG_VERSION_RECORD=${CFG_RECORD_PRD}
        CONFIG_LATEST=${CFG_LATEST_PRD}
        LATEST_VAR="CFG_LATEST_PRD"
        RECORD_VAR="CFG_RECORD_PRD"

    else
        echo "No Need to update"
        exit 0
    fi
}

# Update Latest config to Gitlab
# Input $1: current commit version
# Inpit $2: current K8S volumes settings
# Inpit $3: current K8S volumesmounts settings
function update_latest_cfg() {

    # prepare json
    CONFIG_LATEST="{\"VER\":\"$version\",\"cfg\":$cfg,\"vol\":$vol}"
    echo "UPDATE LATEST: CONFIG_LATEST"

    # update to Gitlab
    curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/${LATEST_VAR}" --form "value=${CONFIG_LATEST}"
}

# Update Latest config to Gitlab
# Input $1: if prior version exists in config record
# Input $2: prior version
# Inpit $3: current K8S volumes settings
# Inpit $4: current K8S volumesmounts settings
function update_cfg_record() {
    # prepare json
    if test "$1" == "false"; then
        echo "Not exsit: Add new"
        CFG_VERSION_RECORD=$(jq --arg key "$2" --argjson value1 "${3}" --argjson value2 "${4}" '. * {($key):{vol:$value2,cfg:$value1}}' <<<$CFG_VERSION_RECORD)
    else
        echo "Exsit: Update"
        CFG_VERSION_RECORD=$(jq --arg key "$2" --argjson value "${3}" '.[$key].cfg=$value' <<<$CFG_VERSION_RECORD)
        CFG_VERSION_RECORD=$(jq --arg key "$2" --argjson value "${4}" '.[$key].vol=$value' <<<$CFG_VERSION_RECORD)

    fi
    echo "CFG_VERSION_RECORD: $CFG_VERSION_RECORD"

    # update to Gitlab
    curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/${RECORD_VAR}" --form "value=${CFG_VERSION_RECORD}"
}

# Check if prior version
# Input 1~4: piror version
# Input 5~8: current commit version
# Input 9: if prior version exists in config record
# Output 10: if prior version need to update to latest config
function compare_version() {

    # Defualt as need to update to latest config
    eval "${10}="false""

    if test "${CONFIG_LATEST}" != ""; then

        echo "LATEST CONFIG EXIST!"
        newer="true"

        # versions to compare
        banchmark_vers=($1 $2 $3 $4)
        input_vers=($5 $6 $7 $8)

        # loop every element
        for i in $(seq 0 3); do
            if test "${input_vers[i]}" -lt "${banchmark_vers[i]}"; then

                # Quit when version input less then banchmark (Older verion)
                echo "Check $i: ${input_vers[i]} < ${banchmark_vers[i]}"
                newer="false"
                break

            elif test "${input_vers[i]}" -gt "${banchmark_vers[i]}"; then

                # Quit when version input greater then banchmark (Newer verion)
                echo "Check $i: : ${input_vers[i]} > ${banchmark_vers[i]}"
                newer="true"
                break

            else

                # Continue loop to compare small ver when input equal to banchmark
                echo "Check $i: : ${input_vers[i]} = ${banchmark_vers[i]}"

            fi
        done

        echo "newer: $newer"

        if test "$newer" == "true" && test "$9" == "false"; then
            echo "A Newer version"
            eval "${10}="true""
        fi

    else
        echo "NO LATEST CONFIG"
        # 不存在，表示是最新的
        eval "${10}="true""
    fi
}

# Split version
# Input $1: version
# Output $2: 1st element of version
# Output $3: 2nd element of version
# Output $4: 3rd element of version
# Output $5: 4th element of version
function split_ver() {

    current_ver=$1
    dash="-"

    if [[ $current_ver == *$dash* ]]; then
        current_ver="${current_ver/*$dash/$dash}"
        current_ver=${current_ver:1}
    fi

    # split value
    v1=$(jq -r 'split(".")[0]' <<<"\"$current_ver\"") # "
    v2=$(jq -r 'split(".")[1]' <<<"\"$current_ver\"") # "
    v3=$(jq -r 'split(".")[2]' <<<"\"$current_ver\"") # "
    v4=$(jq -r 'split(".")[3]' <<<"\"$current_ver\"") # "
    if test "${v4}" == "null"; then v4=0; fi

    # return value
    eval "$2=$v1"
    eval "$3=$v2"
    eval "$4=$v3"
    eval "$5=$v4"
}

function record_git_qas_version() {
    if test "${CI_COMMIT_REF_NAME}" == "pre-production"; then
        version="${SYS_VER}"
        echo "pre-production: update CURRENT_QAS_VERSION"
        curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/CURRENT_QAS_VERSION" --form "value=${version}"
    fi
}

# Retag docker image
# Input $1: version (docker image tag)
function retag() {
    image_name="${BUILD_IMAGE_NAME}"
    if test "${CI_COMMIT_REF_NAME}" == "pre-production"; then
        version="${SYS_VER}"
        echo "${CI_COMMIT_REF_NAME}: retag qas ${image_name}:${version}"
        curl -L --request POST -u "${HARBOR_USER}:${HARBOR_PASSWORD}" --header "Content-Type: application/json" "${HARBOR_URL}/api/repositories/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}/tags" -d "{\"override\": true,\"src_image\": \"${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${version}\",\"tag\": \"${version}.qas\"}"
        record_git_qas_version
    elif test "${CI_COMMIT_REF_NAME}" == "production"; then
        if test "${scheduler}x" == "truex"; then
            qas_version="${SYS_VER}"
        else
            qas_version="${CURRENT_QAS_VERSION}"
        fi

        if test "$qas_version" != ""; then
            echo "${CI_COMMIT_REF_NAME}: retag prd ${image_name}:${qas_version}"
            curl -L --request POST -u "${HARBOR_USER}:${HARBOR_PASSWORD}" --header "Content-Type: application/json" "${HARBOR_URL}/api/repositories/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}/tags" -d "{\"override\": true,\"src_image\": \"${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${qas_version}.qas\",\"tag\": \"${qas_version}.prd\"}"
        else
            echo "Variable CURRENT_QAS_VERSION not found , skip retag"
        fi
    elif test "${CI_COMMIT_REF_NAME}" == "master"; then
        dev_version=$1
        echo "${CI_COMMIT_REF_NAME}: retag dev ${image_name}:${dev_version}"
        curl -L --request POST -u "${HARBOR_USER}:${HARBOR_PASSWORD}" --header "Content-Type: application/json" "${HARBOR_URL}/api/repositories/${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}/tags" -d "{\"override\": false,\"src_image\": \"${HARBOR_PROJECT}/${BUILD_IMAGE_NAME}:${DOCKER_TEST_IMAGE_TAG}\",\"tag\": \"${dev_version}\"}"
    fi
}

function sync_issue_board() {
    if test "${CI_COMMIT_REF_NAME}" == "master"; then

        commit_message=$(git log -1 --pretty=%B)

        IFS=',' read -ra AR <<<"$commit_message"
        IFS=';' read -ra issue_ids <<<"$AR"

        for i in "${issue_ids[@]}"; do
            issue_id=$(echo $i | xargs)

            issue_info=$(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}")
            state=$(echo $issue_info | jq -r ".state")

            if [ "${state}" == "opened" ]; then
                echo "update issue [${issue_id}] to fix"
                version_date=$(date +"%Y%m%d")
                echo "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=${LABEL_FIX}&description=${version_date},${SYS_VER}"
                curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=${LABEL_FIX}&description=${version_date},${SYS_VER}"
                echo "update issue [${issue_id}] done"
            fi

        done
    elif test "${CI_COMMIT_REF_NAME}" == "pre-production"; then
        project_fix_issues=$(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues?labels=${LABEL_FIX}")
        issues=$(echo $project_fix_issues | jq -r ".[] | @base64")
        for issue in $issues; do
            issue_data=$(echo $issue | base64 -d)
            issue_id=$(echo $issue_data | jq -r ".iid")
            echo "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=${LABEL_TESTING}"
            curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" -XPUT "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=${LABEL_TESTING}"
        done
    fi

}

function init_issueborad() {
    curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues?title=cicd_implement"

    ongoingLabelCreateInfo=$(curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/labels?name=${LABEL_ONGOING}&color=black")
    ongoingLabelId=$(echo $ongoingLabelCreateInfo | jq -r ".id")

    fixLabelCreateInfo=$(curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/labels?name=${LABEL_FIX}&color=black")
    fixLabelId=$(echo $fixLabelCreateInfo | jq -r ".id")

    testingLabelCreateInfo=$(curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/labels?name=${LABEL_TESTING}&color=black")
    testingLabelId=$(echo $fixLabelCreateInfo | jq -r ".id")

    issueBoardInfo=$(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/boards")
    defaultIssueBoardId=$(echo $issueBoardInfo | jq -r ".[0].id")

    curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/boards/${defaultIssueBoardId}/lists?label_id=${ongoingLabelId}"
    curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/boards/${defaultIssueBoardId}/lists?label_id=${fixLabelId}"
    curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/boards/${defaultIssueBoardId}/lists?label_id=${testingLabelId}"

    echo "Binding labels to board[${defaultIssueBoardId}]"
}

function create_wiki_page() {
    today=$(date +"%Y%m%d")
    echo "Create at : ${today} <br /> <br />" >temp.md

    project_fix_issues=$(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues?labels=${LABEL_TESTING}")
    issues=$(echo $project_fix_issues | jq -r ".[] | @base64")
    for issue in $issues; do
        issue_data=$(echo $issue | base64 -d)
        issue_id=$(echo $issue_data | jq -r ".iid")
        issue_title=$(echo $issue_data | jq -r ".title")
        description=$(echo $issue_data | jq -r ".description")

        echo "#${issue_id} ${description} ${issue_title} <br/>" >>temp.md
    done

    wiki_content=$(cat temp.md)
    wiki_page_title="${CURRENT_QAS_VERSION}"
    curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" -XPOST "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/wikis" -d "title=${wiki_page_title}&content=${wiki_content}"
}

function close_alltesting_issue() {
    project_fix_issues=$(curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues?labels=${LABEL_TESTING}")
    issues=$(echo $project_fix_issues | jq -r ".[] | @base64")
    for issue in $issues; do
        issue_data=$(echo $issue | base64 -d)
        issue_id=$(echo $issue_data | jq -r ".iid")
        echo "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=&state_event=close"
        curl --header "PRIVATE-TOKEN:${GITLAB_KEY}" -XPUT "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/issues/${issue_id}?labels=&state_event=close"
    done
}

function approval_status() {
    echo "${SYS_VER} 版本"
    echo "${ITSM_TICKET_NUMBER} 單號"
    echo "${2}  分支"
    echo "${1} 參數"

    if test "${1}" == "approve"; then
        # Create tag by version to Gitlab
        curl --request DELETE --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags/"W-${ITSM_TICKET_NUMBER}""
        echo "delte-w add A"
        curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name="A-${ITSM_TICKET_NUMBER}"&ref=${2}"
        if test "${SCHEDULE_FLAG}" == "Y"; then
            curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name="Scheduling"&ref=${2}"
            curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" --form value="${SYS_VER}" --url "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/SCHEDULE_VER"
        fi
    elif test "${1}" == "deny"; then
        # Create tag by version to Gitlab
        curl --request DELETE --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags/"W-${ITSM_TICKET_NUMBER}""
        echo "delete-w add D"
        curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name="D-${ITSM_TICKET_NUMBER}"&ref=${2}"
    else
        curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags?tag_name="W-${ITSM_TICKET_NUMBER}"&ref=${2}"
    fi

    #Retag Version
    curl --request DELETE --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags/"${SYS_VER}""
    curl --request POST --header "PRIVATE-TOKEN:${GITLAB_KEY}" "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/tags/"${SYS_VER}""
}

function tag_itsm_status() {
    echo "tag_itsm_status";
    if test "${isTicketFinish}" == "true"; then
        echo "isTicketFinish is approve"
        approval_status "approve" "${CI_COMMIT_REF_NAME}"
    elif test "${isTicketFinish}" == "false"; then
        echo "isTicketFinish is deny"
        approval_status "deny" "${CI_COMMIT_REF_NAME}"
    else
        echo "isTicketFinish is waitting"
        approval_status "waitting" "${CI_COMMIT_REF_NAME}"
    fi
}

function set_ticket_number() {
    # write back to gitlab
    if test "${1}x" == ""; then
        curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" --form value=$1 --url "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/ITSM_TICKET_NUMBER"
    else
        curl --request PUT --header "PRIVATE-TOKEN:${GITLAB_KEY}" --form value=${TicketNum} --url "${GITLAB_URL}/api/v4/projects/${CI_PROJECT_ID}/variables/ITSM_TICKET_NUMBER"
    fi
}
