// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "./common/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import {IcmToken} from "./IcmToken.sol";

contract xMLTToken is IcmToken {
    

     constructor(string memory name, string memory symbol, uint _totalSupply) IcmToken(name, symbol, _totalSupply) {
    }

    

}
