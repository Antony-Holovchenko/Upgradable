//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NeonToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {  

    event Minted(address minter, uint256 amount);
   
    function initialize(string memory _name, string memory _symbol) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init(msg.sender);
    }

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender,  _amount);
        emit Minted(msg.sender, _amount);
    }
}