<?php
require __DIR__ . '/vendor/autoload.php';

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

class ChatServer implements MessageComponentInterface {
    protected $clients;
    protected $parties; // Map of partyId => array of {conn, username}
    protected $clientToParty; // Map of resourceId => partyId

    public function __construct() {
        $this->clients = new \SplObjectStorage;
        $this->parties = array();
        $this->clientToParty = array();
        echo "Server started\n";
    }

    public function onOpen(ConnectionInterface $conn) {
        $this->clients->attach($conn);
        echo "New connection: {$conn->resourceId}\n";
    }

    public function onMessage(ConnectionInterface $from, $msg) {
        $data = json_decode($msg, true);
        
        // Handle party join
        if (isset($data['type']) && $data['type'] === 'joinParty') {
            $partyId = $data['partyId'];
            $username = $data['username'] ?? 'Unknown';
            
            if (!isset($this->parties[$partyId])) {
                $this->parties[$partyId] = array();
            }
            
            $this->parties[$partyId][] = array(
                'conn' => $from,
                'resourceId' => $from->resourceId,
                'username' => $username
            );
            
            $this->clientToParty[$from->resourceId] = $partyId;
            
            echo "Player '$username' joined party: $partyId\n";
            $this->logPartyMembers($partyId);
            
            // Notify all party members
            $response = json_encode([
                'type' => 'partyMemberJoined',
                'partyId' => $partyId,
                'username' => $username,
                'members' => $this->getPartyMembers($partyId)
            ]);
            $this->broadcastToParty($partyId, $response);
            return;
        }
        
        // Handle party leave
        if (isset($data['type']) && $data['type'] === 'leaveParty') {
            $partyId = $data['partyId'];
            if (isset($this->parties[$partyId])) {
                $this->parties[$partyId] = array_filter($this->parties[$partyId], function($member) use ($from) {
                    return $member['resourceId'] !== $from->resourceId;
                });
                if (empty($this->parties[$partyId])) {
                    unset($this->parties[$partyId]);
                    echo "Party $partyId is now empty and removed\n";
                } else {
                    echo "Player left party: $partyId\n";
                    $this->logPartyMembers($partyId);
                    $response = json_encode([
                        'type' => 'partyMemberLeft',
                        'partyId' => $partyId,
                        'members' => $this->getPartyMembers($partyId)
                    ]);
                    $this->broadcastToParty($partyId, $response);
                }
            }
            unset($this->clientToParty[$from->resourceId]);
            return;
        }
        
        // Handle chat messages - only send to clients NOT in parties (original chat room)
        if (!isset($this->clientToParty[$from->resourceId])) {
            foreach ($this->clients as $client) {
                if ($client !== $from && !isset($this->clientToParty[$client->resourceId])) {
                    $client->send($msg);
                }
            }
        } else {
            // If in a party, send to party members
            $partyId = $this->clientToParty[$from->resourceId];
            $this->broadcastToParty($partyId, $msg);
        }
    }

    public function onClose(ConnectionInterface $conn) {
        if (isset($this->clientToParty[$conn->resourceId])) {
            $partyId = $this->clientToParty[$conn->resourceId];
            if (isset($this->parties[$partyId])) {
                $this->parties[$partyId] = array_filter($this->parties[$partyId], function($member) use ($conn) {
                    return $member['resourceId'] !== $conn->resourceId;
                });
                if (empty($this->parties[$partyId])) {
                    unset($this->parties[$partyId]);
                    echo "Party $partyId removed (all members disconnected)\n";
                } else {
                    echo "Player disconnected from party: $partyId\n";
                    $this->logPartyMembers($partyId);
                }
            }
            unset($this->clientToParty[$conn->resourceId]);
        }
        
        $this->clients->detach($conn);
        echo "Connection closed: {$conn->resourceId}\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "Error: {$e->getMessage()}\n";
        $conn->close();
    }

    protected function broadcastToParty($partyId, $msg) {
        if (!isset($this->parties[$partyId])) return;
        foreach ($this->parties[$partyId] as $member) {
            try {
                $member['conn']->send($msg);
            } catch (\Exception $e) {
                echo "Failed to send to party member: {$e->getMessage()}\n";
            }
        }
    }

    protected function getPartyMembers($partyId) {
        if (!isset($this->parties[$partyId])) return array();
        return array_map(function($member) {
            return array(
                'username' => $member['username'],
                'resourceId' => $member['resourceId']
            );
        }, $this->parties[$partyId]);
    }

    protected function logPartyMembers($partyId) {
        if (!isset($this->parties[$partyId])) {
            echo "  Party $partyId has no members\n";
            return;
        }
        $members = $this->getPartyMembers($partyId);
        echo "  Party $partyId members (" . count($members) . "): ";
        echo implode(', ', array_map(function($m) { return $m['username']; }, $members));
        echo "\n";
    }
}

use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use Ratchet\Server\IoServer;

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new ChatServer()
        )
    ),
    7000
);

$server->run();

