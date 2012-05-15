require 'green/socket'

original_verbosity = $VERBOSE
$VERBOSE = nil    

Socket = Green::Socket
TCPSocket = Green::TCPSocket
TCPServer = Green::TCPServer


$VERBOSE = original_verbosity