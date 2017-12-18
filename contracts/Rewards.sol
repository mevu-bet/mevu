pragma solidity 0.4.18;

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol";
import "./Wagers.sol";

import "./Oracles.sol";
contract Rewards is Ownable {  
    Admin admin;
    Wagers wagers;
    Oracles oracles;
    mapping(address => uint) public playerRep;
    mapping (address => uint) public oracleRep;  
    mapping (address => uint) public ethBalance;
    mapping (address => uint) public mvuBalance;
    mapping(address => uint) public unlockedEthBalance;
    mapping (address => uint) public unlockedMvuBalance;


    modifier onlyAuth () {
        require(msg.sender == address(admin) ||
                msg.sender == address(this.owner)||
                msg.sender == address(oracles) ||
                msg.sender == address(wagers));
                _;
    }

    function setOraclesContract (address thisAddr) external onlyOwner {
        oracles = Oracles(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);        
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
    
    function subOracleRep(address oracle, uint value) external onlyAuth {
        oracleRep[oracle] -= value;
    }

    function subPlayerRep(address player, uint value) external onlyAuth {
        playerRep[player] -= value;
    }

    function addOracleRep(address oracle, uint value) external onlyAuth {
        oracleRep[oracle] += value;
    }

    function addPlayerRep(address player, uint value) external onlyAuth {
        playerRep[player] += value;
    }
} 