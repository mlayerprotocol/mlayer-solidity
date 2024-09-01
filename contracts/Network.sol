// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ChainInfo} from "./common/ChainInfo.sol";
import {console} from "hardhat/console.sol";

contract Network is OwnableUpgradeable, AccessControlUpgradeable {
    bool public locked;
    uint256 private messagePrice;
    uint256 private startTime;
    uint256 public startBlock;
    uint256 public blockTime;
   
    mapping(uint256=>uint256) public cycleMessagePrice;
    MessagePriceUpdate[] public priceHistory;
    bytes32 public constant MESSAGE_PRICE_MANAGER = keccak256("MESSAGE_PRICE_MANAGER");


    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyTest() {
        require(block.chainid == 31337,"unauthorized");
        _;
    }

    struct MessagePriceUpdate {
        uint price;
        uint from;
        uint to;
    }
    event PriceUpdated(uint cycle, uint price);

    

    function initialize(
        uint256 _blockTime,
        uint _startBlock
    ) public initializer {
        __Ownable_init(msg.sender);
         __AccessControl_init();
         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MESSAGE_PRICE_MANAGER, DEFAULT_ADMIN_ROLE);
        messagePrice = 1 * 10 ** 15;
        startTime = block.timestamp;
        startBlock = block.number;
        blockTime = _blockTime;
        if (_startBlock > 0) {
            startBlock = _startBlock;
        }
    }


    function withdraw(address token, address to, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20(token).transfer(to, amount), "transfer failed");
        }
    }

    function searchPriceHistory(uint256 cycle) public view returns (uint256) {
        uint len = priceHistory.length;
       
        if (len==0) {
             
            return messagePrice;
        }
        int256 low = 0;
        int256 high = int256(len - 1);
       
        while (low <= high) {
            int256 mid = low + (high - low) / 2;
            MessagePriceUpdate memory currentRange = priceHistory[uint256(mid)];
            if (cycle >= currentRange.from && cycle <= currentRange.to) {
                // Target is within the range
                return currentRange.price;
            } else if (cycle < currentRange.from) {
                // Search the left half
                high = mid - 1;
            } else {
                // Search the right half
                low = mid + 1;
            }
        }
        return messagePrice;
    }
    /*
     * getMessagePrice: returns the message price
     * @param cycle uint
     */
    function getMessagePrice(uint cycle) public view returns (uint256) {
        uint256 cyclePrice = cycleMessagePrice[cycle];
        require(cycle <= getCurrentCycle(), "invalid cycle");
        if (cyclePrice == 0) {
           return searchPriceHistory(cycle);
        }
        return cyclePrice;
    }

    /*
     * getMessagePrice: returns the message price
     * @param cycle uint
     */
    function getCurrentMessagePrice() public view returns (uint256) {
        return getMessagePrice(getCurrentCycle());
    }

    function setMessagePrice(uint price) public onlyRole(MESSAGE_PRICE_MANAGER) {
        uint curCycle = getCurrentCycle();
        cycleMessagePrice[curCycle] = messagePrice;
        cycleMessagePrice[curCycle+1] = price;
        uint from = 0;
        if (priceHistory.length > 0) {
                from = priceHistory[priceHistory.length-1].to + 1;
        }
        priceHistory.push(MessagePriceUpdate({
                price: messagePrice,
                from: from,
                to: curCycle
            }));
        messagePrice = price;
        emit PriceUpdated(curCycle+1, price);
    }

    function getChainInfo()
        public
        view
        returns (ChainInfo memory) {
        return ChainInfo({
            startTime: startTime * 1000,
            chainId: block.chainid,
            startBlock: startBlock,
            currentBlock: block.number,
            currentEpoch: getCurrentEpoch(),
            currentCycle: getCurrentCycle()
        });
    }

    function getStartTime() public view returns (uint256) {
        return startTime * 1000;
    }

     function setStartBlock(uint256 _blockNum) public onlyOwner onlyTest {
       startBlock = _blockNum;
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
