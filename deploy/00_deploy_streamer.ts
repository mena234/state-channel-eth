import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Streamer } from "../typechain-types";

/**
 * Deploys a contract named "Streamer" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployStreamer: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {

  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("Streamer", {
    from: deployer,
    // Contract constructor arguments
    args: [],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // *Checkpoint 1*
  // Get the deployed contract
  const streamer: Streamer = await hre.ethers.getContract("Streamer", deployer);

  // Transfer ownership to your front end address
  console.log("\n 🤹  Sending ownership to frontend address...\n");
  const ownerTx = await streamer.transferOwnership("0xc80127BC1Af2bFeD1438151030F33Ae1Ef91915E");
  console.log("\n       confirming...\n");
  const ownershipResult = await ownerTx.wait();
  if (ownershipResult) {
    console.log("       ✅ ownership transferred successfully!\n");
  }
};

export default deployStreamer;

deployStreamer.tags = ["Streamer"];
