const params = new URLSearchParams(window.location.search);
const lobbycode = params.get('code');

const ws = new WebSocket("ws://10.138.37.74:7000");

let partyMembers = [];

ws.onopen = () => {
    console.log('Game WebSocket connected');
    console.log('Lobby code:', lobbycode);
    
    // Get username from localStorage or use default
    const username = localStorage.getItem('currentUsername') || 'Player';
    
    // Send join party message
    const joinMsg = JSON.stringify({
        type: "joinParty",
        partyId: lobbycode,
        username: username
    });
    
    console.log('Sending join party message:', joinMsg);
    ws.send(joinMsg);
};

ws.onerror = (error) => {
    console.error('WebSocket error:', error);
};

ws.onmessage = (event) => {
    try {
        const data = JSON.parse(event.data);
        console.log('Received message from server:', data);
        
        if (data.type === "partyMemberJoined") {
            console.log(`Player "${data.username}" joined the party`);
            partyMembers = data.members;
            logConnectedMembers();
        }
        
        if (data.type === "partyMemberLeft") {
            console.log('A player left the party');
            partyMembers = data.members;
            logConnectedMembers();
        }
    } catch (e) {
        console.warn('Error parsing message:', e, 'Raw:', event.data);
    }
};

ws.onclose = () => {
    console.log('Game WebSocket disconnected');
};

function logConnectedMembers() {
    console.log(`=== Connected Party Members (${partyMembers.length}) ===`);
    partyMembers.forEach((member, index) => {
        console.log(`  ${index + 1}. ${member.username} (ID: ${member.resourceId})`);
    });
    console.log('========================================');
}