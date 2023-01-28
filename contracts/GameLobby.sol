pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/upgradeability/Initializable.sol";
//import "@openzeppelin/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";

contract GameLobby is Ownable {
    using Address for address;
    address payable public developer;
    address payable public dao;
    mapping(address => bool) public players;
    address[] public playerAddresses;
    address[] public approvedTokens;
    mapping(address => uint) public playerBalances;
    mapping(address => bytes32) public playerNames;
    uint public gameStartTime;
    uint public gameEndTime;
    uint public timeWindow;
    bytes32 public gameID;
    address public winner;
    bool public gameInProgress;
    bool public gameEnded;
    uint public minimumPlayers = 2;
    uint public maximumPlayers = 20;
    address payable public escrow; // variable to hold the escrow address
    // NFT related code
    ERC721 public victoryNFT;
    mapping(address => bool) public nftOwnership;
    mapping(address => bytes32) public nftMetadata;

    // events
    event NewGame(bytes32 gameID);
    event PlayerJoin(address player);
    event GameStart(bytes32 gameID);
    event GameEnd(bytes32 gameID, address winner);
    event Refund(address player, uint refund);
    event VictoryNFTIssued(address player, uint tokenId);

    constructor(address payable _developer, address payable _dao, uint _timeWindow) public {
        developer = _developer;
        dao = _dao;
        timeWindow = _timeWindow;
        approvedTokens.push(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // USDC
        approvedTokens.push(address(0x0000000000085d4780B73119b644AE5ecd22b376)); // DAI
        approvedTokens.push(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); // USDC
        approvedTokens.push(address(0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa)); // USDT
    }

    function deposit(address payable _player, bytes32 _playerName, uint _value) public payable {
        require(msg.sender == _player, "Only the player themselves can make a deposit.");
        require(players[_player] == false, "Player has already made a deposit.");
       // require(approvedTokens[address(this).balance] == true, "Token not approved for deposit.");
        require(_value > 0, "Deposit value must be greater than 0.");
        playerBalances[_player] = _value;
        players[_player] = true;
        playerNames[_player] = _playerName;
        playerAddresses.push(_player);
        emit PlayerJoin(_player);

        // send the deposit to the escrow address instead of storing it in the contract
        escrow.transfer(msg.value);
    }

    function startGame(bytes32 _gameID) public{
        //require(msg.sender == owner, "Only the owner can start the game.");
       // require(players.length >= minimumPlayers && players.length <= maximumPlayers, "Not enough players to start the game. Minimum 2 and maximum 20 players are required.");
        require(gameInProgress == false, "A game is already in progress.");
        require(gameEnded == false, "The previous game has not ended yet.");
        gameID = _gameID;
        gameStartTime = block.timestamp;
        gameEndTime = gameStartTime + timeWindow;
        gameInProgress = true;
        emit GameStart(_gameID);
    }


function refund() public payable {
    require(gameInProgress == false, "Cannot refund while game is in progress.");
    require(gameEnded == false, "Cannot refund while game has ended.");
    require(block.timestamp >= gameEndTime, "The game has not ended yet.");
    for (uint i = 0; i < playerAddresses.length; i++) {
        address player = playerAddresses[i];
        uint refund = playerBalances[player];
        payable(player).transfer(refund);
        emit Refund(player, refund);
    }
}

    function setWinner(bytes32 _gameID, address _winner) public {
        require(msg.sender == developer, "Only the developer can set the winner.");
        require(_gameID == gameID, "Invalid game ID.");
        require(gameEnded == true, "The game has not ended yet.");
        winner = _winner;
        emit GameEnd(_gameID, _winner);
    }

    function issueVictoryNFT(address _winner) public {
        require(msg.sender == developer, "Only the developer can issue victory NFTs.");
        require(gameEnded == true, "The game has not ended yet.");
        require(_winner == winner, "Invalid winner address.");
        require(nftOwnership[_winner] == false, "Player already owns a victory NFT.");
        uint tokenId = victoryNFT.mint(_winner);
        nftOwnership[_winner] = true;
        nftMetadata[_winner] = "Victory NFT for game ID: " + gameID;
        emit VictoryNFTIssued(_winner, tokenId);
        }
    }