pragma solidity 0.4.18;

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Oracles is Ownable {


    struct OracleStruct {
        bytes32 oracleId;
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }

    mapping(address => bytes32[])  oracles;
    mapping(bytes32 => OracleStruct) oracleStructs;   
    address[]  oracleList; // List of people who have ever registered as an oracle

    function removeOracle (address oracle, uint256 eventId, bytes32 oracleId) onlyOwner {
        OracleStruct memory thisOracle;         
        thisOracle = OracleStruct (0,0,0,0, false);               
        oracleStructs[oracleId] = thisOracle;    
    }

    function createOracle (
        bytes32 eventId,
        uint mvuStake,
        bytes32 oracleId,
        uint winnerVote,
        bool paid
    ) 
        onlyOwner 
    {
        OracleStruct memory thisOracle; 
        thisOracle = OracleStruct (oracleId, eventId, mvuStake, winnerVote, paid);
        oracles[msg.sender].push(oracleId);
        oracleStructs[oracleId] = thisOracle;
        
    }
  

    
    function setOraclePaid (bytes32 id) onlyOwner {
        oracleStructs[id].paid = true;
    } 

    function getWinnerVote(bytes32 id) external view returns (uint) {
        return oracleStructs[id].winnerVote;
    }

    function getPaid (bytes32 id) external view returns (bool) {
        return oracleStructs[id].paid;
    }

    function getEventId(bytes32 oracleId) external view returns (bytes32) {
        return oracleStructs[oracleId].eventId;
    }

    function getMvuStake (bytes32 id) external view returns (uint) {
        return oracleStructs[id].mvuStake;
    }

    function getOracle(address oracle) external view returns (bytes32[]) {
        return oracles[oracle];
    }
    
    function getOracleAt (address oracle, uint index) external view returns (bytes32) {
        return oracles[oracle][index];
    }   
     
    function getOracleLength(address oracle) external view returns (uint) {
        return oracles[oracle].length;
    }

    function getOracleListLength() external view returns (uint) {
        return oracleList.length;
    }
  

}