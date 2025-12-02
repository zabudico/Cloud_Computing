#!/bin/bash

# Enhanced load testing script for DevOps
# Usage: ./load_test.sh <ALB_DNS_NAME> <THREADS> <DURATION> [TOOL]

set -e

ALB_DNS_NAME=$1
THREADS=${2:-6}
DURATION=${3:-60}
TOOL=${4:-curl}

show_usage() {
    echo "Usage: $0 <ALB_DNS_NAME> [THREADS] [DURATION] [TOOL]"
    echo "Example: $0 project-alb-123456789.us-east-1.elb.amazonaws.com 10 120 ab"
    echo "Tools: curl, ab, hey"
    echo ""
    echo "Default: 6 threads, 60 seconds, curl"
    exit 1
}

# Validate inputs
if [ -z "$ALB_DNS_NAME" ]; then
    echo "❌ ERROR: ALB DNS name is required"
    show_usage
fi

if ! [[ "$THREADS" =~ ^[0-9]+$ ]] || [ "$THREADS" -lt 1 ]; then
    echo "❌ ERROR: THREADS must be a positive number"
    show_usage
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo "❌ ERROR: DURATION must be a positive number"
    show_usage
fi

echo "=========================================="
echo "🚀 LOAD TEST CONFIGURATION"
echo "=========================================="
echo "🔗 ALB DNS: $ALB_DNS_NAME"
echo "🧵 Threads: $THREADS"
echo "⏱️  Duration: ${DURATION}s"
echo "🛠️  Tool: $TOOL"
echo "🌐 URL: http://$ALB_DNS_NAME/load?seconds=$DURATION"
echo "🕐 Start Time: $(date)"
echo "=========================================="
echo ""

# Test ALB connectivity first
echo "🔍 Testing ALB connectivity..."
if curl -s -f "http://$ALB_DNS_NAME/" > /dev/null; then
    echo "✅ ALB is responding"
else
    echo "❌ ALB is not responding. Please check the DNS name and try again."
    exit 1
fi

# Function for curl-based load testing
run_curl_test() {
    local thread_num=$1
    local end_time=$((SECONDS + DURATION))
    local request_count=0
    local success_count=0
    
    echo "🧵 Thread $thread_num started (curl)"
    
    while [ $SECONDS -lt $end_time ]; do
        if curl -s -o /dev/null -w "Thread $thread_num: HTTP %{http_code}, Time: %{time_total}s\n" "http://$ALB_DNS_NAME/load?seconds=$DURATION" 2>/dev/null; then
            success_count=$((success_count + 1))
        fi
        request_count=$((request_count + 1))
        sleep 0.5
    done
    
    echo "✅ Thread $thread_num finished - $success_count/$request_count successful requests"
}

# Function for Apache Benchmark
run_ab_test() {
    echo "🔄 Starting Apache Benchmark test..."
    
    # Install ab if not available
    if ! command -v ab &> /dev/null; then
        echo "📦 Installing Apache Benchmark..."
        if command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y apache2-utils
        else
            echo "❌ Cannot install ab automatically. Please install manually."
            return 1
        fi
    fi
    
    echo "🧪 Running: ab -c $THREADS -t $DURATION -n 100000 http://$ALB_DNS_NAME/load?seconds=$DURATION"
    ab -c $THREADS -t $DURATION -n 100000 "http://$ALB_DNS_NAME/load?seconds=$DURATION" || true
}

# Function for Hey tool
run_hey_test() {
    echo "🔄 Starting Hey test..."
    
    # Install hey if not available
    if ! command -v hey &> /dev/null; then
        echo "📦 Downloading Hey..."
        if command -v wget &> /dev/null; then
            wget -q -O hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
        elif command -v curl &> /dev/null; then
            curl -L -o hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
        else
            echo "❌ Cannot download hey. Please install wget or curl."
            return 1
        fi
        chmod +x hey
        HEY_CMD="./hey"
    else
        HEY_CMD="hey"
    fi
    
    echo "🧪 Running: $HEY_CMD -c $THREADS -z ${DURATION}s http://$ALB_DNS_NAME/load?seconds=$DURATION"
    $HEY_CMD -c $THREADS -z ${DURATION}s "http://$ALB_DNS_NAME/load?seconds=$DURATION"
}

# Monitor Auto Scaling Group
monitor_asg() {
    local duration=$1
    local end_time=$((SECONDS + duration + 60))
    
    echo ""
    echo "📊 Starting Auto Scaling Group monitoring..."
    echo "   (Open AWS Console → EC2 → Auto Scaling Groups for detailed view)"
    echo ""
    
    while [ $SECONDS -lt $end_time ]; do
        echo "=== 📈 Monitoring Update - $(date) ==="
        
        # Get ASG information using AWS CLI if available
        if command -v aws &> /dev/null; then
            local asg_name="${var.project_name}-auto-scaling-group"
            local asg_info=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg_name" 2>/dev/null || echo "")
            
            if [ -n "$asg_info" ]; then
                local instance_count=$(echo "$asg_info" | jq -r '.AutoScalingGroups[0].Instances | length' 2>/dev/null || echo "N/A")
                local desired_capacity=$(echo "$asg_info" | jq -r '.AutoScalingGroups[0].DesiredCapacity' 2>/dev/null || echo "N/A")
                
                echo "   Instances: $instance_count (Desired: $desired_capacity)"
            else
                echo "   ASG information unavailable"
            fi
        else
            echo "   AWS CLI not available for detailed monitoring"
        fi
        
        sleep 30
    done
    echo "✅ Monitoring completed"
}

# Main test execution
case $TOOL in
    "ab")
        run_ab_test
        ;;
    "hey")
        run_hey_test
        ;;
    "curl"|*)
        # Start monitoring in background
        monitor_asg "$DURATION" &
        local monitor_pid=$!
        
        echo "🔄 Starting curl-based load test with $THREADS threads..."
        
        # Start load threads
        for i in $(seq 1 $THREADS); do
            run_curl_test $i &
        done
        
        # Wait for all threads to complete
        wait
        
        # Stop monitoring
        kill $monitor_pid 2>/dev/null || true
        ;;
esac

echo ""
echo "=========================================="
echo "✅ LOAD TEST COMPLETED"
echo "=========================================="
echo "🕐 End Time: $(date)"
echo "⏱️  Total Duration: ${DURATION}s"
echo "🧵 Threads: $THREADS"
echo "🛠️  Tool: $TOOL"
echo ""
echo "📊 Next steps:"
echo "   1. Check AWS Console → CloudWatch for metrics"
echo "   2. Check AWS Console → EC2 → Auto Scaling Groups"
echo "   3. Monitor instance count changes"
echo "=========================================="