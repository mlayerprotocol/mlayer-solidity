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
    IERC20 xTokenContract;
    uint256 public minStakable;
    uint256 public waitDuration;
    ISentryContract public sentryContract;
    ISentryContract public superNodeContract;
   
    


    // Starts
    mapping(bytes16 => mapping(address => StakeStruct[])) public subnetBalances;
    mapping(bytes16 => mapping(address => uint256)) public subnetStakerBalances;
    mapping(bytes16 => uint256) public subnetBalance;

    mapping(address => mapping(bytes => int32)) public unstakeOrders;
    mapping(address => uint) public proofProviderRewards;


    mapping(address => SwapStruct[]) public userSwaps;
    mapping(address => uint256) public userSwapsBalances;


    
    PenaltyStruct[] public penalties;


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


    struct SwapStruct{
        uint id;
        uint amount;
        uint durationDays;
        uint256 timestamp;
    }


    struct PenaltyStruct{
        
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

    
    function initialize(address tokenAddress, address xTokenAddress, address _sentryContract, address _superNode) public initializer {
        tokenContract = IERC20(tokenAddress);
        xTokenContract = IERC20(xTokenAddress);
        minStakable = 5000 * 10**18;
        __Ownable_init(msg.sender);
        sentryContract = ISentryContract(_sentryContract);
        superNodeContract = ISentryContract(_superNode);

        //  0, 30, 90 or 180 
        // 5%, 20%, 70 and 100% 
        penalties = [
            PenaltyStruct(5, 30),
            PenaltyStruct(20, 90),
            PenaltyStruct(70, 180)
        ];
    }

    function stake( bytes16 subnetId, uint256 amount) public {
        require(amount > 0, "You need to stake the minimum amount of tokens");
        require(amount >= minStakable, "You need to stake more than the minimum stake");
        StakeStruct memory stakeVal = StakeStruct(amount, block.timestamp);
        // uint256 length  = subnetBalances[bytesVal][msg.sender].length;
        subnetBalances[subnetId][msg.sender].push(stakeVal);
        // tokenContract.transferFrom(msg.sender, address(this), amount);
        subnetStakerBalances[subnetId][msg.sender] += amount;
        subnetBalance[subnetId] += amount;
        emit StakeEvent(msg.sender, stakeVal);
    }


    function getSubnetBalance(bytes16 subnetId)
        public
        view
        returns (uint256)
    {
       //  bytes memory bytesVal = abi.encodePacked(subnetId);
        // return minConst * (1 + (stakerCount/100)**2);   
        return subnetBalance[subnetId];   
    }
    
    function getSubnetAccountBalance(bytes16 subnetId, address addr)
        public
        view
        returns (uint256)
    {
        return subnetStakerBalances[subnetId][addr];   
    }
    
    

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake(bytes16 subnetId) public noReentrancy {
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
        bytes16 messageHash
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
            //     bytes16(signature),
            //     commitment
            // );



        // bytes memory bytesVal = abi.encodePacked(subnetId);
        // require(getSubnetBalance(subnetId) >= amount, "Amount should not be greater than subnet balance");
        // subnetBalance[bytesVal] -= amount;
        // subnetStakerBalances[bytesVal][msg.sender] -= amount;
        // tokenContract.transfer(msg.sender, amount);

        
    } 

    /** time based swap. Penalize for early swap.
     * @dev 
     * @param amount {uint} the amount of token to be swapped in wei
     * @param durationDays {uint} the number of days the request will mature
     */ 
    function swapXForTokens(uint amount, uint durationDays ) public noReentrancy {

        
        SwapStruct memory swapStruct = SwapStruct(userSwaps[msg.sender].length+1, amount,durationDays, block.timestamp);
        userSwaps[msg.sender].push(swapStruct);
        userSwapsBalances[msg.sender] += amount;
        xTokenContract.transferFrom(msg.sender, address(this), amount);
        if(durationDays == 0){
            claimToken(swapStruct.id);
            return;
        }
    }  

    /**
     * claim previously initiated swap. Only possible after selected duration.
     * @param swapID {uint} the index of the swap
     */
    function claimToken(uint swapID) public  noReentrancy {
        SwapStruct[] memory userSwapStructs =  userSwaps[msg.sender];
        
        SwapStruct memory userSwap = userSwapStructs[swapID];
        // Compute Deductoion
        uint256 startTime = userSwap.timestamp;
        uint256 endTime = block.timestamp;
        
        require(endTime > startTime, "End time must be greater than start time");
        require(endTime >= startTime, "End time must be greater than or equal to start time");
        uint256 differenceInDays = (endTime - startTime) / 86400; // 86400 seconds in a day

        require(differenceInDays < userSwap.durationDays, "Duration has not been reached");

        uint amount = userSwap.amount;
        //  0, 30, 90 or 180 
        // 5%, 20%, 70 and 100% 
        
        for (uint256 index = 0; index < penalties.length; index++) {
            PenaltyStruct memory penalty = penalties[index];

            // if(differenceInDays < penalty.durationDays){
            if(userSwap.durationDays == penalty.durationDays){
                amount = (amount * penalty.percentage) / 100;
                break;
            }
            
        }
        
        tokenContract.transferFrom(msg.sender, address(this), amount);
        // xTokenContract.transfer(msg.sender,  userSwap.amount);
        
        
    }   

    
    /**
     * cstraighforward swap, just transfer then one-one
     * @param amount {uint} the amount of token to be swapped for X
     */
     function swapTokensForX(uint amount ) public noReentrancy {
        
        tokenContract.transferFrom(msg.sender, address(this), amount);
        xTokenContract.transfer(msg.sender,  amount);
    }   


    function updatePenalties(PenaltyStruct[] memory _penalties) public onlyOwner {
        penalties = _penalties;
    }
}
