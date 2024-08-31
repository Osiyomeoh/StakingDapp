//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract SamToken is ERC20{

    address public owner;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
        owner = msg.sender;
        _mint(msg.sender, 100000e18);
        }
        function mint(uint _amount) external {
            require(msg.sender == owner, "you are not owner");
            _mint(msg.sender, _amount * 1e18);
        }

        




    }
