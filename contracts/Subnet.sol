// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Subnet is OwnableUpgradeable {
    
    mapping(address => address) public stakeAddresses;

    bool public withdrawalEnabled;
    bool public locked;
    IERC20 tokenContract;
    uint256 public minStakable;
    uint256 public waitDuration;
    


    // Starts
    mapping(bytes => mapping(address => StakeStruct[])) public subnetBalances;
    mapping(bytes => mapping(address => uint256)) public subnetStakerBalances;
    mapping(bytes => uint256) public subnetBalance;

    mapping(address => mapping(bytes => int32)) public unstakeOrders;


    struct StakeStruct{
        uint256 amount;
        uint256 timestamp;
    }

    struct OrderStruct{
        uint256 amount;
        uint256 timestamp;
    }



    event StakeEvent(
        address indexed account,
        StakeStruct stake
    );

    event UnStakeEvent(
        address indexed account,
        StakeStruct stake
    );
    
    // Ends

    


   

    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    
    function initialize(address _address) public initializer {
        tokenContract = IERC20(_address);
        minStakable = 5000 * 10**18;
        __Ownable_init(msg.sender);

        
    }

    function stake( string memory subnetId, uint256 amount) public {
        require(amount > 0, "You need to stake the minimum amount of tokens");
        require(amount >= minStakable, "You need to stake more than the minimum stake");
        bytes memory bytesVal = abi.encodePacked(subnetId);
        StakeStruct memory stakeVal = StakeStruct(amount, block.timestamp);
        // uint256 length  = subnetBalances[bytesVal][msg.sender].length;
        subnetBalances[bytesVal][msg.sender].push(stakeVal);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        subnetStakerBalances[bytesVal][msg.sender] += amount;
        subnetBalance[bytesVal] += amount;
        emit StakeEvent(msg.sender, stakeVal);
    }


    function getSubnetBalance(string memory subnetId)
        public
        view
        returns (uint256)
    {
        bytes memory bytesVal = abi.encodePacked(subnetId);
        // return minConst * (1 + (stakerCount/100)**2);   
        return subnetBalance[bytesVal];   
    }
    
    function getSubnetAccountBalance(string memory subnetId, address addr)
        public
        view
        returns (uint256)
    {
        bytes memory bytesVal = abi.encodePacked(subnetId);
        // return minConst * (1 + (stakerCount/100)**2);   
        return subnetStakerBalances[bytesVal][addr];   
    }
    
    

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake(string memory subnetId) public noReentrancy {
        require(withdrawalEnabled, "Withdrawal is not enabled");
        require(getSubnetAccountBalance(subnetId, msg.sender) > 0, "Inadequate Withdrawal Balance");
        // bytes memory bytesVal = abi.encodePacked(subnetId);
        // tokenContract.transfer(msg.sender, stakeBalance[msg.sender]);
        // emit UnStakeEvent(
        //     msg.sender,
        //     stakeBalance[msg.sender],
        //     block.timestamp
        // );
        // stakeBalance[msg.sender] = 0;
    }

    function withdrawableAmount() public pure returns (uint) {
        uint total;
        return total;
    }

    


   


    
    


    

    function setMinStakable(uint256 _minStakable) public onlyOwner {
        minStakable = _minStakable;
    }

    

    function setWaitDuration(uint256 _waitDuration) public onlyOwner {
        waitDuration = _waitDuration;
    }

    function rewardValidator(
        // string memory validator,
         string memory subnetId, uint256 amount) public {
        
        bytes memory bytesVal = abi.encodePacked(subnetId);
        require(getSubnetBalance(subnetId) >= amount, "Amount should not be greater than subnet balance");
        subnetBalance[bytesVal] -= amount;
        // subnetStakerBalances[bytesVal][msg.sender] -= amount;
        tokenContract.transfer(msg.sender, amount);

        
    }

    
}
