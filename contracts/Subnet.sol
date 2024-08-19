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

contract Subnet is OwnableUpgradeable {
    mapping(address => address) public stakeAddresses;
    mapping(uint=>mapping(bytes=>mapping(uint=>bool))) processedClaim;
    bool public withdrawalEnabled;
    bool public locked;
    IERC20 tokenContract;
    IERC20 xTokenContract;
    uint256 public minStakable;
    // uint256 public waitDuration;
    INodeContract public sentryContract;
    INodeContract public superNodeContract;
    uint public sentryBaseReward;
    uint public validatorBaseReward;
    INetwork public network;
    mapping(bytes32=>bool) multilocked;

    // Starts
    mapping(bytes16 => mapping(address => StakeStruct[])) public subnetBalances;
    mapping(bytes16 => mapping(address => uint256)) public subnetStakerBalances;
    mapping(bytes16 => uint256) public subnetCredit;
    mapping(bytes16 => uint256) public subnetDebt;

    mapping(address => mapping(bytes => int32)) public unstakeOrders;
    mapping(address => uint) public proofProviderRewards;



    struct StakeStruct {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardClaimData {
        bytes16 subnetId;
        uint256 amount;
    }

    event StakeEvent(address indexed account, StakeStruct stake);

    event UnStakeEvent(address indexed account, StakeStruct stake);


    // Ends
    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

     modifier claimLock(Claim memory claim) {
        bytes32 hash = keccak256(abi.encodePacked(claim.validator,claim.cycle, claim.index));
        require(!multilocked[hash], "Contract Locked");
        multilocked[hash] = true;
        _;
        multilocked[hash] = false;
    }

    function subnetBalance(bytes16 subnetId) public view returns (uint) {
        if (subnetCredit[subnetId] < subnetDebt[subnetId]) {
            return 0;
        } else {
            return subnetCredit[subnetId] - subnetDebt[subnetId];
        }
    }

    function initialize(
         address _network,
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
        network = INetwork(_network);
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

    // function setWaitDuration(uint256 _waitDuration) public onlyOwner {
    //     waitDuration = _waitDuration;
    // }

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
         if (cycleNumLicences <= 4) {
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

    function rewardValidator(Claim calldata claim) public claimLock(claim) {
        uint licenceCount;
        bytes32 claimHash;
        {
            require(!processedClaim[claim.cycle][claim.validator][claim.index],"aready claimed");
            processedClaim[claim.cycle][claim.validator][claim.index] = true;
            if (block.chainid != 31337) {
                require(network.getCurrentCycle() - claim.cycle  > 1,"Cannot claim current or future cycles");
            }
            //1. loop through validators and hash the first 6 bytes of the subnetId and the amount with the previous hash
            // address[] memory validSigners;
            //2. keccak256 hash the concatenation of the dataHash, the cycle and the validators public key
            //3. Verify the signature using the new hash as the message
            
            (bool valid, bytes32 hash) = verifyClaim(claim);
            require(valid, "invalid signature");
            claimHash = hash;
            licenceCount = sentryContract.getCycleActiveLicenseCount(
                claim.cycle
            );

            //3. loop through signers starting from the last
            // uint hash = uint(claimHash);
            // uint salt = (uint(claimHash) % 1000) + 1;
            //  uint startLicence = ((hash/salt) % licenceCount) + 1000;

        }
        {
            uint validCount;
            uint signerIndex = 0;
            uint minSigners = getMinSignerCount(licenceCount);
            xTokenContract.operatorMint(
                sentryContract.operatorsOwner(claim.validator),
                validatorBaseReward + (claim.totalCost / 2)
            );
           
            for (uint i = 0; i < 30; i++) {
                uint decodedLicence = (MLUtils.lcg(
                    ((((uint(claimHash) / ((uint(claimHash) % 1000))) %
                        licenceCount) + 1000) +
                        (i * ((uint(claimHash) % 1000) + 1)))) % (licenceCount)
                ) + 1000;
                
                bytes memory signer = LibSecp256k1Extended.pubKeyFromPoints(
                    claim.signers[signerIndex]
                );
                bytes memory owner = sentryContract.licenseOperator(
                    decodedLicence
                );
                console.log("DecodedSigner", minSigners, licenceCount);
                if (uint(bytes32(signer)) == uint(bytes32(owner))) {
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
        sentryContract.fillLicenseCountGap();
        superNodeContract.fillLicenseCountGap();
        //6. Reward the operators that provided the proof
    }
}
