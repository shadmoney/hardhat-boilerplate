// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    address public escAcc;
    uint256 public escBal;
    uint256 public escAvailBal;
    uint256 public escFee;
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;
    uint256 public gameID;

    mapping(uint256 => ItemStruct) private items;
    mapping(address => ItemStruct[]) private itemsOf;
    mapping(address => mapping(uint256 => bool)) public requested;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => Available) public isAvailable;

    enum Status {
        OPEN,
        PENDING,
        DELIVERY,
        CONFIRMED,
        DISPUTTED,
        REFUNDED,
        WITHDRAWED
    }

    enum Available { NO, YES }

    struct ItemStruct {
        uint256 itemId;
        string purpose;
        uint256 amount;
        uint256 timestamp;
        address owner;
        address provider;
        Status status;
        bool provided;
        bool confirmed;
    }

    event Action (
        uint256 itemId,
        string actionType,
        Status status,
        address indexed executor
    );

    constructor(uint256 _gameID) public payable {
        escAcc = msg.sender;
        escBal = 0;
        escAvailBal = 0;
        //escFee = _escFee;
        gameID = _gameID;
    }

      function send(uint256 value) public payable {
        escBal += value;
    }

    function createItem(
        string calldata purpose
    ) payable external returns (bool) {
        require(bytes(purpose).length > 0, "Purpose cannot be empty");
        require(msg.value > 0 ether, "Item cannot be zero ethers");

        uint256 itemId = totalItems++;
        ItemStruct storage item = items[itemId];

        item.itemId = itemId;
        item.purpose = purpose;
        item.amount = msg.value;
        item.timestamp = block.timestamp;
        item.owner = msg.sender;
        item.status = Status.OPEN;

        itemsOf[msg.sender].push(item);
        ownerOf[itemId] = msg.sender;
        isAvailable[itemId] = Available.YES;
        escBal += msg.value;

        emit Action (
            itemId,
            "ITEM CREATED",
            Status.OPEN,
            msg.sender
        );
        return true;
    }


    function getItems()
        external
        view
        returns (ItemStruct[] memory props) {
        props = new ItemStruct[](totalItems);

        for (uint256 i = 0; i < totalItems; i++) {
            props[i] = items[i];
        }
    }

    function getItem(uint256 itemId)
        external
        view
        returns (ItemStruct memory) {
        return items[itemId];
    }

    function myItems()
        external
        view
        returns (ItemStruct[] memory) {
        return itemsOf[msg.sender];
    }

    function requestItem(uint256 itemId) external returns (bool) {
        require(msg.sender != ownerOf[itemId], "Owner not allowed");
        require(isAvailable[itemId] == Available.YES, "Item not available");

        requested[msg.sender][itemId] = true;

        emit Action (
            itemId,
            "REQUESTED",
            Status.OPEN,
            msg.sender
        );

        return true;
    }

    function approveRequest(
        uint256 itemId,
        address provider
    ) external returns (bool) {
        require(msg.sender == ownerOf[itemId], "Only owner allowed");
        require(isAvailable[itemId] == Available.YES, "Item not available");
        require(requested[provider][itemId], "Provider not on the list");

        isAvailable[itemId] == Available.NO;
        items[itemId].status = Status.PENDING;
        items[itemId].provider = provider;

        emit Action (
            itemId,
            "APPROVED",
            Status.PENDING,
            msg.sender
        );

        return true;
    }

    function performDelievery(uint256 itemId) external returns (bool) {
        require(msg.sender == items[itemId].provider, "Service not awarded to you");
        require(!items[itemId].provided, "Service already provided");
        require(!items[itemId].confirmed, "Service already confirmed");

        items[itemId].provided = true;
        items[itemId].status = Status.DELIVERY;

        emit Action (
            itemId,
            "DELIVERY INTIATED",
            Status.DELIVERY,
            msg.sender
        );

        return true;
    }

    function confirmDelivery(
        uint256 itemId,
        bool provided
    ) external returns (bool) {
        require(msg.sender == ownerOf[itemId], "Only owner allowed");
        require(items[itemId].provided, "Service not provided");
        require(items[itemId].status != Status.REFUNDED, "Already refunded, create a new Item");

        if(provided) {
            uint256 fee = (items[itemId].amount * escFee) / 100;
            payTo(items[itemId].provider, (items[itemId].amount - fee));
            escBal -= items[itemId].amount;
            escAvailBal += fee;

            items[itemId].confirmed = true;
            items[itemId].status = Status.CONFIRMED;
            totalConfirmed++;
        }else {
           items[itemId].status = Status.DISPUTTED; 
        }

        emit Action (
            itemId,
            "DISPUTTED",
            Status.DISPUTTED,
            msg.sender
        );

        return true;
    }

    function refundItem(uint256 itemId) external returns (bool) {
        require(msg.sender == escAcc, "Only Escrow allowed");
        require(!items[itemId].confirmed, "Service already provided");

        payTo(items[itemId].owner, items[itemId].amount);
        escBal -= items[itemId].amount;
        items[itemId].status = Status.REFUNDED;
        totalDisputed++;

        emit Action (
            itemId,
            "REFUNDED",
            Status.REFUNDED,
            msg.sender
        );

        return true;
    }

    function withdrawFund(
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == escAcc, "Only Escrow allowed");
        require(amount > 0 ether && amount <= escAvailBal, "Zero withdrawal not allowed");

        payTo(to, amount);
        escAvailBal -= amount;

        emit Action (
            block.timestamp,
            "WITHDRAWED",
            Status.WITHDRAWED,
            msg.sender
        );

        return true;
    }

    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}
