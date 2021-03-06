// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./extensions/ERC20Capped.sol";

/// @title Wisdom3Token
/// @author Atsushi Mandai
/// @notice Basic functions of the ERC20 Token WSDM for Wisdom3 will be written here.
contract Wisdom3Token is ERC20Capped {

    /** 
    * @dev ERC20 Token for Wisdom3 is "Wisdom3" and its ticker is "WSDM".
    * max supply of the token will be 100,000,000.
    * Founder takes 10% of the max supply as an incentive for him and early collaborators.
    * All the remaining tokens will be minted through a non-arbitrary algorithm.
    */
    constructor () ERC20 ("Wisdom3", "WSDM") ERC20Capped(100000000 * (10**uint256(18)))
    {
        ERC20._mint(_msgSender(),10000000 * (10**uint256(18)));
    }

}