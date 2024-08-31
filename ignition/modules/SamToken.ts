
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const TokenModule = buildModule("TokenModule", (m) => {

  const name = m.getParameter<string>("name", "Sam");
  
  const symbol = m.getParameter<string>("symbol", "S");

  const samToken = m.contract("StakeSamToken", [name, symbol] );


  return { samToken };
});

export default TokenModule;
