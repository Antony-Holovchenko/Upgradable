// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This is a contract created to use ERC20 token in local testing purposes.
contract TestStakingToken is ERC20 {
    constructor() ERC20("Test", "Tst") {
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender,  _amount);
    }
}