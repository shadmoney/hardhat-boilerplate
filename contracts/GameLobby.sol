// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Escrow.sol";

contract GameLobby {
    address payable public developer;
    address payable public dao;
    mapping(address => bool) public players;
    address[] public playerAddresses;
    address[] public approvedTokens;
    mapping(address => uint) public playerBalances;
    mapping(address => string) public playerNames;
    uint public gameStartTime;
    uint public gameEndTime;
    uint public timeWindow;
    uint256 public gameID;
    uint public escFee = 10;
    address payable public winner;
    uint public minimumPlayers = 2;
    uint public maximumPlayers = 20;
    uint public playerCount;
    // NFT related code
    // ERC721 public victoryNFT;
    mapping(address => bool) public nftOwnership;
    mapping(address => bytes32) public nftMetadata;

    mapping(uint256 => Escrow) escrowAddresses; // mapping to store the escrow address for each game
    mapping(bytes32 => uint) public escrowBalances; // mapping to store the balance in the escrow for each game
    uint public currentGameID;

    // events
    event NewGame(uint256 gameID);
    event PlayerJoin(address player, string playerName);
    event GameStart(uint256 gameID);
    event GameEnd(uint256 gameID, address winner);
    event Refund(address player, uint refund);
    event VictoryNFTIssued(address player, uint tokenId);
    event EscrowCreated(Escrow escrow);
    event EscrowDeposit(Escrow escrow, uint amount);

    enum GameStatus {
        PENDING,
        STARTED,
        FINISHED
    }

    mapping (uint256 => GameStatus) public gameStatus;

    constructor(address payable _developer, address payable _dao, uint _timeWindow) public {
        developer = _developer;
        dao = _dao;
        timeWindow = _timeWindow;
        approvedTokens.push(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // USDC
        approvedTokens.push(address(0x0000000000085d4780B73119b644AE5ecd22b376)); // DAI
        approvedTokens.push(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // USDC
        approvedTokens.push(address(0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa)); // USDT
    }
    function newGame(uint256 _gameID) public {
        require(currentGameID == _gameID, "A game with that ID already exists.");
        Escrow newEscrow = new Escrow(_gameID);
  
        escrowAddresses[uint256(_gameID)] = newEscrow;
        currentGameID = _gameID;
        emit NewGame(currentGameID);
        emit EscrowCreated(newEscrow);

}

    function deposit(address payable _player, string memory _playerName, uint256 _gameID, uint _value) public payable {
        address payable player = _player;
        uint256 value = _value;
        string memory playerName = _playerName;
        require(msg.sender == _player, "Only the player themselves can make a deposit.");
        require(players[player] == false, "Player has already made a deposit.");
        require(gameStatus[uint256(_gameID)] == GameStatus.PENDING, "Game has already started, deposit not allowed.");
        require(_value > 0, "Deposit value must be greater than 0.");
        playerBalances[player] = _value;
        players[player] = true;
        playerNames[_player] = _playerName;

        emit PlayerJoin(player, playerName);
        playerCount++;

        // send the deposit to the escrow address instead of storing it in the contract
        escrowAddresses[uint256(_gameID)].send(value);
        escrowBalances[bytes32(_gameID)] += value;
        emit EscrowDeposit(escrowAddresses[uint256(_gameID)], value);
    }

    function startGame(uint256 _gameID) public{
        //require(msg.sender == owner, "Only the owner can start the game.");
        require(playerCount >= minimumPlayers && playerCount <= maximumPlayers, "Not enough players to start the game. Minimum 2 and maximum 20 players are required.");
        gameID = _gameID;
        gameStartTime = block.timestamp;
        gameEndTime = gameStartTime + timeWindow;
        gameStatus[_gameID] = GameStatus.STARTED;
        emit GameStart(_gameID);
    }


    function refund(address payable _player) public {
        //require(players[_player] == true, "Player has not made a deposit.");
        require(escrowBalances[bytes32(currentGameID)] >= playerBalances[_player], "Not enough funds in escrow to refund player.");

        // send the refund to the player
        _player.transfer(playerBalances[_player]);
        escrowBalances[bytes32(currentGameID)] -= playerBalances[_player];
        //players[_player] = false;
        playerBalances[_player] = 0;
        playerNames[_player] = "";

        emit Refund(_player, playerBalances[_player]);
    }

    function payOutWinner(address payable _winner, uint256 _gameID) public {
        winner = _winner;
        gameStatus[_gameID] = GameStatus.FINISHED;
        emit GameEnd(_gameID, _winner);
        require(_gameID == gameID, "Invalid game ID.");
        require(winner != address(0), "There is no winner to pay out.");

        uint256 escrowBalance = escrowBalances[keccak256(abi.encodePacked(_gameID))];
        uint256 payOutAmount = escrowBalance * 9 / 10;
        uint256 devCut = escrowBalance * 5 / 100;
        uint256 daoCut = escrowBalance * 5 / 100;
        winner.transfer(payOutAmount);
        developer.transfer(devCut);
        dao.transfer(daoCut);
    }
    function getEscrowInformationByGameID(uint256 _gameID) public view returns (address, uint) {
        Escrow escrow = escrowAddresses[uint256(_gameID)];
        return (address(escrow), escrowBalances[bytes32(_gameID)]);
        }

}

