
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const StakingModule = buildModule("StakingModule", (m) => {

  const tokenAddress = m.getParameter<string>("tokenAddress", "");
  
 

  const StakingContract = m.contract("tokenAddress", [tokenAddress] );


  return { StakingContract };
});

export default StakingModule;
