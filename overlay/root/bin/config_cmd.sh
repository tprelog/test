

homeassistant_config_usage() {
    echo -e "\n Config Directory: ${homeassistant_config_dir}"
    echo -e " Backup Directory: ${homeassistant_backup_dir}\n"
    cat <<-_HELP_ # NOTE this Here Doc uses TABS to function correctly
	  
	  Usage: Do stuff with the configuration
	    
	  export TODO = Add more useful information to help
	    
	    -b  | --backup   Create zip backup of a configuration directory.
	    -cp | --copy     Copy configuration to another directory.
	    -r  | --restore  Restore zip backup to a configuration directory.
	    
	_HELP_
    return 0
  }
  
config_cmd="${name}_config ${*}"
homeassistant_config() {
  [ "${1}" == "config" ] && shift
  local _opt_ _dir_  _from_ _to_
  _opt_="${1}"
  _dir_="${2}"
  case ${_opt_} in
    -h | --help )
        homeassistant_config_usage
        ;;
    -cp | --copy )
        [ -n "${_dir_}" ] || err 1 "Please provide a /path/to/directory"
        ## One folder must be empty! Copy config to the empty folder.
        if [ ! -d "${_dir_}" ] || [ ! "$(ls -A "${_dir_}")" ]; then
          _from_="${homeassistant_config_dir}"
          _to_="${_dir_}"
        elif [ ! -d "${homeassistant_config_dir}" ] || [ ! "$(ls -A "${homeassistant_config_dir}")" ]; then
          _to_="${homeassistant_config_dir}"
          _from_="${_dir_}"
        else
          err 1 "expecting empty directory: ${_to_}"
        fi
        install -d -g "${homeassistant_group}" -m 775 -o ${homeassistant_user} -- "${_to_}" \
        && cp -a "${_from_}"/ "${_to_}"/
        ;;
      -b | --backup )
          local conf_dir="${dir:=$homeassistant_config_dir}"
          if [ ! -d ${conf_dir} ]; then
            err 1 "directory not found: ${conf_dir}"
          elif [ ! -d ${homeassistant_backup_dir} ]; then
            install -d -g "${homeassistant_group}" -m 775 -o ${homeassistant_user} -- "${homeassistant_backup_dir}" || return 1
          fi
          # shellcheck disable=SC2016
          su ${homeassistant_user} -c '
            _now=$(date +%y%m%d.%H%M%S)
            _ver=$(cat ${1}/.HA_VERSION 2>/dev/null)
            backup="HA_${_ver:="NA"}_${_now}.zip"
            echo -e "\n${orn}Creating Backup...\n${end}"
            echo    " Config Directory: ${1}"
            echo    " Backup Directory: ${2}"
            echo -e " Backup file: ${backup}\n"
            
            cd ${1}
            zip -9 -q -r "${2}/${backup}" . -x"*/components/*" -x"*/deps/*" -x"*/home-assistant.log" -x"*/.cache/*" -x"*/__pycache__*/" \
            && { echo -e "${orn}Testing Backup... ${end}"; unzip -t "${2}/${backup}" 2>&1>/dev/null; } \
            || { echo -e "${red}Backup Failed"${end}; rm -f -- "${2}/${backup}"; exit 1; }
            echo -e "${grn}Backup Created${end} ${2}/${backup}"
          ' _ ${conf_dir} ${homeassistant_backup_dir} || return $?
          ;;
      -r | --restore )
          local _create_="false" conf_dir="${dir:=$homeassistant_config_dir}"
          if [ ! -d ${homeassistant_backup_dir} ] || [ ! "$(ls -A ${homeassistant_backup_dir}/*.zip)" ]; then
            err 1 "no backups found: ${homeassistant_backup_dir}"
          elif [ -d ${conf_dir} ] && [ "$(ls -A ${conf_dir})" ]; then
            echo -e "${orn}\n Directory is not empty${end} ${conf_dir}"
            echo -e "${orn} This operation will REPLACE existing files${end}\n"
          elif [ ! -d ${conf_dir} ] || [ ! "$(ls -A ${conf_dir})" ];then
            install -d -g "${homeassistant_group}" -m 775 -o ${homeassistant_user} -- "${conf_dir}" \
            || err 1 "unable to create directory: ${conf_dir}"
            _create_="true"
            echo -e "${grn}\n Backup will be restored to ${conf_dir}${end}\n"
          fi
          # shellcheck disable=SC2016
          su ${homeassistant_user} -c '
            cancel() {
              exit 99
            }; trap cancel 2 3 6
            backups="$(ls -r "${1}" | grep .zip)"
            PS3=$(echo -e "\n C to Cancel\n Select: ")
            select zip in ${backups}
              do
                if [ "$REPLY" == c ] || [ "$REPLY" == C ]; then
                  cancel
                elif [ -z "${zip}" ]; then
                  echo -e "${red} $REPLY ${end}is not a valid number"
                  continue
                fi
                unzip -o -d "${2}" "${1}/${zip}" \
                && echo -e "${grn} Configuration restored${end}\n"
                exit 0
              done
          ' _ ${homeassistant_backup_dir} ${conf_dir}
          if [ $? == "99" ] && [ "${_create_}" == "true" ]; then
            [ ! "$(ls -A ${conf_dir})" ] \
            && { echo "Cleaning up..."; rmdir "${conf_dir}"; }
          fi
          ;;
      * )
      homeassistant_config_usage ;;
    esac
}