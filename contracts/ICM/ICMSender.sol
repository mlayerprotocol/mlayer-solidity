// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../common/IICMRouter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ICMSender is OwnableUpgradeable {

    IICMRouter public icmRouter;

    event NewICMMessage (
        address sender,
        address caller,
        string networkName,
        uint chainId,
        bytes contractAddress,
        address relayer,
        bytes message
    );

    constructor(address _icmRouter) {
        icmRouter = IICMRouter(_icmRouter);
    }
    
  
   function sendMessage(string memory networkName, uint chainId, bytes memory contractAddress, address relayer, bytes calldata message)  public returns(uint) {
        // add fee logic
        uint256 gasRemaining = gasleft();
        tx.gasprice;
        emit NewICMMessage(msg.sender, address(this), networkName, chainId, contractAddress, relayer, message);
        uint256 gasRemaining2 = gasleft();
        uint256 gasConsumed = gasRemaining - gasRemaining2;
        return gasConsumed;
   }

   function estimateFee(string memory networkName, uint chain)  public view returns (uint256) {

   }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }

}
