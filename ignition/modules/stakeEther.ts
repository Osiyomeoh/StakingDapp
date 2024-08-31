import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingModule = buildModule("StakingModule", (m) => {
  
  const stakingContract = m.contract("EtherStaking");

  return { stakingContract };
});

export default StakingModule;
