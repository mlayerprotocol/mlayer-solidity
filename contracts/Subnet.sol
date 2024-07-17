// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1} from "./libs/schnorr/LibSecp256k1.sol";

import {LibSchnorrExtended} from "./libs/schnorr/LibSchnorrExtended.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";
import {ISentryContract} from "./interfaces/ISentryNode.sol";

contract Subnet is OwnableUpgradeable {
    
    mapping(address => address) public stakeAddresses;
   

    bool public withdrawalEnabled;
    bool public locked;
    IERC20 tokenContract;
    uint256 public minStakable;
    uint256 public waitDuration;
    ISentryContract public sentryContract;
   
    


    // Starts
    mapping(bytes32 => mapping(address => StakeStruct[])) public subnetBalances;
    mapping(bytes32 => mapping(address => uint256)) public subnetStakerBalances;
    mapping(bytes32 => uint256) public subnetBalance;

    mapping(address => mapping(bytes => int32)) public unstakeOrders;
    mapping(address => uint) public proofProviderRewards;


    struct StakeStruct{
        uint256 amount;
        uint256 timestamp;
    }

    struct OrderStruct{
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardClaimData{
        bytes subnetId;
        uint256 count;
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

    
    function initialize(address _address, address _sentryContract) public initializer {
        tokenContract = IERC20(_address);
        minStakable = 5000 * 10**18;
        __Ownable_init(msg.sender);
        sentryContract = ISentryContract(_sentryContract);
    }

    function stake( bytes32 subnetId, uint256 amount) public {
        require(amount > 0, "You need to stake the minimum amount of tokens");
        require(amount >= minStakable, "You need to stake more than the minimum stake");
        StakeStruct memory stakeVal = StakeStruct(amount, block.timestamp);
        // uint256 length  = subnetBalances[bytesVal][msg.sender].length;
        subnetBalances[subnetId][msg.sender].push(stakeVal);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        subnetStakerBalances[subnetId][msg.sender] += amount;
        subnetBalance[subnetId] += amount;
        emit StakeEvent(msg.sender, stakeVal);
    }


    function getSubnetBalance(bytes32 subnetId)
        public
        view
        returns (uint256)
    {
       //  bytes memory bytesVal = abi.encodePacked(subnetId);
        // return minConst * (1 + (stakerCount/100)**2);   
        return subnetBalance[subnetId];   
    }
    
    function getSubnetAccountBalance(bytes32 subnetId, address addr)
        public
        view
        returns (uint256)
    {
        return subnetStakerBalances[subnetId][addr];   
    }
    
    

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake(bytes32 subnetId) public noReentrancy {
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

    function hashRewardData(RewardClaimData[] calldata claimData) pure internal returns(bytes32 hash) {
        uint len = claimData[0].subnetId.length;
        for (uint i; i < claimData.length; i++) {
            hash = keccak256(abi.encodePacked(hash, claimData[i].subnetId[len-6:], uint64(claimData[i].count)));
        }
    }

    function rewardValidator(
        bytes memory validatorPublicKey,
        RewardClaimData[] calldata claimData,
        uint cycle,
        bytes[] calldata signers,
        bytes memory message, 
        address committment, 
        uint256 signature,
        bytes32 messageHash
        ) public {
            //1. loop through validators and hash the last 6 bytes of the subnetId and the amount with the previous hash
            bytes32 dataHash = hashRewardData(claimData);

            //2. loop through signers starting from the last
                // a. check if signer is present in list of valid signers for batch
                // b. get the license count from the ISentry contract, if count is 0, throw error (//TODO check if operator was recently updated if yes, then its likely valid  )
                // c. if all valid are valid operators, generate the aggregate public key
            //3. keccak256 hash the concatenation of the dataHash, the cycle and the validators public key
            //4. Verify the signature using the new hash as the message
            //5. If its valid, deduct all amount from the subnate stake and credit the account associated with the validator
            //6. Reward the operators that provided the proof

            // bool ok = LibSchnorr.verifySignature(
            //     pubKeys.aggregatePublicKeys(),
            //     message,
            //     bytes32(signature),
            //     commitment
            // );



        // bytes memory bytesVal = abi.encodePacked(subnetId);
        // require(getSubnetBalance(subnetId) >= amount, "Amount should not be greater than subnet balance");
        // subnetBalance[bytesVal] -= amount;
        // subnetStakerBalances[bytesVal][msg.sender] -= amount;
        // tokenContract.transfer(msg.sender, amount);

        
    }    
}
