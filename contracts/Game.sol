pragma solidity ^0.8.8;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/payment/Escrow.sol";

contract pvpEscrow is ReentrancyGuard, Escrow {
    uint256 public damFee;
    uint256 public devFee;
    uint256 public daoFee;
    uint256 public totalgames = 0;
    uint256 public totalConfirmed = 0;
    address payable escrowAccount;

    mapping(uint256 => gameStruct) private games;
    mapping(address => gameStruct[]) private gamesOf;
    mapping(uint256 => address) public ownerOf;

    enum Status {
        OPEN,
        PENDING,
        DELIVERY,
        CONFIRMED,
        DISPUTTED
    }

    struct gameStruct {
        uint256 gameId;
        uint256 amount;
        uint256 timestamp;
        address owner;
        address provider;
        address winner; 
        Status status;
    }

    event Action (
        uint256 indexed gameId,
        bytes32 actionType,
        Status status,
        address indexed executor
    );

    constructor() public {
        damFee = 5;
        devFee = 3;
        daoFee = 2;
    }

    function createLobby(address payable _escrowAccount, uint256 amount) payable external returns (bool) {
        require(msg.value >= amount, "game amount is less than required");
        require(damFee <= 10 && damFee >= 1, "Invalid damFee value");
        require(devFee <= 10 && devFee >= 1, "Invalid devFee value");
        require(daoFee <= 10 && daoFee >= 1, "Invalid daoFee value");
        escrowAccount = _escrowAccount;

        uint256 gameId = totalgames++;
        gameStruct storage game = games[gameId];

        game.gameId = gameId;
        game.amount = amount;
        game.timestamp = block.timestamp;
        game.owner = msg.sender;
        game.status = Status.OPEN;

        gamesOf[msg.sender].push(game);
        ownerOf[gameId] = msg.sender;

        // Send the funds to the escrow
        require(Escrow.deposit.value(amount)(escrowAccount), "Deposit failed");

        emit Action (
            gameId,
            "game CREATED",
            Status.OPEN,
            msg.sender
        );
        return true;
    }

    function deposit(uint256 gameId, uint256 amount) payable external {
        require(games[gameId].status == Status.OPEN, "Game is not in OPEN status");
        require(msg.value == amount, "Deposit amount does not match specified amount");
        require(Escrow.deposit.value(amount)(address(this)), "Deposit failed");
    }



    function getMyGames() external view returns (gameStruct[] memory) {
    return gamesOf[msg.sender];
    }
    
    function getGameID(uint256 gameId) external view returns (gameStruct memory) {
    require(isAvailable[gameId] == Available.YES, "Game is not available");
    return games[gameId];
    }


    function setWinner(uint256 gameId, address winner) external {
        require(isAvailable[gameId] == Available.YES, "Game is not available");
        require(games[gameId].status != Status.CONFIRMED && games[gameId].status != Status.DISPUTTED, "Game already confirmed or disputed");
        require(msg.sender == ownerOf[gameId], "You are not the owner of the game");
        games[gameId].winner = winner;
        games[gameId].status = Status.CONFIRMED;
        totalConfirmed++;
        isAvailable[gameId] = Available.NO;

        emit Action (
            gameId,
            "Winner set",
            Status.CONFIRMED,
            msg.sender
        );
    }
}