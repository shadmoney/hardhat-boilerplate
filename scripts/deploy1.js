// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const path = require("path");

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());
  //const GameLobby = require("/Users/shadman/Desktop/hardhat-boilerplate/artifacts/contracts/GameLobby.sol/GameLobby.json");

  const developer = "0xa1e77237d52776Ac9Ee222911C748F83e6dEe82E"; // replace with the address of the developer
  const dao = "0xb3F825CC341F21545C8E5d87bC76e4696dB955c1"; // replace with the address of the dao
const timeWindow = 2800;

  const GameLobby = await ethers.getContractFactory("GameLobby");
  const game = await GameLobby.deploy(developer, dao, timeWindow);
  await game.deployed();

  console.log("Game Lobby address:", game.address);

    // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(game);
}

function saveFrontendFiles(game) {
  const fs = require("fs");
  const contractsDir = path.join(__dirname, "..", "frontend", "src", "contracts");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    path.join(contractsDir, "contract-address.json"),
    JSON.stringify({ Game: game.address }, undefined, 2)
  );

  const GameArtifact = artifacts.readArtifactSync("GameLobby");

  fs.writeFileSync(
    path.join(contractsDir, "GameLobby.json"),
    JSON.stringify(GameArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
