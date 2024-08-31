
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// To deploy the staking contract for ERC20
const StakingModule = buildModule("StakingModule", (m) => {

  const tokenAddress = m.getParameter<string>("tokenAddress", "");
  
 

  const StakingContract = m.contract("token", [tokenAddress] );


  return { StakingContract };
});

export default StakingModule;
