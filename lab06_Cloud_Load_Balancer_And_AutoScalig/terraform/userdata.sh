#!/bin/bash
# Update and install packages
yum update -y
yum install -y nginx stress jq

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Create HTML page
cat > /usr/share/nginx/html/index.html << 'EOF'
<html>
<head>
    <title>Project Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🚀 Hello from Project Web Server!</h1>
    <div class="info">
        <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
        <p><strong>Availability Zone:</strong> <span id="availability-zone">Loading...</span></p>
        <p><strong>IP Address:</strong> <span id="ip-address">Loading...</span></p>
    </div>
    <h2>Load Testing:</h2>
    <ul>
        <li><a href="/load?seconds=30">Light Load (30 seconds)</a></li>
        <li><a href="/load?seconds=60">Medium Load (60 seconds)</a></li>
        <li><a href="/load?seconds=120">Heavy Load (120 seconds)</a></li>
    </ul>
    
    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(r => r.text()).then(id => document.getElementById('instance-id').textContent = id);
        
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(r => r.text()).then(az => document.getElementById('availability-zone').textContent = az);
        
        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(r => r.text()).then(ip => document.getElementById('ip-address').textContent = ip);
    </script>
</body>
</html>
EOF

# Create load testing endpoint
cat > /usr/share/nginx/html/load << 'EOF'
#!/bin/bash
echo "Content-type: text/html"
echo ""

# Parse query parameters
QUERY_STRING="${QUERY_STRING:-}"
SECONDS=$(echo "$QUERY_STRING" | grep -oE 'seconds=[0-9]+' | cut -d= -f2)
SECONDS=${SECONDS:-60}

cat << HTML
<html>
<head>
    <title>Load Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .loading { color: #d35400; }
        .success { color: #27ae60; }
    </style>
</head>
<body>
    <h1>🧪 Load Test Started</h1>
    <div id="status">
        <p class="loading">⚡ Generating CPU load for $SECONDS seconds...</p>
        <p><strong>Instance:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        <p><strong>Duration:</strong> $SECONDS seconds</p>
    </div>
    <script>
        setTimeout(() => {
            document.getElementById('status').innerHTML = 
                '<p class="success">✅ Load test completed successfully!</p>' +
                '<p><a href="/">← Back to main page</a></p>';
        }, ${SECONDS} * 1000);
    </script>
</body>
</html>
HTML

# Generate CPU load in background
nohup bash -c "stress --cpu 1 --timeout ${SECONDS}s" > /dev/null 2>&1 &
EOF

chmod +x /usr/share/nginx/html/load

# Configure nginx to handle CGI scripts
echo "location /load { gzip off; root /usr/share/nginx/html; fastcgi_pass unix:/var/run/fcgiwrap.socket; include fastcgi_params; fastcgi_param SCRIPT_FILENAME /usr/share/nginx/html/load; }" >> /etc/nginx/default.d/cgi.conf

# Install and configure fcgiwrap for CGI support
yum install -y fcgiwrap
systemctl start fcgiwrap
systemctl enable fcgiwrap

# Restart nginx
systemctl restart nginx

# Health check file
echo "OK" > /usr/share/nginx/html/health