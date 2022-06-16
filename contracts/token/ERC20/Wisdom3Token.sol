// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./extensions/ERC20Capped.sol";

contract Wisdom3Token is ERC20Capped {

    constructor () ERC20 ("Wisdom", "WSDM") ERC20Capped(1000000000 * (10**uint256(18)))
    {
        _mint(msg.sender,1000000000 * (10**uint256(18)));
    
    }
}