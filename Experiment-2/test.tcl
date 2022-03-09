set ns [new Simulator]

set trace [open test_res.tr w]
$ns trace-all $trace

proc finish {} {
	global ns trace
	$ns flush-trace
	close $trace
	exit 0
}

set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns duplex-link $n2 $n3 10Mb 10ms DropTail
$ns duplex-link $n3 $n4 10Mb 10ms DropTail
$ns duplex-link $n2 $n5 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail

$ns queue-limit $n2 $n3 10

set udp [new Agent/UDP]
$ns attach-agent $n2 $udp

set null [new Agent/Null]
$ns attach-agent $n3 $null

$udp set fid_ 1
$ns connect $udp $null

set cbr [new Application/Traffic/CBR]
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set random_ false
$cbr set rate_ 1mb
$cbr attach-agent $udp

set tcp1 [new Agent/TCP]
$ns attach-agent $n1 $tcp1
set tcp_sink1 [new Agent/TCPSink]
$ns attach-agent $n4 $tcp_sink1
$tcp1 set fid_ 2
$ns connect $tcp1 $tcp_sink1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP

set tcp2 [new Agent/TCP/Reno]
$ns attach-agent $n5 $tcp2
set tcp_sink2 [new Agent/TCPSink]
$ns attach-agent $n6 $tcp_sink2
$tcp2 set fid_ 3
$ns connect $tcp2 $tcp_sink2

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP

$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp1 start"
$ns at 3.0 "$ftp2 start"
$ns at 10.0 "$ftp1 stop"
$ns at 10.0 "$ftp2 stop"
$ns at 10.0 "$cbr stop"

$ns at 10.0 "finish"

$ns run












set ns [new Simulator]

# Retrieve simulation parameters from shell command line
# 1. The pair of TCP Variants
set tcp_variant1 [lindex $argv 0]
set tcp_variant2 [lindex $argv 1]

# 2. The CBR flow
set cbr_flow [lindex $argv 2]mb

# 3. The TCP variant pair start times
set tcp1_start_time [lindex $argv 3]
set tcp2_start_time [lindex $argv 4]

# Setup the output file name
set trace_file_name exp2_
# TCP/... TCP/...
append trace_file_name $tcp_variant1 _ $tcp_variant2
append trace_file_name _$cbr_flow
append trace_file_name _$tcp1_start_time
append trace_file_name _$tcp2_start_time.tr

# Console log message
puts "$trace_file_name || Running Sim for TCP 1: $tcp_variant1 | TCP 2: $tcp_variant2 | CBR: $cbr_flow | TCP 1 ST: $tcp1_start_time | TCP 2 ST: $tcp2_start_time"

# Open simulation trace file
set nf [open trace_data/$trace_file_name w]
$ns trace-all $nf

# 'finish' procedure definition
proc finish {} {
    global ns nf
    $ns flush-trace
    # Close the trace file
    close $nf
    exit 0
}

#
# Create a simple six node topology:
#
#        N1(TCP1, FTP1)  N4(TCP Sink1)
#         \              /
# 10Mb,12ms\  10Mb,12ms / 10Mb,12ms
#           N2(CBR) --- N3(UDP Sink)
# 10Mb,12ms/            \ 10Mb,12ms
#         /              \
#        N5(TCP2, FTP2)  N6(TCP Sink2)
#

# Setting up 6 nodes as part of the network blueprint
# TCP Source 1
set N1 [$ns node]
# TCP Source 2
set N5 [$ns node]
# CBR Source - Bottleneck Cap: 10Mbps
set N2 [$ns node]
# UDP Sink - Null
set N3 [$ns node]
# TCP Sink 1
set N4 [$ns node]
# TCP Sink 2
set N6 [$ns node]

# Create network links. Default queueing mechanism (Droptail)
$ns duplex-link $N1 $N2 10Mb 12ms DropTail
$ns duplex-link $N5 $N2 10Mb 12ms DropTail
$ns duplex-link $N2 $N3 10Mb 12ms DropTail
$ns duplex-link $N3 $N4 10Mb 12ms DropTail
$ns duplex-link $N3 $N6 10Mb 12ms DropTail

# Set queue limit between nodes N2 and N3
$ns queue-limit $N1 $N2 50
$ns queue-limit $N5 $N2 50
$ns queue-limit $N2 $N3 50
$ns queue-limit $N3 $N4 50
$ns queue-limit $N3 $N6 50

# UDP-CBR Connection
# Setup a UDP connection for CBR flow at N2
set udp [new Agent/UDP]
$ns attach-agent $N2 $udp

# Setup CBR over UDP at N2
set cbr_stream [new Application/Traffic/CBR]
$cbr_stream set rate_ $cbr_flow
$cbr_stream set type_ CBR
$cbr_stream set random_ false
$cbr_stream attach-agent $udp

# Setup Sink at N3
set cbr_sink [new Agent/Null]
$ns attach-agent $N3 $cbr_sink

# Connection: UDP - From N2 to N3
$ns connect $udp $cbr_sink
$udp set fid_ 1

# TCP-FTP Connection 1
# Setup the first TCP connection from N1 to N4
set tcp_var1 [new Agent/TCP/$tcp_variant1]
$tcp_var1 set window_ 100
$ns attach-agent $N1 $tcp_var1

# Setup FTP application at N1 for data stream
set ftp_stream_var1 [new Application/FTP]
$ftp_stream_var1 set type_ FTP
$ftp_stream_var1 attach-agent $tcp_var1

# Setup TCP Sink at N4
set tcp_sink_var1 [new Agent/TCPSink]
$ns attach-agent $N4 $tcp_sink_var1

# Connection: TCP 1 - From N1 to N4
$ns connect $tcp_var1 $tcp_sink_var1
$tcp_var1 set fid_ 2

# TCP-FTP Connection 2
# Setup the second TCP connection from N5 to N6
set tcp_var2 [new Agent/TCP/$tcp_variant2]
$tcp_var2 set window_ 100
$ns attach-agent $N5 $tcp_var2

# Setup FTP application at N5 for data stream
set ftp_stream_var2 [new Application/FTP]
$ftp_stream_var2 set type_ FTP
$ftp_stream_var2 attach-agent $tcp_var2

# Setup TCP Sink at N6
set tcp_sink_var2 [new Agent/TCPSink]
$ns attach-agent $N6 $tcp_sink_var2

# TCP 2 - From N5 to N6
$ns connect $tcp_var2 $tcp_sink_var2
$tcp_var2 set fid_ 3

# Event schedule for TCP and UDP connections
# Starting CBR at 0.0s
$ns at 0.1 "$cbr_stream start"
# Starting TCP variant pairs after CBR starts (stabalization check)
$ns at $tcp1_start_time "$ftp_stream_var1 start"
$ns at $tcp2_start_time "$ftp_stream_var2 start"

$ns at 12.1 "$cbr_stream stop"
$ns at 12.0 "$ftp_stream_var1 stop"
$ns at 12.0 "$ftp_stream_var2 stop"

# Run simulation
$ns at 12.5 "finish"
$ns run