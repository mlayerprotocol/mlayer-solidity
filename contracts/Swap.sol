// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1} from "./libs/schnorr/LibSecp256k1.sol";
import {console} from "hardhat/console.sol";
import {LibSchnorrExtended} from "./libs/schnorr/LibSchnorrExtended.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";
import {INodeContract} from "./interfaces/ISentryNode.sol";
import {MLUtils} from "./libs/mlayer/utils.sol";
import {INetwork} from "./interfaces/INetwork.sol";

contract Swap is OwnableUpgradeable {
    bool public locked;
    IERC20 tokenContract;
    IERC20 xTokenContract;
  
    mapping(address => mapping(bytes => int32)) public unstakeOrders;
    mapping(address => uint) public proofProviderRewards;

    mapping(address => SwapStruct[]) public userSwaps;
    mapping(address => uint256) public userSwapsBalances;

    PenaltyStruct[] public penalties;



    struct SwapStruct {
        uint id;
        uint amount;
        uint durationDays;
        uint256 timestamp;
        uint claimAmount;
        uint256 claimedAt;
    }

    struct PenaltyStruct {
        uint percentage;
        uint durationDays;
    }

    // Ends
    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    function initialize(
        address tokenAddress,
        address xTokenAddress
    ) public initializer {
        tokenContract = IERC20(tokenAddress);
        xTokenContract = IERC20(xTokenAddress);
        __Ownable_init(msg.sender);
        penalties.push(PenaltyStruct(5, 30));
        penalties.push(PenaltyStruct(20, 90));
        penalties.push(PenaltyStruct(70, 180));
    }

    
   
    // function getSubnetBalance(bytes16 subnetId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //    bytes memory bytesVal = abi.encodePacked(subnetId);
    //   return minConst * (1 + (stakerCount/100)**2);
    //     return subnetBalance(subnetId);
    // }
 

    /** time based swap. Penalize for early swap.
     * @dev
     * @param amount {uint} the amount of token to be swapped in wei
     * @param durationDays {uint} the number of days the request will mature
     */
    function swapXForTokens(
        uint amount,
        uint durationDays
    ) public {
        uint claimedAmount = getRedemptionAmount(amount, durationDays);

        SwapStruct memory swapStruct = SwapStruct(
            userSwaps[msg.sender].length,
            amount,
            durationDays,
            block.timestamp,
            claimedAmount,
            0
        );
        userSwaps[msg.sender].push(swapStruct);
        userSwapsBalances[msg.sender] += amount;
        xTokenContract.transferFrom(msg.sender, address(this), amount);
        
        if (durationDays == 0) {
            claimToken(swapStruct.id);
            return;
        }
    }

    /**
     * claim previously initiated swap. Only possible after selected duration.
     * @param swapID {uint} the index of the swap
     */
    function claimToken(uint swapID) public noReentrancy {
        SwapStruct[] memory userSwapStructs = userSwaps[msg.sender];

        SwapStruct memory userSwap = userSwapStructs[swapID];

        require(
            userSwap.claimedAt == 0,
            "Claim has been collected"
        );


        // Compute Deductoion
        uint256 startTime = userSwap.timestamp;
        uint256 endTime = block.timestamp;

        // require(endTime > startTime, "End time must be greater than start time");
        // require(endTime >= startTime, "End time must be greater than or equal to start time");
        uint256 differenceInDays = (endTime - startTime) / 86400; // 86400 seconds in a day

        require(
            differenceInDays >= userSwap.durationDays,
            "Duration has not been reached"
        );

        // uint claimedAmount = getRedemptionAmount(userSwap.amount, differenceInDays );
        //         uint amount = userSwap.amount;
        //         //  0, 30, 90 or 180
        //         // 5%, 20%, 70 and 100%

        //         for (uint256 index = 0; index < penalties.length; index++) {
        //             PenaltyStruct memory penalty = penalties[index];
        // //
        //             if(differenceInDays < penalty.durationDays){
        //             // if(userSwap.durationDays == penalty.durationDays){
        //                 amount = (amount * penalty.percentage) / 100;
        //                 break;
        //             }

        //         }
    
        require(tokenContract.transfer(
            msg.sender,
            userSwap.claimAmount
        ),"Transfer failed");

        
        userSwaps[msg.sender][swapID].claimedAt = block.timestamp;
        // xTokenContract.transfer(msg.sender,  userSwap.amount);
    }

    function getRedemptionAmount(
        uint _amount,
        uint durationDays
    ) public view returns (uint) {
        uint amount = _amount;
        for (uint256 index = 0; index < penalties.length; index++) {
            PenaltyStruct memory penalty = penalties[index];
            if (durationDays < penalty.durationDays) {
                // if(userSwap.durationDays == penalty.durationDays){
                amount = (amount * penalty.percentage) / 100;
                break;
            }
        }

        return amount;
    }

    /**
     * cstraighforward swap, just transfer then one-one
     * @param amount {uint} the amount of token to be swapped for X
     */
    function swapTokensForX(uint amount) public noReentrancy {
        tokenContract.transferFrom(msg.sender, address(this), amount);
        xTokenContract.transfer(msg.sender, amount);
    }

    function updatePenalties(
        PenaltyStruct[] memory _penalties
    ) public onlyOwner {
        delete penalties;
        for(uint i; i<_penalties.length; i++) {
            penalties.push(_penalties[i]);
        }
    }
}
