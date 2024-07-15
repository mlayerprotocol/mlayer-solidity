// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "hardhat/console.sol";
import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1} from "./libs/schnorr/LibSecp256k1.sol";

import {LibSchnorrExtended} from "./libs/schnorr/LibSchnorrExtended.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";


contract LibSchnorrTest  {
    using LibSecp256k1 for LibSecp256k1.Point;
    using LibSecp256k1Extended for uint;
    using LibSchnorrExtended for uint;
    using LibSchnorrExtended for uint[];
    using LibSchnorrExtended for LibSecp256k1.Point;
    using LibSchnorrExtended for LibSecp256k1.Point[];

    uint256 private constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    

    function _bound(uint256 x, uint256 min, uint256 max) internal pure virtual returns (uint256 result) {
        require(min <= max, "StdUtils bound(uint256,uint256,uint256): Max is less than min.");
        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        // If the value is 0, 1, 2, 3, wrap that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x) return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
    }

    function assertTrue(bool b) view internal {
        if (!b) {
            console.log("Should be true but returned false");
        }
    }

 function assertFalse(bool b) view internal {
        if (b) {
            console.log("Should be false but returned true");
        } 
    }

     function assertEq(bool a, bool b) internal virtual {
        if (a != b) {
            console.log("Error: a == b not satisfied [bool]");
        }
    }



    // function testFuzz_verifySignature_SingleSigner(
    //     uint privKeySeed,
    //     bytes32 message
    // ) public view returns (bool) {
    //     // Let privKey ∊ [1, Q).
    //     uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);
    //     // Compute pubKey.
    //     LibSecp256k1.Point memory pubKey = privKey.derivePublicKey();

    //     // Sign message.
    //     uint signature;
    //     address commitment;
    //     (signature, commitment) = privKey.signMessage(message);

    //     // Signature is _not_ verifiable if one of the following cases hold:
    //     // - commitment == address(0)
    //     // - pubKey.x == 0
    //     // - signature == 0
    //     // - signature >= Q
    //     bool shouldBeOk = true;
    //     if (commitment == address(0)) shouldBeOk = false;
    //     if (pubKey.x == 0) shouldBeOk = false;
    //     if (signature == 0) shouldBeOk = false;
    //     if (signature >= LibSecp256k1.Q()) shouldBeOk = false;

    //     // Signature verification should equal expected value.
    //     bool ok = LibSchnorr.verifySignature(
    //         privKey.derivePublicKey(), message, bytes32(signature), commitment
    //     );
    //      console.log("ISOKAY", ok);
    //     // assertEq(ok, shouldBeOk);
    //     return ok;
    // }

    function testFuzz_verifySignature_MultipleSigners(
        uint[] memory privKeys,
        bytes32 message
    ) public view returns(bool) {
        // Vm.assume(privKeySeeds.length > 1);
        // Keep low to not run out-of-gas.
       // Vm.assume(privKeySeeds.length < 50);

        // Let each privKey ∊ [2, Q).
        // Note that we allow double signing.
        // uint[] memory privKeys = new uint[](privKeySeeds.length);
        // for (uint i; i < privKeySeeds.length; i++) {
        //     privKeys[i] = _bound(privKeySeeds[i], 2, LibSecp256k1.Q() - 1);
        //      console.log("PRIVATEKEY", i, privKeys[i]);
        // }
       

        // Make list of public key.
        LibSecp256k1.Point[] memory pubKeys =
            new LibSecp256k1.Point[](privKeys.length);
        for (uint i; i < privKeys.length; i++) {
            pubKeys[i] = privKeys[i].derivePublicKey();
             console.log("pubkeys", pubKeys[i].x, pubKeys[i].y);
        }

       

        // Compute aggregated public key.
        LibSecp256k1.Point memory aggPubKey = pubKeys.aggregatePublicKeys();
        console.log("AggregatePubKey", aggPubKey.x, aggPubKey.y);
        
        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKeys.signMessage(message);
      
        // Signature is _not_ verifiable if one of the following cases hold:
        // - commitment == address(0)
        // - pubKey.x == 0
        // - signature == 0
        // - signature >= Q
        bool shouldBeOk = true;
        if (commitment == address(0)) shouldBeOk = false;
        if (aggPubKey.x == 0) shouldBeOk = false;
        if (signature == 0) shouldBeOk = false;
        if (signature >= LibSecp256k1.Q()) shouldBeOk = false;

        // // Signature verification should equal expected value.
        bool ok = LibSchnorr.verifySignature(
            pubKeys.aggregatePublicKeys(),
            message,
            bytes32(signature),
            commitment
        );
       //  assertEq(ok, shouldBeOk);
       // return ok;
    }
    // function testFuzz_verifySignature_MultipleSigners2(
    //     uint256[] memory privKeys,
    //     bytes32 message
    // ) public view returns(bool) {
    //     // Vm.assume(privKeySeeds.length > 1);
    //     // Keep low to not run out-of-gas.
    //    // Vm.assume(privKeySeeds.length < 50);

    //     // Let each privKey ∊ [2, Q).
    //     // Note that we allow double signing.
        
       

    //     // Make list of public key.
    //     LibSecp256k1.Point[] memory pubKeys =
    //         new LibSecp256k1.Point[](privKeys.length);
    //     for (uint i; i < privKeys.length; i++) {
    //         pubKeys[i] = privKeys[i].derivePublicKey();
    //     }

    //     // Compute aggregated public key.
    //     LibSecp256k1.Point memory aggPubKey = pubKeys.aggregatePublicKeys();

    //     // Sign message.
    //     uint signature;
    //     address commitment;
    //     (signature, commitment) = privKeys.signMessage(message);

    //     // Signature is _not_ verifiable if one of the following cases hold:
    //     // - commitment == address(0)
    //     // - pubKey.x == 0
    //     // - signature == 0
    //     // - signature >= Q
    //     bool shouldBeOk = true;
    //     if (commitment == address(0)) shouldBeOk = false;
    //     if (aggPubKey.x == 0) shouldBeOk = false;
    //     if (signature == 0) shouldBeOk = false;
    //     if (signature >= LibSecp256k1.Q()) shouldBeOk = false;

    //     // Signature verification should equal expected value.
    //     bool ok = LibSchnorr.verifySignature(
    //         pubKeys.aggregatePublicKeys(),
    //         message,
    //         bytes32(signature),
    //         commitment
    //     );
    //    //  assertEq(ok, shouldBeOk);
    //     return ok;
    // }

    function testFuzz_verifySignature_FailsIf_SignatureMutated(
        uint privKeySeed,
        bytes32 message,
        uint signatureMask
    ) public {
        // Vm.assume(signatureMask != 0);

        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Mutate signature.
        signature ^= signatureMask;

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            privKey.derivePublicKey(), message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }

    function testFuzz_verifySignature_FailsIf_CommitmentMutated(
        uint privKeySeed,
        bytes32 message,
        uint160 commitmentMask
    ) public {
       // Vm.assume(commitmentMask != 0);

        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Mutate commitment.
        commitment = address(uint160(commitment) ^ commitmentMask);

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            privKey.derivePublicKey(), message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }

    function testFuzz_verifySignature_FailsIf_MessageMutated(
        uint privKeySeed,
        bytes32 message,
        uint messageMask
    ) public {
       //  Vm.assume(messageMask != 0);

        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Mutate message.
        message = bytes32(uint(message) ^ messageMask);

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            privKey.derivePublicKey(), message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }

    function testFuzz_verifySignature_FailsIf_PubKeyNotOnCurve(
        uint privKeySeed,
        bytes32 message,
        uint pubKeyXMask,
        bool flipParity
    ) public {
       // Vm.assume(pubKeyXMask != 0 || flipParity);

        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Compute and mutate pubKey.
        LibSecp256k1.Point memory pubKey = privKey.derivePublicKey();
        pubKey.x ^= pubKeyXMask;
        pubKey.y = flipParity ? pubKey.y + 1 : pubKey.y;

       //  Vm.assume(!pubKey.isOnCurve());

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            pubKey, message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }

    function testFuzz_verifySignature_FailsIf_SignatureIsZero(
        uint privKeySeed,
        bytes32 message
    ) public {
        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Let signature be zero.
        signature = 0;

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            privKey.derivePublicKey(), message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }

    function testFuzz_verifySignature_FailsIf_CommitmentIsZero(
        uint privKeySeed,
        bytes32 message
    ) public {
        // Let privKey ∊ [1, Q).
        uint privKey = _bound(privKeySeed, 1, LibSecp256k1.Q() - 1);

        // Sign message.
        uint signature;
        address commitment;
        (signature, commitment) = privKey.signMessage(message);

        // Let commitment be zero.
        commitment = address(0);

        // Signature verification should not succeed.
        bool ok = LibSchnorr.verifySignature(
            privKey.derivePublicKey(), message, bytes32(signature), commitment
        );
        assertFalse(ok);
    }
}