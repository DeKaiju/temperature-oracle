import { ethers } from "hardhat";

async function main() {
  const Validator = await ethers.getContractFactory("Validator");
  const validator = await Validator.deploy("kono_erc20_contract_address");
  await validator.deployed();
  console.log("Validator deployed to:", validator.address);

  const Aggregator = await ethers.getContractFactory("Aggregator");
  const aggregator = await Aggregator.deploy(validator.address, "kono_erc20_contract_address");
  await aggregator.deployed();
  console.log("Aggregator deployed to:", aggregator.address);

  const setAggregatorAddressTx = await validator.setAggregatorAddress(aggregator.address);
  await setAggregatorAddressTx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
