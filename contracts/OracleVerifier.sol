pragma solidity ^0.4.18;
import "./AuthorityGranter.sol";

/** @title Oracle Verifier -- This contract controls the adding to and removal from the list of verified oracles.
  * 
  */
contract OracleVerifier is AuthorityGranter {

    address mevuAccount;
    mapping (address => bytes32) phoneHashAtAddress;
    mapping (bytes32 => address) addressAtPhonehash;
    mapping (address => bool) public verified;
    mapping (address => uint) public timesRemoved;
    bytes32 empty;

    function OracleVerifier() {
        mevuAccount = msg.sender;
    }
    
    /** @dev Registers an address as a verified Oracle so the user may register to report event outcomes.
      * @param newOracle - address of the new oracle.
      * @param phoneNumber - ten digit phone number belonging to Oracle which has already been verified.
      */
    function addVerifiedOracle(address newOracle, uint phoneNumber) onlyAuth {
        bytes32 phoneHash = keccak256(phoneNumber);
        if (verified[newOracle]) {
            revert();
        } else {
            if (addressAtPhonehash[phoneHash] == address(0)
            && phoneHashAtAddress[newOracle] == empty) {
                verified[newOracle] = true;
                addressAtPhonehash[phoneHash] = newOracle;
                phoneHashAtAddress[newOracle] = phoneHash;
            }
        }       
    }
    
    /** @dev Removes an address as a verified Oracle so the user may no longer register to report event outcomes.
      * @param oracle - address of the oracle to be removed.
      */
    function removeVerifiedOracle (address oracle) onlyAuth {
        verified[oracle] = false;
        timesRemoved[oracle] += 1;
    }
    
    function checkVerification (address oracle) external view returns (bool) {
      return verified[oracle];        
    }
    
}