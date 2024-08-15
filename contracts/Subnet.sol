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

contract Subnet is OwnableUpgradeable {
    mapping(address => address) public stakeAddresses;

    bool public withdrawalEnabled;
    bool public locked;
    IERC20 tokenContract;
    IERC20 xTokenContract;
    uint256 public minStakable;
    uint256 public waitDuration;
    INodeContract public sentryContract;
    INodeContract public superNodeContract;
    uint public sentryBaseReward;
    uint public validatorBaseReward;

    // Starts
    mapping(bytes16 => mapping(address => StakeStruct[])) public subnetBalances;
    mapping(bytes16 => mapping(address => uint256)) public subnetStakerBalances;
    mapping(bytes16 => uint256) public subnetCredit;
    mapping(bytes16 => uint256) public subnetDebt;

    mapping(address => mapping(bytes => int32)) public unstakeOrders;
    mapping(address => uint) public proofProviderRewards;

    mapping(address => SwapStruct[]) public userSwaps;
    mapping(address => uint256) public userSwapsBalances;

    PenaltyStruct[] public penalties;

    struct StakeStruct {
        uint256 amount;
        uint256 timestamp;
    }

    struct OrderStruct {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardClaimData {
        bytes16 subnetId;
        uint256 amount;
    }

    event StakeEvent(address indexed account, StakeStruct stake);

    event UnStakeEvent(address indexed account, StakeStruct stake);

    struct SwapStruct {
        uint id;
        uint amount;
        uint durationDays;
        uint256 timestamp;
        uint claimAmount;
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

    function subnetBalance(bytes16 subnetId) public view returns (uint) {
        if (subnetCredit[subnetId] < subnetDebt[subnetId]) {
            return 0;
        } else {
            return subnetCredit[subnetId] - subnetDebt[subnetId];
        }
    }

    function initialize(
        address tokenAddress,
        address xTokenAddress,
        address _sentryContract,
        address _superNodeContract
    ) public initializer {
        tokenContract = IERC20(tokenAddress);
        xTokenContract = IERC20(xTokenAddress);
        minStakable = 5000 * 10 ** 18;
        __Ownable_init(msg.sender);
        sentryContract = INodeContract(_sentryContract);
        superNodeContract = INodeContract(_superNodeContract);
        penalties.push(PenaltyStruct(5, 30));
        penalties.push(PenaltyStruct(20, 90));
        penalties.push(PenaltyStruct(70, 180));
    }

    function stake(bytes16 subnetId, uint256 amount) public {
        require(amount > 0, "You need to stake the minimum amount of tokens");
        require(
            amount >= minStakable,
            "You need to stake more than the minimum stake"
        );
        StakeStruct memory stakeVal = StakeStruct(amount, block.timestamp);
        // uint256 length  = subnetBalances[bytesVal][msg.sender].length;
        subnetBalances[subnetId][msg.sender].push(stakeVal);
        // tokenContract.transferFrom(msg.sender, address(this), amount);
        subnetStakerBalances[subnetId][msg.sender] += amount;
        subnetCredit[subnetId] += amount;
        emit StakeEvent(msg.sender, stakeVal);
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
    function getSubnetAccountBalance(
        bytes16 subnetId,
        address addr
    ) public view returns (uint256) {
        return subnetStakerBalances[subnetId][addr];
    }

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake(bytes16 subnetId) public noReentrancy {
        require(withdrawalEnabled, "Withdrawal is not enabled");
        require(
            getSubnetAccountBalance(subnetId, msg.sender) > 0,
            "Inadequate Withdrawal Balance"
        );
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

    function setSentryBaseReward(uint256 _baseReward) public onlyOwner {
        sentryBaseReward = _baseReward;
    }

    function setValidatorBaseReward(uint256 _baseReward) public onlyOwner {
        validatorBaseReward = _baseReward;
    }

    function hashRewardData(
        RewardClaimData[] calldata claimData
    ) public pure returns (bytes32 hash) {
        // uint len = claimData[0].subnetId.length;
        for (uint i; i < claimData.length; i++) {
            if (i == 0) {
                hash = keccak256(
                    abi.encodePacked(
                        bytes6(claimData[i].subnetId),
                        claimData[i].amount
                    )
                );
            } else {
                hash = keccak256(
                    abi.encodePacked(
                        hash,
                        bytes6(claimData[i].subnetId),
                        claimData[i].amount
                    )
                );
            }
        }
        return hash;
    }

    function getMinSignerCount(
        uint cycleNumLicences
    ) public pure returns (uint) {
        if (cycleNumLicences < 5) {
            return cycleNumLicences - 1;
        }
        if (cycleNumLicences < 3) {
            return 1;
        }
        uint min = cycleNumLicences / 3;
        if (min > 20) {
            return 20;
        }
        return min;
    }

    struct Claim {
        bytes validator;
        RewardClaimData[] claimData;
        uint256 cycle;
        uint256 index;
        LibSecp256k1.Point[] signers;
        address commitment;
        bytes signature;
        uint256 totalCost;
    }
    function getClaimHash(Claim calldata claim) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hashRewardData(claim.claimData),
                    block.chainid,
                    claim.cycle,
                    claim.index,
                    claim.totalCost,
                    claim.validator
                )
            );
    }
    function verifyClaim(
        Claim calldata claim
    ) public view returns (bool, bytes32) {
        bytes32 claimHash = getClaimHash(claim);
        return (
            LibSchnorr.verifySignature(
                LibSchnorrExtended.aggregatePublicKeys(claim.signers),
                claimHash,
                bytes32(claim.signature),
                claim.commitment
            ),
            claimHash
        );
    }
    function rewardValidator(Claim calldata claim) public {
        {
            require(claim.cycle < sentryContract.getCurrentCycle()-1,"Cannot claim current or future cycles");
            //1. loop through validators and hash the first 6 bytes of the subnetId and the amount with the previous hash
            // address[] memory validSigners;
            //2. keccak256 hash the concatenation of the dataHash, the cycle and the validators public key
            //3. Verify the signature using the new hash as the message
            (bool valid, bytes32 claimHash) = verifyClaim(claim);
            require(valid, "invalid signature");
            uint licenceCount = sentryContract.getCycleLicenseCount(
                claim.cycle
            );

            //3. loop through signers starting from the last
            // uint hash = uint(claimHash);
            // uint salt = (uint(claimHash) % 1000) + 1;
            //  uint startLicence = ((hash/salt) % licenceCount) + 1000;
            uint validCount;
            uint signerIndex = 0;
            uint minSigners = getMinSignerCount(licenceCount);
            xTokenContract.operatorMint(
                sentryContract.operatorsOwner(claim.validator),
                validatorBaseReward + (claim.totalCost / 2)
            );
            for (uint i = 0; i < 30; i++) {
                uint decodedLicence = MLUtils.lcg(
                    ((((uint(claimHash) / ((uint(claimHash) % 1000))) %
                        licenceCount) + 1000) +
                        (i * ((uint(claimHash) % 1000) + 1))) % licenceCount
                ) + 1000;
                bytes memory signer = LibSecp256k1Extended.pubKeyFromPoints(
                    claim.signers[signerIndex]
                );
                bytes memory owner = sentryContract.licenseOperator(
                    decodedLicence
                );
                if (keccak256(signer) == keccak256(owner)) {
                    validCount++;
                    signerIndex++;
                    // TODO mint/transfer xToken to the license owner
                    xTokenContract.operatorMint(
                        sentryContract.licenseOwner(decodedLicence),
                        sentryBaseReward +
                            (claim.totalCost / (2 * claim.signers.length))
                    );
                }
                if (
                    validCount >= (claim.signers.length - 1) ||
                    validCount >= minSigners * 2
                ) {
                    break;
                }
            }
            require(validCount >= minSigners, "not enough signers");
            // a. check if signer is present in list of valid signers for batch
            // b. get the license count from the ISentry contract, if count is 0, throw error (//TODO check if operator was recently updated if yes, then its likely valid  )
            // c. if all valid are valid operators, generate the aggregate public key
            for (uint i; i < claim.claimData.length; i++) {
                uint cost = claim.claimData[i].amount;
                bytes16 subnet = claim.claimData[i].subnetId;
                if (subnetCredit[subnet] < cost) {
                    // uint diff = cost - subnetBalance[claimData.subnetId];
                    // subnetBalance[claimData.subnetId] = 0;
                    subnetDebt[subnet] += cost;
                } else {
                    subnetCredit[subnet] -= cost;
                }
            }
        }
        // distribute the reward
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
    function swapXForTokens(
        uint amount,
        uint durationDays
    ) public noReentrancy {
        uint claimedAmount = getRedemptionAmount(amount, durationDays);

        SwapStruct memory swapStruct = SwapStruct(
            userSwaps[msg.sender].length + 1,
            amount,
            durationDays,
            block.timestamp,
            claimedAmount
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

        tokenContract.transferFrom(
            msg.sender,
            address(this),
            userSwap.claimAmount
        );
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
