import React, { useState, useEffect } from "react";
import web3 from "./web3";
import GameLobby from "./contracts/GameLobby";

const GameLobbyInterface = () => {
  const [gameID, setGameID] = useState("");
  const [playerAddress, setPlayerAddress] = useState("");
  const [playerName, setPlayerName] = useState("");
  const [depositAmount, setDepositAmount] = useState("");
  const [gameStarted, setGameStarted] = useState(false);

  const handleNewGame = async () => {
    const accounts = await web3.eth.getAccounts();
    await GameLobby.methods.newGame(gameID).send({
      from: accounts[0]
    });
    setGameStarted(true);
  };

  const handleDeposit = async () => {
    const accounts = await web3.eth.getAccounts();
    await GameLobby.methods
      .deposit(playerAddress, playerName, gameID, depositAmount)
      .send({
        from: accounts[0],
        value: web3.utils.toWei(depositAmount, "ether")
      });
  };

  const handleStartGame = async () => {
    const accounts = await web3.eth.getAccounts();
    await GameLobby.methods.startGame(gameID).send({
      from: accounts[0]
    });
  };

  return (
    <div>
      <h2>Game Lobby</h2>
      <p>
        This interface allows you to interact with the Game Lobby smart contract
        on the Ethereum blockchain.
      </p>
      <hr />
      <h3>Create New Game</h3>
      <div>
        <label>Enter Game ID: </label>
        <input
          type="text"
          value={gameID}
          onChange={e => setGameID(e.target.value)}
        />
      </div>
      <button onClick={handleNewGame}>Create Game</button>
      <hr />
      <h3>Join Game</h3>
      <div>
        <label>Enter Player Address: </label>
        <input
          type="text"
          value={playerAddress}
          onChange={e => setPlayerAddress(e.target.value)}
        />
      </div>
      <div>
        <label>Enter Player Name: </label>
        <input
          type="text"
          value={playerName}
          onChange={e => setPlayerName(e.target.value)}
        />
      </div>
      <div>
        <label>Enter Deposit Amount (in Ether): </label>
        <input
          type="text"
          value={depositAmount}
          onChange={e => setDepositAmount(e.target.value)}
        />
      </div>
      <button onClick={handleDeposit}>Deposit</button>
      <hr />
      {gameStarted ? (
        <div>
            <h3>Start Game</h3>
            <button onClick={handleStartGame}>Start Game</button>
        </div>
      ) : null}
    </div>
