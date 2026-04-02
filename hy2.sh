#!/bin/bash
# ==========================================
# 项目: Hysteria2-LuoPo 核心管理面板 V1.0 (纯净极客版)
# 描述: 专为恶劣网络环境打造的极简 Hysteria2 运维脚本
# ==========================================

# --- 1. 全局变量与颜色输出 ---
sh_ver="v1.1.0"

_red="\033[0;31m"
_green="\033[0;32m"
_yellow="\033[0;33m"
_blue="\033[0;36m"
_plain="\033[0m"

HY2_CONF_DIR="/etc/hysteria"
HY2_CONF_FILE="${HY2_CONF_DIR}/config.yaml"
HY2_META_FILE="${HY2_CONF_DIR}/meta.info"
HY2_SERVICE="hysteria-server.service"
HY2_BACKUP_DIR="${HY2_CONF_DIR}/backup"

msg() { echo -e "${_blue}[信息]${_plain} $1"; }
ok() { echo -e "${_green}[成功]${_plain} $1"; }
err() { echo -e "${_red}[错误]${_plain} $1"; }
print_line() { echo -e "${_blue}=====================================================${_plain}"; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        err "请使用 root 用户运行此脚本。"
        exit 1
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        err "缺少依赖命令: ${cmd}"
        return 1
    fi
    return 0
}

preflight_check() {
    local missing=0
    local cmd
    for cmd in curl systemctl openssl grep awk hostname journalctl; do
        if ! require_cmd "${cmd}"; then
            missing=1
        fi
    done
    if [[ "${missing}" -ne 0 ]]; then
        err "运行环境依赖不完整，请先安装缺失命令后重试。"
        exit 1
    fi
    if ! systemctl list-unit-files >/dev/null 2>&1; then
        err "当前系统未检测到可用的 systemd 环境，脚本无法继续运行。"
        exit 1
    fi
}

ensure_hy2_core_installed() {
    if ! command -v hysteria >/dev/null 2>&1; then
        err "未检测到 Hysteria2 内核，请先执行菜单 (1) 安装/更新内核。"
        return 1
    fi
    return 0
}

is_valid_port() {
    local p="$1"
    [[ "${p}" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 ))
}

is_valid_domain() {
    local d="$1"
    [[ "${d}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[A-Za-z]{2,63}$ ]]
}

is_valid_url() {
    local u="$1"
    [[ "${u}" =~ ^https?://[^[:space:]]+$ ]]
}

is_valid_email() {
    local e="$1"
    [[ "${e}" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

yaml_single_quote() {
    local raw="$1"
    local escaped="${raw//\'/\'\'}"
    printf "'%s'" "${escaped}"
}

url_encode() {
    local raw="$1"
    local length="${#raw}"
    local i char out=""
    for (( i = 0; i < length; i++ )); do
        char="${raw:i:1}"
        case "${char}" in
            [a-zA-Z0-9.~_-]) out+="${char}" ;;
            *) printf -v out '%s%%%02X' "${out}" "'${char}" ;;
        esac
    done
    printf '%s' "${out}"
}

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "${s}"
}

format_host_for_url() {
    local host="$1"
    if [[ "${host}" == *:* ]]; then
        printf '[%s]' "${host}"
        return
    fi
    printf '%s' "${host}"
}

backup_runtime_files() {
    mkdir -p "${HY2_BACKUP_DIR}" || return 1
    cp -f "${HY2_CONF_FILE}" "${HY2_BACKUP_DIR}/config.yaml.bak" 2>/dev/null || true
    cp -f "${HY2_META_FILE}" "${HY2_BACKUP_DIR}/meta.info.bak" 2>/dev/null || true
    return 0
}

restore_runtime_files() {
    local restored=0
    if [[ -f "${HY2_BACKUP_DIR}/config.yaml.bak" ]]; then
        cp -f "${HY2_BACKUP_DIR}/config.yaml.bak" "${HY2_CONF_FILE}" && restored=1
    fi
    if [[ -f "${HY2_BACKUP_DIR}/meta.info.bak" ]]; then
        cp -f "${HY2_BACKUP_DIR}/meta.info.bak" "${HY2_META_FILE}" || true
    fi
    if [[ "${restored}" -eq 1 ]]; then
        return 0
    fi
    return 1
}

fetch_server_ip() {
    local ip
    ip="$(curl -fsS4 --max-time 6 https://api.ipify.org 2>/dev/null || true)"
    if [[ -z "${ip}" ]]; then
        ip="$(curl -fsS6 --max-time 6 https://api64.ipify.org 2>/dev/null || true)"
    fi
    if [[ -z "${ip}" ]]; then
        ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
    fi
    echo "${ip}"
}

read_meta_info() {
    ip=""
    port=""
    password=""
    sni=""
    insecure=""

    while IFS='=' read -r key value; do
        case "${key}" in
            ip) ip="${value}" ;;
            port) port="${value}" ;;
            password) password="${value}" ;;
            sni) sni="${value}" ;;
            insecure) insecure="${value}" ;;
        esac
    done < "${HY2_META_FILE}"

    if [[ -z "${ip}" || -z "${port}" || -z "${password}" || -z "${sni}" || -z "${insecure}" ]]; then
        return 1
    fi
    if ! is_valid_port "${port}"; then
        return 1
    fi
    if [[ "${insecure}" != "true" && "${insecure}" != "false" ]]; then
        return 1
    fi
    return 0
}

service_control_menu() {
    while true; do
        clear
        print_line
        echo -e "               ${_green}--- 服务控制 ---${_plain}"
        print_line
        echo -e "    (1) 启动服务"
        echo -e "    (2) 停止服务"
        echo -e "    (3) 重启服务"
        echo -e "    (4) 查看状态"
        echo -e "    (0) 返回主菜单"
        print_line
        read -p " => 请选择操作 [0-4]: " action

        case "${action}" in
            1)
                if systemctl start "${HY2_SERVICE}"; then
                    ok "服务已启动。"
                else
                    err "启动失败，请检查日志。"
                fi
                sleep 1
                ;;
            2)
                if systemctl stop "${HY2_SERVICE}"; then
                    ok "服务已停止。"
                else
                    err "停止失败，请检查日志。"
                fi
                sleep 1
                ;;
            3)
                if systemctl restart "${HY2_SERVICE}"; then
                    ok "服务已重启。"
                else
                    err "重启失败，请检查日志。"
                fi
                sleep 1
                ;;
            4)
                if systemctl is-active --quiet "${HY2_SERVICE}"; then
                    ok "当前状态: 运行中"
                else
                    err "当前状态: 未运行"
                fi
                sleep 1
                ;;
            0) return 0 ;;
            *) err "输入错误"; sleep 1 ;;
        esac
    done
}

# --- 2. 核心控制模块: 安装与卸载 ---
install_hy2_core() {
    if command -v hysteria &> /dev/null; then
        msg "Hysteria2 内核已安装，正在尝试更新..."
    else
        msg "正在调用官方脚本安装 Hysteria2 内核..."
    fi
    
    if ! bash <(curl -fsSL https://get.hy2.sh/); then
        err "内核安装/更新失败，请检查网络后重试。"
        return 1
    fi

    if ! systemctl enable "${HY2_SERVICE}" >/dev/null 2>&1; then
        err "已安装内核，但设置开机自启失败，请手动执行: systemctl enable ${HY2_SERVICE}"
        return 1
    fi
    ok "Hysteria2 内核部署/更新完成！"
}

uninstall_hy2() {
    print_line
    echo -e "${_red}[警告] 这将彻底卸载 Hysteria2 及所有节点配置！${_plain}"
    read -p " => 确定要继续吗？(y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        systemctl stop "${HY2_SERVICE}" >/dev/null 2>&1 || true
        systemctl disable "${HY2_SERVICE}" >/dev/null 2>&1 || true
        
        rm -f /usr/local/bin/hysteria
        rm -rf /etc/hysteria
        rm -f /etc/systemd/system/hysteria-server.service
        systemctl daemon-reload
        ok "Hysteria2 已彻底卸载！"
        
        rm -f /usr/local/bin/hy2
        exit 0
    else
        msg "已取消卸载。"
    fi
}

# --- 3. 核心控制模块: 节点配置与生成 ---
config_hy2() {
    if ! ensure_hy2_core_installed; then
        sleep 2
        return 1
    fi

    clear
    print_line
    echo -e "               ${_green}--- Hysteria2 节点配置 ---${_plain}"
    print_line
    
    read -p " => 请设置监听端口 (默认 443): " port
    [[ -z "${port}" ]] && port=443
    if ! is_valid_port "${port}"; then
        err "端口无效，请输入 1-65535 的整数。"
        sleep 2
        return 1
    fi
    
    local default_pwd=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
    read -p " => 请设置认证密码 (默认随机: ${default_pwd}): " password
    [[ -z "${password}" ]] && password="${default_pwd}"

    read -p " => 请设置伪装网址 (默认 https://bing.com): " masquerade_url
    [[ -z "${masquerade_url}" ]] && masquerade_url="https://bing.com"
    if ! is_valid_url "${masquerade_url}"; then
        err "伪装网址格式无效，必须以 http:// 或 https:// 开头。"
        sleep 2
        return 1
    fi

    echo -e "\n[*] 请选择证书模式："
    echo -e "  (1) CA 域名证书 (推荐，需要提前将域名解析到本 VPS)"
    echo -e "  (2) 自签证书 (无需域名，直接使用 IP 连通)"
    read -p " => 请选择 [1-2]: " cert_type
    if [[ "${cert_type}" != "1" && "${cert_type}" != "2" ]]; then
        err "证书模式输入无效，请输入 1 或 2。"
        sleep 2
        return 1
    fi

    if ! mkdir -p "${HY2_CONF_DIR}"; then
        err "创建配置目录失败: ${HY2_CONF_DIR}"
        sleep 2
        return 1
    fi
    chmod 700 "${HY2_CONF_DIR}" >/dev/null 2>&1 || true
    if ! backup_runtime_files; then
        err "备份当前配置失败，已中止以避免覆盖现有配置。"
        sleep 2
        return 1
    fi

    if [[ "${cert_type}" == "1" ]]; then
        read -p " [*] 请输入已解析到本机的域名: " domain
        if ! is_valid_domain "${domain}"; then
            err "域名格式无效，请输入有效域名（例如 example.com）。"
            sleep 2
            return 1
        fi
        read -p " [*] 请输入邮箱 (用于自动申请证书，随意填): " email
        [[ -z "${email}" ]] && email="admin@${domain}"
        if ! is_valid_email "${email}"; then
            err "邮箱格式无效，请重新输入。"
            sleep 2
            return 1
        fi
        
        cat << EOF > ${HY2_CONF_FILE}
listen: :${port}
acme:
  domains:
    - $(yaml_single_quote "${domain}")
  email: $(yaml_single_quote "${email}")
auth:
  type: password
  password: $(yaml_single_quote "${password}")
masquerade:
  type: proxy
  proxy:
    url: $(yaml_single_quote "${masquerade_url}")
    rewriteHost: true
EOF
        chmod 600 "${HY2_CONF_FILE}" >/dev/null 2>&1 || true
        local sni="${domain}"
        local insecure="false"

    else
        msg "正在生成高强度自签名证书..."
        read -p " [*] 请输入用于伪装的 SNI 域名 (默认 bing.com): " sni
        [[ -z "${sni}" ]] && sni="bing.com"
        if ! is_valid_domain "${sni}"; then
            err "SNI 域名格式无效，请输入有效域名。"
            sleep 2
            return 1
        fi
        
        if ! openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout ${HY2_CONF_DIR}/server.key -out ${HY2_CONF_DIR}/server.crt \
        -subj "/CN=${sni}" -days 36500 >/dev/null 2>&1; then
            err "自签证书生成失败，请确认系统已安装 openssl。"
            sleep 2
            return 1
        fi
        
        if id hysteria >/dev/null 2>&1; then
            chown hysteria ${HY2_CONF_DIR}/server.key ${HY2_CONF_DIR}/server.crt || true
        fi
        chmod 600 "${HY2_CONF_DIR}/server.key" >/dev/null 2>&1 || true
        chmod 644 "${HY2_CONF_DIR}/server.crt" >/dev/null 2>&1 || true
        
        cat << EOF > ${HY2_CONF_FILE}
listen: :${port}
tls:
  cert: ${HY2_CONF_DIR}/server.crt
  key: ${HY2_CONF_DIR}/server.key
auth:
  type: password
  password: $(yaml_single_quote "${password}")
masquerade:
  type: proxy
  proxy:
    url: $(yaml_single_quote "${masquerade_url}")
    rewriteHost: true
EOF
        chmod 600 "${HY2_CONF_FILE}" >/dev/null 2>&1 || true
        local insecure="true"
    fi

    SERVER_IP="$(fetch_server_ip)"
    if [[ -z "${SERVER_IP}" ]]; then
        err "无法获取服务器 IP，请检查网络后重试。"
        sleep 2
        return 1
    fi

    cat > "${HY2_META_FILE}" << EOF
ip=${SERVER_IP}
port=${port}
password=${password}
sni=${sni}
insecure=${insecure}
EOF
    chmod 600 "${HY2_META_FILE}" >/dev/null 2>&1 || true

    msg "正在重启 Hysteria2 服务以应用新配置..."
    if ! systemctl restart "${HY2_SERVICE}"; then
        err "重启服务失败，正在尝试自动回滚到上一版配置..."
        if restore_runtime_files && systemctl restart "${HY2_SERVICE}"; then
            err "已回滚到上一版配置，本次变更未生效。"
        else
            err "自动回滚失败，请手动检查 ${HY2_CONF_FILE} 和服务日志。"
        fi
        sleep 2
        return 1
    fi
    sleep 2
    if systemctl is-active --quiet "${HY2_SERVICE}"; then
        ok "Hysteria2 节点配置并启动成功！"
    else
        err "启动失败！可能是端口被占用，或 CA 证书申请失败。请使用菜单 (5) 查看日志。"
    fi
    sleep 2
}

# --- 4. 客户端订阅与展示模块 ---
show_info() {
    if [[ ! -f ${HY2_META_FILE} ]]; then
        err "未找到节点元数据，请先执行 (2) 配置 Hysteria2 节点！"
        sleep 2
        return
    fi
    
    if ! read_meta_info; then
        err "节点元数据损坏或缺失，请重新执行 (2) 配置节点。"
        sleep 2
        return
    fi

    clear
    print_line
    echo -e "               ${_green}--- Hysteria2 客户端配置 ---${_plain}"
    print_line
    echo -e "  [*] 服务器 IP : ${_yellow}${ip}${_plain}"
    echo -e "  [*] 端口      : ${_yellow}${port}${_plain}"
    echo -e "  [*] 密码      : ${_yellow}${password}${_plain}"
    echo -e "  [*] SNI伪装   : ${_yellow}${sni}${_plain}"
    echo -e "  [*] 跳过证书  : ${_yellow}${insecure}${_plain} (自签必须为true)"
    print_line

    local enc_password enc_sni url_host json_ip json_password json_sni
    enc_password="$(url_encode "${password}")"
    enc_sni="$(url_encode "${sni}")"
    url_host="$(format_host_for_url "${ip}")"
    local hy2_url="hysteria2://${enc_password}@${url_host}:${port}/?sni=${enc_sni}&insecure=${insecure}#Hysteria2-LuoPo"

    json_ip="$(json_escape "${ip}")"
    json_password="$(json_escape "${password}")"
    json_sni="$(json_escape "${sni}")"
    echo -e "${_green}[Link] 一键导入链接 (推荐 V2rayN / NekoBox / Clash):${_plain}"
    echo -e "${hy2_url}"
    print_line
    
    echo -e "${_green}[JSON] Sing-box (Android/iOS) 专属 Outbound 模块:${_plain}"
    echo -e "{
  \"type\": \"hysteria2\",
  \"tag\": \"proxy\",
  \"server\": \"${json_ip}\",
  \"server_port\": ${port},
  \"up_mbps\": 50,
  \"down_mbps\": 200,
  \"password\": \"${json_password}\",
  \"tls\": {
    \"enabled\": true,
    \"server_name\": \"${json_sni}\",
    \"insecure\": ${insecure}
  }
}"
    print_line
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# --- 5. 主菜单系统 (高兼容极客版) ---
main_menu() {
    while true; do
        clear
        print_line
        echo -e "        ${_green}Hysteria2-LuoPo 管理面板 ${sh_ver}${_plain}"
        print_line
        
        local status="${_red}未运行${_plain}"
        local core_version="未安装"
        if command -v hysteria &> /dev/null; then
            # 精准抓取版本号，过滤 ASCII 图案
            core_version=$(hysteria version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
            [[ -z "$core_version" ]] && core_version="未知版本"
            
            if systemctl is-active --quiet "${HY2_SERVICE}"; then
                status="${_green}运行中${_plain}"
            fi
        fi
        
        echo -e "  [状态] Core: ${core_version} | 服务: [ ${status} ]"
        print_line
        echo -e "  [*] 节点与核心管理"
        echo -e "    (1) [+] 一键安装/更新 Hysteria2 内核"
        echo -e "    (2) [*] 配置 Hysteria2 节点 (CA / 自签)"
        echo -e "    (3) [>] 查看客户端配置与分享链接"
        echo -e ""
        echo -e "  [*] 服务控制"
        echo -e "    (4) [~] 启动 / 停止 / 重启 / 状态"
        echo -e "    (5) [i] 查看实时运行日志"
        echo -e "    (6) [-] 完全卸载清理"
        echo -e "    (0) [x] 退出面板"
        print_line
        
        read -p " => 请选择操作 [0-6]: " menu_num
        
        case "${menu_num}" in
            1) install_hy2_core; sleep 2 ;;
            2) config_hy2 ;;
            3) show_info ;;
            4)
                if ensure_hy2_core_installed; then
                    service_control_menu
                else
                    sleep 2
                fi
                ;;
            5)
                if ensure_hy2_core_installed; then
                    journalctl -u "${HY2_SERVICE}" --no-pager -n 100 -f
                else
                    sleep 2
                fi
                ;;
            6) uninstall_hy2 ;;
            0) exit 0 ;;
            *) err "输入错误"; sleep 1 ;;
        esac
    done
}

# 入口运行
require_root
preflight_check
main_menu
