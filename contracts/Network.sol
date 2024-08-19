// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ChainInfo} from "./common/ChainInfo.sol";

contract Network is OwnableUpgradeable {
    
    bool public locked;
    uint256 public messagePrice;
   
   
    uint256 public startTime;
    uint256 public startBlock;
    uint256 public blockTime;

    
    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    function initialize(
        uint256 _blockTime,
        uint _startBlock
    ) public initializer {
        __Ownable_init(msg.sender);
        messagePrice = 1 * 10 ** 15;
       
       startTime = block.timestamp;
        startBlock = block.number;
        blockTime = _blockTime;
        if (_startBlock > 0) {
            startBlock = _startBlock;
        }
    }

    function withdraw(address token, address to, uint amount) public onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20(token).transfer(to, amount), "transfer failed");
        }
    }

    function getMessagePrice() public view returns (uint256) {
        return messagePrice;
    }

    function setMessagePrice(uint price) public onlyOwner {
        messagePrice = price;
    }


    function getChainInfo()
        public
        view
        returns (ChainInfo memory)
    {
        return ChainInfo({
            startTime: startTime,
            startBlock: startBlock,
            currentBlock: block.number,
            currentEpoch: getCurrentEpoch(),
            currentCycle: getCurrentCycle()
        });
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getStartBlock() public view returns (uint256) {
        return startBlock;
    }

    function getEpoch(
        uint256 blockNumber
    ) public view returns (uint256) {
        return ((blockNumber - startBlock) * blockTime) / ((1 days) / 2);
    }

    /**
     * ~ 24 hours
     */
    function getCycle(uint256 blockNumber) public view returns (uint256) {
        return ((blockNumber - startBlock) * blockTime) / ((1 days));
    }

    function getCurrentCycle() public view returns (uint256) {
        return getCycle(block.number);
    }

    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /**
     * ~ 12 hour epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return getEpoch(block.number);
    }

    function getCurrentYear(uint256 _block) public view returns (uint256) {
        return
            ((_block - startBlock) * blockTime) / ((365 days) + ((1 days) / 4));
    }

}
