#!/bin/bash

# Script chặn toàn bộ dịch vụ Speedtest tại Việt Nam và quốc tế trên VPS Linux
# Chạy với quyền root (sudo)

# Kiểm tra xem script có chạy với quyền root không
if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script này với quyền root (sudo)."
    exit 1
fi

# Kiểm tra và cài đặt iptables nếu chưa có
if ! command -v iptables &> /dev/null; then
    echo "iptables không được tìm thấy. Đang cài đặt iptables..."
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt-get update && apt-get install -y iptables
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL
        yum install -y iptables-services
    else
        echo "Không thể xác định hệ điều hành. Vui lòng cài đặt iptables thủ công."
        exit 1
    fi
fi

# Đảm bảo module string của iptables được bật (cần cho --string)
modprobe ip_tables
modprobe xt_string

# Danh sách tên miền Speedtest tại Việt Nam và quốc tế
SPEEDTEST_DOMAINS=(
    "speedtest.vn"
    "i-speed.vn" 
    "speedtest.net.vn" 
    "speedtest.net" 
    "*.speedtest.net"
    "ookla.com"
    "fast.com" 
    "testmy.net"
    "speedcheck.org" 
    "openspeedtest.com" 
    "speakeasy.net/speedtest"
    "dslreports.com"
    "bandwidthplace.com"
    "speakeasy.net" 
    "nperf.com" 
    "speed.is" 
    "dospeedtest.com"
    "speedof.me"
    "speedtesthn.fpt.vn"
    "speedtest.vpsttt.com"
    "vhn.vietpn.com"
    "speedtest.vnanet.vn"
    "ooklaodx.laotel.com"
    "speedtest.etllao.com"
    "ooklasvk.laotel.com"
    "udtsp1.myaisfibre.com"
    "speedtest-kkn1.ais-idc.net"
    "speedtest.kku.ac.th"
    "testnet.vn"
    "speedtest.com.vn"
    "speedtest.vnpt.vn"
)

# Danh sách IP mẫu của các dịch vụ Speedtest
SPEEDTEST_IPS=(
    "151.101.2.219" "151.101.66.219" "151.101.130.219"
    "23.63.240.0/24" "104.20.224.0/24" "203.119.10.0/24"
)

# Flush các rule iptables hiện tại (tùy chọn, bỏ comment nếu cần)
# iptables -F

# Chặn truy cập tới các IP Speedtest cụ thể
for ip in "${SPEEDTEST_IPS[@]}"; do
    echo "Chặn IP: $ip"
    iptables -A OUTPUT -d "$ip" -j DROP
done

# Chặn truy cập tới tên miền Speedtest qua DNS (port 53)
for domain in "${SPEEDTEST_DOMAINS[@]}"; do
    iptables -A OUTPUT -p udp --dport 53 -m string --string "$domain" --algo bm -j DROP
    iptables -A OUTPUT -p tcp --dport 53 -m string --string "$domain" --algo bm -j DROP
done

# Chặn truy cập trực tiếp tới các tên miền qua HTTP/HTTPS (port 80, 443)
for domain in "${SPEEDTEST_DOMAINS[@]}"; do
    iptables -A OUTPUT -p tcp --dport 80 -m string --string "$domain" --algo bm -j DROP
    iptables -A OUTPUT -p tcp --dport 443 -m string --string "$domain" --algo bm -j DROP
done

# Tạo thư mục và lưu các rule iptables
if [ ! -d /etc/iptables ]; then
    mkdir -p /etc/iptables
fi
iptables-save > /etc/iptables/rules.v4

# Cấu hình tự động áp dụng sau khi khởi động lại
if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    apt-get install -y iptables-persistent
    echo "iptables-restore < /etc/iptables/rules.v4" > /etc/network/if-pre-up.d/iptables
    chmod +x /etc/network/if-pre-up.d/iptables
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL
    systemctl enable iptables
    systemctl restart iptables
fi

# Thông báo hoàn tất
echo "Đã chặn toàn bộ dịch vụ Speedtest tại Việt Nam và quốc tế trên VPS."
echo "Các rule đã được lưu vào /etc/iptables/rules.v4"
echo "Kiểm tra rule: iptables -L -v"
echo "Xóa rule nếu cần: iptables -F (cẩn thận, sẽ xóa tất cả rule hiện tại)"

exit 0
