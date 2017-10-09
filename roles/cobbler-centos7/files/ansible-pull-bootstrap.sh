#!/bin/bash
# Author: Luke Pafford
# Created: 20171003
# Purpose: Bootstraps a server so that it is ready to use ansible-pull
# on a periodic basis. Intended to be ran as a post script from a kickstart
# This script is fully idempotent, and can be reran at any point if someone
# screws up the configurations on the local box.

# The remote git server must have the account created, and the public key
# added to the authorized file. The account must belong to a group on the server
# that has read access to the repository. This script will NOT perform these steps
# on the remote server.

# You will want to verify that the ansible-pull cron job runs successfully. You may need to
# tweak the command in this script to fit your environment.

# The private key will be reused for each server, as it only serves one purpose,
# that is to connect to the GIT server and pull configurations

# Script was tested on Centos 7. Expected to work on any RedHat family distribution

function main {

	account='svc_git' # Local service account to be created
	git_server='vcs-git-01' # Remote server where ansible repository is stored
	ansible_pull_log='/var/log/ansible-pull.log'
	cron_frequency='*/15 * * * *' # Every 15 minutes by default
	cron_file='/etc/cron.d/ansible-pull' # Cron file to schedule ansible-pull jobs
	ansible_output_dir='/var/ansible-pull' # Directory to pull playbooks into
	ansible_hosts="${ansible_output_dir}/hosts" # Inventory hosts file. Generally in root directory of your ansible repository
	ansible_repo="ansible" # Git repository to pull configs from
	prereq_packages=(
		ansible
		git
	)
	remote_host_key=$(cat <<-EOF
	vcs-git-01 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCRqFcrpVPvpl3Sfp/r+eMTbTw/DTbcUprnRUcpt638dTcJbedbRNPOIAjzVzaq6FSO2du8AcLjwEmTSL5OtKFzCj+H0BATEE+yeN+QEKwwoPq051+NS7OhEFV/ioyCeyuyoMRXL4kflHcqh3dcx1T59T+Q05OaCicRfFrhTaMaLnLe6x0IXlm3qdTa8d6JeQndCCPud7kttnW9Cmro5RBtkBEu2/kvYNbnQ4KNmIwcuCI8YPxIvyQgY0KG3mCZp0NC6pKKbZJdy3zp1FEwnzxiUatw7q3tX2U0RixotWEmqIIyh8ucLEBH7+MD+UDwcSZsBJbZjQgSA8fVGGQY4un
EOF
	)
	private_key=$(cat <<-EOF
		-----BEGIN RSA PRIVATE KEY-----
		MIIEogIBAAKCAQEA2DDt5NYAttIoFOc+/PUniOZ9pHXtfyERalKngaHHscKRwckD
		/XUK7Ast7LLM9dVot8/+AoxeGmXMtrCZApzrMDZV52aGljIq9JdLtfrt+ixFeaBK
		7BuI5ruPoUCoIOjrfEye5SS0NF0SZ6wGP5b+aUWR4kctjsweydGxThQwuGc0oF9F
		GGaxvXGRhqP23DvyvFdW+6OEzEQXA68BXQAvS4f8I0j1fXj+NXGnDE/DdBpJb/TA
		w7P8683QTmwgTPsxfti5v1ZKggpN9J/Pw7rZkXP/xkqv8u5PsUKHCeQHv3g6vY/9
		HWLLJOwA/U146K8YmNWmxB/PUnvx+8SnQqrpYwIDAQABAoIBACHg2QbJOmdr23gb
		HNXLHRzo8bt593O6nN4KgdFgpsiGcwzpEUUAuGtw/QtgoZnMjZJwd5+ym3SLi179
		oZy1Nm3hteiDOogC6JRXuTeVUQGpOmHq6pLBZdyye7mLRk2R8oUSBLxn2g1yoFW6
		sWf5o3ifvFK3UL5V4mVCBQT1SQU8bUDtCVov4uGqD0UvW0mXmccQ26JVLcSgi0mN
		gx+448CPPF0z1d3VBBCp+Wx8EiuejmjjBjUAxNm5r0Z2bvCKvjJB6stOIM9jSH26
		ZRA6bk7Myp1A21j/Kb0u36qkBOFAVWLiYIZaTiGWkDgDFmuy8Q17B/jqjmg/Md6s
		kUlPiuECgYEA94Hlhe3kdyU9K2DOkaoG91gyr7BDsdqbA3cc9subTTRW9VK4w7Sp
		m1OpRTQN5Xm6gHToRnS07sJ1d1/WsesY8CQmSPv0pmQrB4WO+nJOUTfGcxI5ks9K
		zzrSoZfeWzb0Dpok7+K2P/n2f+oZMhO4KyZk319T1sTp0upfDzyTqKkCgYEA35vz
		YihvDu8G2+vwAWoruZE+wm9mAN1DLVI4r6dHlQe2UCOQqpa8GGh8s6TFUMyj1cHU
		nTSmK10UhWXkNx6wSIIg8MH2ZwIAYZQ8FjZdqawCXaPgpAwx0QSa8usGiI6Rd6/D
		TtGcbcGzNAlM8Y/iBR38YjEJAk3qzwF7h9MFDSsCgYB6/StGr/3VTsXkpkg/jdPE
		WSlmsBoTaOOahzf3Uxmq9ZU4dpClf0LAkoQMhV9aZnDMoEtDp365Hhws44zWAFL2
		EaCMp9bcT+4p4K45uU89gI+2YpoFX8h2zW4ZKlQt01LXZrVwFqIljFp3GabHgZEE
		sCFz9fS9RkBCtH/kHF/rcQKBgCQPmWOGE8r7v0ZuOUlxHtYRV2ax4mhXRoMjlGK3
		fnLJSJyJ78WjA3iIOTwbYXrTVcSeOrSTjgzGOQ3+TZyaBWHcIoXRMfSQvRD/f+Ux
		JU+8nrENQagTE2Ga9YYhYu9Y1prPrJakdS66IzVMHq2CP7gFivMm50YI3Mo/efWA
		kXr7AoGAfdpGqvevKv42zEEWko2mMd6ivzkAE513MI/hX+i6p5aGNk5uyvozMWtP
		RyYjyWpCvlCwWibsrbJK1DmIio9IVVmuvLIn+0jSjk7z0rhw65bY9aE6/1GNuGqT
		OOKSrotlLjnC3qQbCO/tOFO6gZsaJt8qT4029gdZIaiPQMVDrFw=
		-----END RSA PRIVATE KEY-----
EOF
	)
	public_key=$(cat <<-EOF
		ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYMO3k1gC20igU5z789SeI5n2kde1/IRFqUqeBocexwpHByQP9dQrsCy3sssz11Wi3z/4CjF4aZcy2sJkCnOswNlXnZoaWMir0l0u1+u36LEV5oErsG4jmu4+hQKgg6Ot8TJ7lJLQ0XRJnrAY/lv5pRZHiRy2OzB7J0bFOFDC4ZzSgX0UYZrG9cZGGo/bcO/K8V1b7o4TMRBcDrwFdAC9Lh/wjSPV9eP41cacMT8N0Gklv9MDDs/zrzdBObCBM+zF+2Lm/VkqCCk30n8/DutmRc//GSq/y7k+xQocJ5Ae/eDq9j/0dYssk7AD9TXjorxiY1abEH89Se/H7xKdCqulj Key used to authenticate to Git server to pull Ansible configurations
EOF
	)

# ------------------------------------------------------------------------------------------------------------------------------------------------
# 					DO NOT MODIFY ANY CODE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
# ------------------------------------------------------------------------------------------------------------------------------------------------
	Check_Root
	Prereq_Install "${prereq_packages[@]}"
	Create_Directory "/home/${account}/.ssh" "${ansible_output_dir}"
	Create_Service_Account "${account}" "${private_key}" "${public_key}" "${remote_host_key}"
	Create_Ansible_Pull_Cron "${account}" "${git_server}" "${cron_frequency}" "${cron_file}" "${ansible_output_dir}" "${ansible_hosts}" "${ansible_repo}" "${ansible_pull_log}"
	Test_Ssh_Connection "${account}" "${git_server}" "/home/${account}/.ssh/id_rsa"
}

function Check_Root {
	if [[ "$EUID" -ne 0 ]]; then
		echo "You must be root to run this script"
		exit 1
	fi
}

function Prereq_Install {
	local packages=("$@")

	echo "Installing prerequisite packages for ansible-pull"
	yum -y install "${packages[@]}" > /dev/null 2>&1
}

function Create_Service_Account {
	local account="${1}"
	local private_key="${2}"
	local public_key="${3}"
	local remote_host_key="${4}"

	echo "Check if service account ${account} does not exist"
	if ! cat /etc/passwd | awk -F ':' '{print $1}' | grep "${account}" > /dev/null 2>&1; then
		echo "Creating user ${account}"
		useradd "${account}" --create-home --system
	fi

	echo "Check if ${account} public key pair does not exist"
	if [[ ! -f "/home/${account}/.ssh/id_rsa" ]]; then
		echo "Creating ${account} public key pair"
		cat > "/home/${account}/.ssh/id_rsa" <<-EOF
		${private_key}
EOF

		cat > /home/${account}/.ssh/id_rsa.pub <<-EOF
		${public_key}
EOF
	fi

	echo "Check if remote known hosts has been configured"
	if [[ ! -f "/root/.ssh/known_hosts" ]]; then
		echo "Creating root known hosts"
		mkdir -p /root/.ssh/
		cat > "/root/.ssh/known_hosts" <<-EOF
		${remote_host_key}
EOF
	fi

	Set_File_Permissions "/home/${account}/.ssh" "${account}" "${account}" "700"
	Set_File_Permissions "/home/${account}/.ssh/id_rsa" "${account}" "${account}" "600"
	Set_File_Permissions "/home/${account}/.ssh/id_rsa.pub" "${account}" "${account}" "644"
}


function Create_Ansible_Pull_Cron {
	local account="${1}"
	local git_server="${2}"
	local cron_frequency="${3}"
	local cron_file="${4}"
	local ansible_output_dir="${5}"
	local ansible_hosts="${6}"
	local ansible_repo="${7}"
	local log_file="${8}"

	cron_job=$(cat <<-EOF
	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
	${cron_frequency} root ansible-pull -d ${ansible_output_dir} -i ${ansible_hosts} -U ssh://${account}@${git_server}/${ansible_repo} --private-key=/home/${account}/.ssh/id_rsa --clean --sleep=60 > ${log_file} 2>&1
EOF
	)

	echo "Check if ansible-pull cron job has been created"
	if [[ ! -f "${cron_file}" ]]; then
		echo "Creating ansible-pull cron job"
		cat > "${cron_file}" <<-EOF
		${cron_job}
EOF
	elif ! grep "${cron_frequency}" "${cron_file}" > /dev/null 2>&1; then
		echo "Updating ansible-pull cron job with new frequency"
		rm -f "${cron_file}"
		cat > "${cron_file}" <<-EOF
		${cron_job}
EOF
	fi
}

# Helper functions
function Set_File_Permissions {
	local filepath="${1}"
	local owner="${2}"
	local group="${3}"
	local mode="${4}"
	
	echo "Check if file ${filepath} has proper permissions set"
	# Check owner
	if [[ "$(stat -c %U ${filepath})" != "${owner}" ]]; then
		echo "Changing owner to ${owner} on ${filepath}"
		chown "${owner}" "${filepath}"
	fi
	# Check group
	if [[ "$(stat -c %G ${filepath})" != "${group}" ]]; then
		echo "Changing group to ${group} on ${filepath}"
		chgrp "${group}" "${filepath}"
	fi
	# Check mode
	if [[ "$(stat -c %a ${filepath})" != "${mode}" ]]; then
		echo "Changing mode to ${mode} on ${filepath}"
		chmod "${mode}" "${filepath}"
	fi
}

function Create_Directory {
	local dirs=("$@")

	for _dir in "${dirs[@]}"; do
		echo "Check if directory ${_dir} has been created"
		if [[ ! -d "${_dir}" ]]; then
			echo "Creating directory ${_dir}"
			mkdir -p "${_dir}"
		fi
	done
}

function Test_Ssh_Connection {
	local account="${1}"
	local server="${2}"
	local private_key="${3}"

	echo "Testing SSH public key connection to ${server} with account ${account}"
	ssh -o "batchmode yes" -o connectTimeout=5 -n -q "${account}@${server}" -i "${private_key}" exit

	if [[ "$?" -eq 0 ]]; then
		echo "SSH public key connection to ${server} with account ${account} succeeded"
	else
		echo "SSH public kyeconnection to ${server} with account ${account} failed"
	fi
}

main
