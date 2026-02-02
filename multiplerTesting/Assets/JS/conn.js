const ws = new WebSocket("ws://10.138.37.74:7000");

const usernameInput = document.getElementById("username");
const input = document.getElementById("input");
const output = document.getElementById("output");
const errorMsg = document.getElementById("error");

const lobbyModal = document.getElementById('lobbyModal');
const hostButton = document.getElementById('host');
const joinButton = document.getElementById('join');
const modalClose = document.getElementById('modalClose');
const hostView = document.getElementById('hostView');
const joinView = document.getElementById('joinView');
const lobbyCodeEl = document.getElementById('lobbyCode');
const maxPlayersSelect = document.getElementById('maxPlayersSelect');
const playersList = document.getElementById('playersList');
const playersListJoin = document.getElementById('playersListJoin');
const startGameBtn = document.getElementById('startGame');
const leaveLobbyBtn = document.getElementById('leaveLobby');
const leaveLobbyBtn2 = document.getElementById('leaveLobby2');
const createLobbyBtn = document.getElementById('createLobby');
const joinCodeInput = document.getElementById('joinCodeInput');
const joinLobbyBtn = document.getElementById('joinLobbyBtn');
const joinStatus = document.getElementById('joinStatus');

let currentLobby = null;
let myPlayerId = null;
let isHost = false;

ws.onopen = () => {
    console.log('WebSocket connected');
};

ws.onerror = (error) => {
    console.error('WebSocket error:', error);
};

ws.onmessage = (event) => {
    try {
        const data = JSON.parse(event.data);
        
        if (!data.type || data.type === 'chat') {
            output.innerHTML += `<p><strong>${data.username}:</strong> ${data.message}</p>`;
        }
        
        if (data.type === 'lobby_join') {
            if (currentLobby && currentLobby.code === data.code) {
                console.log('WS: Player joined lobby');
                currentLobby.players.push(data.player);
                renderPlayers();
            }
        }
        if (data.type === 'lobby_leave') {
            if (currentLobby && currentLobby.code === data.code) {
                console.log('WS: Player left lobby');
                currentLobby.players = currentLobby.players.filter(p => p.id !== data.playerId);
                renderPlayers();
            }
        }
        if (data.type === 'lobby_start') {
            console.log('WS: Received lobby_start for code:', data.code, 'Current lobby code:', currentLobby?.code);
            if (currentLobby && currentLobby.code === data.code) {
                console.log('WS: Redirecting to game.html');
                window.location.href = './game.html?code='+currentLobby.code;
            }
        }
        if (data.type === 'lobby_close') {
            if (currentLobby && currentLobby.code === data.code) {
                console.log('WS: Host closed the lobby');
                alert('Host closed the lobby');
                currentLobby = null;
                closeModal();
            }
        }
    } catch (e) {
        console.warn('Error parsing ws message', e);
    }
};

input.addEventListener("keyup", (event) => {
    if (event.key === "Enter") {

        const username = usernameInput.value.trim();
        const message = input.value.trim();
        errorMsg.textContent = "";
        if (username === "") {
            errorMsg.textContent = "Please enter a username before sending messages.";
            return;
        }

        if (message === "") return;

        const payload = JSON.stringify({
            username: username,
            message: message
        });

        try {
            ws.send(payload);
        } catch (e) {
            console.warn('ws send failed', e);
        }

        output.innerHTML += `<p><strong>${username} (You):</strong> ${message}</p>`;

        input.value = "";
    }
});

function generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    let s = '';
    for (let i=0;i<6;i++) s += chars[Math.floor(Math.random()*chars.length)];
    return s;
}

function storageKey(code) { return 'lobby_' + code; }

function createLobby(maxPlayers) {
    const code = generateCode();
    myPlayerId = Date.now() + '_' + Math.floor(Math.random()*10000);
    const username = usernameInput.value.trim() || 'Host';
    const lobby = {
        code: code,
        hostId: myPlayerId,
        maxPlayers: Number(maxPlayers),
        players: [{ id: myPlayerId, username }],
        started: false,
        createdAt: Date.now()
    };
    localStorage.setItem(storageKey(code), JSON.stringify(lobby));
    currentLobby = lobby;
    isHost = true;
    openHostView();
    try { ws.send(JSON.stringify({ type:'lobby_create', code: code, hostId: myPlayerId, username, maxPlayers: lobby.maxPlayers })); } catch(e){}
}

function joinLobby(code) {
    console.log('Attempting to join lobby with code:', code);
    if (currentLobby) {
        console.log('Already in a lobby, cannot join another');
        return { ok:false, err:'You are already in a lobby' };
    }
    const key = storageKey(code);
    const raw = localStorage.getItem(key);
    if (!raw) {
        console.log('Lobby not found');
        return { ok:false, err:'Lobby not found' };
    }
    const lobby = JSON.parse(raw);
    if (lobby.started) {
        console.log('Game already started');
        return { ok:false, err:'Game already started' };
    }
    if (lobby.players.length >= lobby.maxPlayers) {
        console.log('Lobby is full');
        return { ok:false, err:'Lobby is full' };
    }
    myPlayerId = Date.now() + '_' + Math.floor(Math.random()*10000);
    const username = usernameInput.value.trim() || 'Player';
    lobby.players.push({ id: myPlayerId, username });
    localStorage.setItem(key, JSON.stringify(lobby));
    localStorage.setItem('currentUsername', username);
    try { ws.send(JSON.stringify({ type:'lobby_join', code: code, player: { id: myPlayerId, username } })); } catch(e){}
    currentLobby = lobby;
    isHost = false;
    console.log('Joined lobby successfully');
    openJoinView(code);
    return { ok:true };
}

function leaveLobby() {
    console.log('Leaving lobby');
    if (!currentLobby) return;
    const key = storageKey(currentLobby.code);
    const raw = localStorage.getItem(key);
    if (!raw) { closeModal(); disablePageInteraction(false); return; }
    const lobby = JSON.parse(raw);
    lobby.players = lobby.players.filter(p => p.id !== myPlayerId);
    if (isHost) {
        localStorage.removeItem(key);
        try { ws.send(JSON.stringify({ type:'lobby_close', code: currentLobby.code, hostId: myPlayerId })); } catch(e){}
    } else {
        localStorage.setItem(key, JSON.stringify(lobby));
        try { ws.send(JSON.stringify({ type:'lobby_leave', code: currentLobby.code, playerId: myPlayerId })); } catch(e){}
    }
    currentLobby = null;
    myPlayerId = null;
    isHost = false;
    closeModal();
    disablePageInteraction(false);
}

function startGame() {
    console.log('startGame called - currentLobby:', currentLobby, 'isHost:', isHost);
    if (!currentLobby || !isHost) {
        console.log('startGame blocked - not host or no lobby');
        return;
    }

    const key = storageKey(currentLobby.code);
    const raw = localStorage.getItem(key);
    if (!raw) {
        console.log('startGame blocked - lobby not in storage');
        return;
    }
    const lobby = JSON.parse(raw);
    lobby.started = true;
    localStorage.setItem(key, JSON.stringify(lobby));
    try { ws.send(JSON.stringify({ type:'lobby_start', code: currentLobby.code })); } catch(e){}

    console.log('Redirecting to game.html   ');
    // Store username for game.html to retrieve
    const username = usernameInput.value.trim() || 'Host';
    localStorage.setItem('currentUsername', username);
    setTimeout(() => { window.location.href = './game.html?code='+currentLobby.code; }, 100);
}

function openModal() { lobbyModal.classList.remove('hidden'); document.body.classList.add('modal-open'); }
function closeModal() { lobbyModal.classList.add('hidden'); document.body.classList.remove('modal-open'); }

function openHostView() {
    hostView.classList.remove('hidden');
    joinView.classList.add('hidden');
    lobbyCodeEl.textContent = currentLobby.code;
    maxPlayersSelect.value = currentLobby.maxPlayers;
    renderPlayers();
    openModal();
    disablePageInteraction(true);
}

function openJoinView(code) {
    hostView.classList.add('hidden');
    joinView.classList.remove('hidden');
    joinCodeInput.value = code || '';
    renderPlayers();
    openModal();
    disablePageInteraction(true);
}

function renderPlayers() {
    const list = currentLobby ? currentLobby.players : [];
    playersList.innerHTML = '';
    playersListJoin.innerHTML = '';
    list.forEach(p => {
        const li = document.createElement('li');
        li.textContent = p.username + (p.id === currentLobby.hostId ? ' (Host)' : '');
        playersList.appendChild(li.cloneNode(true));
        playersListJoin.appendChild(li.cloneNode(true));
    });
}

function refreshLobbyFromStorage(code) {
    const raw = localStorage.getItem(storageKey(code));
    if (!raw) { 
        console.log('Lobby storage cleared:', code);
        currentLobby = null; 
        closeModal(); 
        return; 
    }
    const lobby = JSON.parse(raw);
    currentLobby = lobby;
    renderPlayers();
    console.log('Refreshed lobby from storage:', code, 'Started:', lobby.started);
    if (lobby.started) {
        console.log('Lobby started - redirecting to game.html');
        window.location.href = './game.html?code='+currentLobby.code;
    }
}

window.addEventListener('storage', (ev) => {
    if (!ev.key) return;
    if (!ev.key.startsWith('lobby_')) return;
    const code = ev.key.replace('lobby_', '');
    if (currentLobby && currentLobby.code === code) {
        refreshLobbyFromStorage(code);
    }
});

setInterval(() => { if (currentLobby) refreshLobbyFromStorage(currentLobby.code); }, 800);

function disablePageInteraction(disable) {
    if (disable) {
        usernameInput.disabled = true;
        input.disabled = true;
        hostButton.disabled = true;
        joinButton.disabled = true;
    } else {
        usernameInput.disabled = false;
        input.disabled = false;
        hostButton.disabled = false;
        joinButton.disabled = false;
    }
}

hostButton.addEventListener('click', () => {
    console.log('Host button clicked');
    const username = usernameInput.value.trim();
    if (!username) { errorMsg.textContent = 'Please enter a username before hosting.'; return; }
    errorMsg.textContent = '';
    hostView.classList.remove('hidden');
    joinView.classList.add('hidden');
    createLobbyBtn.classList.remove('hidden');
    startGameBtn.classList.add('hidden');
    leaveLobbyBtn.classList.add('hidden');
    console.log('Create button visible:', !createLobbyBtn.classList.contains('hidden'));
    lobbyCodeEl.textContent = generateCode();
    openModal();
});

createLobbyBtn.addEventListener('click', () => {
    console.log('Create Lobby button clicked');
    const maxP = maxPlayersSelect ? maxPlayersSelect.value : 4;
    console.log('Creating lobby with max players:', maxP);
    createLobby(maxP);
    createLobbyBtn.classList.add('hidden');
    startGameBtn.classList.remove('hidden');
    leaveLobbyBtn.classList.remove('hidden');
});

joinButton.addEventListener('click', () => {
    console.log('Join button clicked');
    const username = usernameInput.value.trim();
    if (!username) { errorMsg.textContent = 'Please enter a username before joining.'; return; }
    errorMsg.textContent = '';
    hostView.classList.add('hidden');
    joinView.classList.remove('hidden');
    playersListJoin.innerHTML = '';
    joinStatus.textContent = '';
    openModal();
});

modalClose.addEventListener('click', () => {
    if (currentLobby) {
        alert('You are in a lobby. Leave the lobby to close this dialog.');
        return;
    }
    closeModal();
    disablePageInteraction(false);
});

leaveLobbyBtn.addEventListener('click', () => {
    console.log('Leave Lobby button clicked');
    leaveLobby();
});
leaveLobbyBtn2.addEventListener('click', () => {
    console.log('Leave Lobby 2 button clicked');
    leaveLobby();
});

joinLobbyBtn.addEventListener('click', () => {
    console.log('Join Lobby button clicked');
    const code = (joinCodeInput.value || '').toUpperCase().trim();
    console.log('Code entered:', code);
    if (!code) { joinStatus.textContent = 'Please enter a code.'; console.log('No code entered'); return; }
    console.log('Calling joinLobby with code:', code);
    const r = joinLobby(code);
    console.log('joinLobby returned:', r);
    if (!r.ok) { joinStatus.textContent = r.err; console.log('Join failed:', r.err); }
    else { joinStatus.textContent = ''; console.log('Join successful'); disablePageInteraction(true); }
});

startGameBtn.addEventListener('click', () => {
    console.log('Start Game button clicked');
    startGame();
});
