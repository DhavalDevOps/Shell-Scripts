#!/bin/bash

#############################
# BASIC DETAILS
#############################
DATE=$(date '+%d %b %Y %H:%M')
HOSTNAME=$(hostname)
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com || echo "N/A")
REPORT="/tmp/server_health_report_$(date +%F).html"
EMAILS="dhaval.chhayla.devops@gmail.com"

#############################
# HTML COMMAND FUNCTION
#############################
cmd_html () {
  echo "<pre>$(eval "$1" 2>&1)</pre>"
}

#############################
# HTML REPORT
#############################
cat <<EOF > $REPORT
<html>
<head>
<style>
body {
  font-family: Arial, sans-serif;
  background-color: #f3f4f6;
}
h1 {
  background: #020617;
  color: white;
  padding: 15px;
}
.section {
  background: white;
  margin: 20px;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 0 6px rgba(0,0,0,0.1);
}
table {
  width: 100%;
  border-collapse: collapse;
}
th {
  background: #e5e7eb;
  padding: 8px;
  text-align: left;
  width: 30%;
}
td {
  padding: 8px;
  border-bottom: 1px solid #ddd;
}
pre {
  background: #020617;
  color: #e5e7eb;
  padding: 12px;
  border-radius: 6px;
  overflow-x: auto;
}
.footer {
  text-align: center;
  font-size: 12px;
  color: #6b7280;
  margin: 30px;
}
</style>
</head>

<body>

<h1>📊 Server Health Monitoring Report</h1>

<div class="section">
<table>
<tr><th>Hostname</th><td>$HOSTNAME</td></tr>
<tr><th>Public IP</th><td>$PUBLIC_IP</td></tr>
<tr><th>Report Generated</th><td>$DATE</td></tr>
<tr><th>Uptime</th><td>$(uptime -p)</td></tr>
<tr><th>OS Version</th><td>$(lsb_release -d | cut -f2)</td></tr>
<tr><th>Kernel Version</th><td>$(uname -r)</td></tr>
</table>
</div>

<div class="section">
<h3>🧠 CPU & Load Average</h3>
$(cmd_html "top -bn1 | head -15")
</div>

<div class="section">
<h3>💾 Memory Usage</h3>
$(cmd_html "free -h")
</div>

<div class="section">
<h3>💽 Disk Usage</h3>
$(cmd_html "df -Th")
</div>

<div class="section">
<h3>📁 Disk Inode Usage</h3>
$(cmd_html "df -i")
</div>

<div class="section">
<h3>🔥 Top CPU Consuming Processes</h3>
$(cmd_html "ps aux --sort=-%cpu | head -11")
</div>

<div class="section">
<h3>🧠 Top Memory Consuming Processes</h3>
$(cmd_html "ps aux --sort=-%mem | head -11")
</div>

<div class="section">
<h3>🌐 Open & Listening Ports</h3>
$(cmd_html "ss -tulpn")
</div>

<div class="section">
<h3>📡 Network Connections Summary</h3>
$(cmd_html "ss -s")
</div>

<div class="section">
<h3>🚦 NGINX Service Status</h3>
$(cmd_html "systemctl status nginx --no-pager")
</div>

<div class="section">
<h3>❌ Failed System Services</h3>
$(cmd_html "systemctl --failed")
</div>

<div class="section">
<h3>🧾 Recent System Errors (Last 50)</h3>
$(cmd_html "journalctl -p 3 -xb --no-pager | tail -50")
</div>

<div class="section">
<h3>🔄 Pending System Updates</h3>
$(cmd_html "apt list --upgradable")
</div>

<div class="section">
<h3>🔐 Security Updates</h3>
$(cmd_html "unattended-upgrade --dry-run 2>/dev/null | tail -20 || echo 'Unattended-upgrades not configured'")
</div>

<div class="section">
<h3>♻️ Reboot Required Status</h3>
$(cmd_html "[ -f /var/run/reboot-required ] && cat /var/run/reboot-required || echo 'Reboot not required'")
</div>

<div class="footer">
Automated Server Monitoring Report
</div>

</body>
</html>
EOF

#############################
# SEND EMAIL
#############################
mail -a "Content-Type: text/html" \
     -a "FROM: Server-Monitoring Alerts" \
     -s "📊 Server Health Report - $HOSTNAME ($PUBLIC_IP)" \
     "$EMAILS" < "$REPORT"
