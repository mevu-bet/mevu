pragma solidity ^0.4.18;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";

contract Rewards is AuthorityGranter {   
    mapping(address => int) private playerRep;
    mapping (address => int) private oracleRep;  
    mapping (address => uint) private ethBalance;
    mapping (address => uint) private mvuBalance;
    mapping(address => uint) private unlockedEthBalance;
    mapping (address => uint) private unlockedMvuBalance;
  
  
    function subEth(address user, uint amount) external onlyAuth {
        ethBalance[user] -= amount;
    }

    function subMvu(address user, uint amount) external onlyAuth {
        mvuBalance[user] -= amount;
    }

    function addEth(address user, uint amount) external onlyAuth {
        ethBalance[user] += amount;
    }

    function addMvu(address user, uint amount) external onlyAuth {
        mvuBalance[user] += amount;
    }  

    function subUnlockedMvu(address user, uint amount) external onlyAuth {
        unlockedMvuBalance[user] -= amount;
    }

    function subUnlockedEth(address user, uint amount) external onlyAuth {
        unlockedEthBalance[user] -= amount;
    }

    function addUnlockedMvu(address user, uint amount) external onlyAuth {
        unlockedMvuBalance[user] += amount;
    }

    function addUnlockedEth(address user, uint amount) external onlyAuth {
        unlockedEthBalance[user] += amount;
    }
    
    function subOracleRep(address oracle, int value) external onlyAuth {
        oracleRep[oracle] -= value;
    }

    function subPlayerRep(address player, int value) external onlyAuth {
        playerRep[player] -= value;
    }

    function addOracleRep(address oracle, int value) external onlyAuth {
        oracleRep[oracle] += value;
    }

    function addPlayerRep(address player, int value) external onlyAuth {
        playerRep[player] += value;
    }
      
    function getEthBalance(address user) external view returns (uint) {
        return ethBalance[user];
    }

    function getMvuBalance(address user) external view returns (uint) {
        return mvuBalance[user];
    }

    function getUnlockedEthBalance(address user) external view returns (uint) {
        return unlockedEthBalance[user];
    }

    function getUnlockedMvuBalance(address user) external view returns (uint) {
        return unlockedMvuBalance[user];
    }

    function getOracleRep (address oracle) external view returns (int) {
        return oracleRep[oracle];
    } 

    function getPlayerRep (address player) external view returns (int) {
        return playerRep[player];
    } 
} 