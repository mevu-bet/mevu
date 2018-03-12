

pragma solidity ^0.4.18; 
import "./AuthorityGranter.sol";
import "../ethereum-api/usingOraclize.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./Rewards.sol";
import "./Oracles.sol";
import "./MvuToken.sol";

contract Mevu is AuthorityGranter, usingOraclize {

    address private mevuWallet;
    Events private events;
    Admin private admin;
    Oracles private oracles;
    Rewards private rewards;   
    MvuToken private mvuToken;
    Wagers private wagers;
    
    bool public contractPaused = false;
    bool private randomNumRequired = false;  
    int private lastIteratedIndex = -1;  
    uint private mevuBalance = 0;
    uint public lotteryBalance = 0;    
   
    uint private oracleServiceFee = 3; //Percent
    
    uint public newMonth;
    uint private monthSeconds = 2592000;
    uint public playerFunds;  
       
    mapping (bytes32 => bool) private validIds;
    mapping (address => bool) private abandoned;
   
    
    event NewOraclizeQuery (string description);  

    modifier notPaused() {
        require (!contractPaused);
        _;
    }    

    modifier onlyPaused() {
        require (contractPaused);
        _;
    }

     modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }


 
    // Constructor 
    function Mevu () payable { 
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);                
        mevuWallet = msg.sender;
        newMonth = block.timestamp + monthSeconds;       
    }

    function () payable {        
                
    }  

    function setEventsContract (address thisAddr) external onlyOwner {
        events = Events(thisAddr);        
    }

    function setOraclesContract (address thisAddr) external onlyOwner {
        oracles = Oracles(thisAddr);
    }

    function setRewardsContract   (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);
    }
 
    function setMvuTokenContract (address thisAddr) external onlyOwner {
        mvuToken = MvuToken(thisAddr);
    } 
  
    function __callback (bytes32 myid, string result)  notPaused {        
         require(validIds[myid]);
         require(msg.sender == oraclize_cbAddress());      
       
        if (randomNumRequired) {        
             uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
             uint randomNumber = uint(keccak256(result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
             randomNumRequired = false;   
             address potentialWinner = oracles.getOracleListAt(randomNumber);
             payoutLottery(potentialWinner);
        } else {             
            bytes32 queryId;  
            if (lastIteratedIndex == -1) {               
               //events.determineEventStage(events.getActiveEventId(lastIteratedIndex), lastIteratedIndex);
                lastIteratedIndex = int(events.getActiveEventsLength()-1);
                
                //checkLottery();
                NewOraclizeQuery("Last active event processed, callback being set for admin interval.");
                queryId =  oraclize_query(admin.getCallbackInterval(), "URL", "", admin.getCallbackGasLimit());
                validIds[queryId] = true; 
            } else {
                events.determineEventStage(events.getActiveEventId(uint(lastIteratedIndex)), uint(lastIteratedIndex));               
               
                lastIteratedIndex --;
                NewOraclizeQuery("Not done yet, querying right away again."); 
                queryId = oraclize_query("URL", "", admin.getCallbackGasLimit());
                validIds[queryId] = true;        
            }            
        } 
    }    

    function setMevuWallet (address newAddress) external onlyOwner {
        mevuWallet = newAddress;       
    }   
   
    function abandonContract() external onlyPaused {
        require(!abandoned[msg.sender]);
        abandoned[msg.sender] = true;
        uint ethBalance =  rewards.getEthBalance(msg.sender);
        uint mvuBalance = rewards.getMvuBalance(msg.sender);
        playerFunds -= ethBalance;
        if (ethBalance > 0) {
            msg.sender.transfer(ethBalance);           
        }
        if (mvuBalance > 0) {
            mvuToken.transfer(msg.sender, mvuBalance);
        }
    } 


    /** @dev Calls the oraclize contract for a random number generated through the Wolfram Alpha engine
      * @param max uint which corresponds to entries in oracleList array.
      */ 
    function randomNum(uint max) private {
        randomNumRequired = true;
        string memory qString = strConcat("random number between 0 and ", bytes32ToString(uintToBytes(max)));        
        bytes32 queryId = oraclize_query("Wolfram Alpha", qString);
        validIds[queryId] = true;
    }       
    
    function callRandomNum (uint max) internal {
        randomNum(max);
    }

    /** @dev Checks to see if a month (in seconds) has passed since the last lottery paid out, pays out if so    
      */ 
    function checkLottery() internal {       
        if (block.timestamp > getNewMonth()) {
            addMonth();
            randomNum(oracles.getOracleListLength()-1);
        }
    }

    /** @dev Pays out the monthly lottery balance to a random oracle and sends the mevuWallet its accrued balance.   
      */ 
    function payoutLottery(address potentialWinner) internal { 
        // TODO: add functionality to test for oracle service being provided within one mointh of block.timestamp   
        
        if (allowedToWin(potentialWinner)) {           
            uint thisWin = lotteryBalance;
            lotteryBalance = 0;                
            potentialWinner.transfer(thisWin);
        } else {
            require(oracles.getOracleListLength() > 0);
            callRandomNum(oracles.getOracleListLength()-1);            
        }       
        
    }

    // PLayers should call this when an event has been cancelled after thay have made a wager
    function playerRefund (bytes32 wagerId) external  onlyBettor(wagerId) {
        require (events.getCancelled(wagers.getEventId(wagerId)));
        require (!wagers.getRefund(msg.sender, wagerId));
        wagers.setRefund(msg.sender, wagerId);
        address maker = wagers.getMaker(wagerId);       
        wagers.setSettled(wagerId);
        if(msg.sender == maker) {
            rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));
        } else {         
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }        
    } 

    function allowedToWin (address potentialWinner) internal view returns (bool) {
        if (mvuToken.balanceOf(potentialWinner) > 0 && 
        (block.timestamp - events.getEndTime(oracles.getLastEventOraclized(potentialWinner)) < admin.getMaxOracleInterval()))
        {
            return true;
        } else {
            return false;
        } 
    }   
    
    function pauseContract() 
        external
        onlyOwner 
    {
        contractPaused = true;    
    }

    function restartContract(uint secondsFromNow) 
        external 
        onlyOwner
        payable
    {            
        contractPaused = false;
        lastIteratedIndex = int(events.getActiveEventsLength()-1);
        NewOraclizeQuery("Starting contract!");
        bytes32 queryId = oraclize_query(secondsFromNow, "URL", "", admin.getCallbackGasLimit());
        validIds[queryId] = true;          
    }

    function mevuWithdraw (uint amount) external onlyOwner {
        require(mevuBalance >= amount);
        mevuWallet.transfer(amount);
    }  

    function addMevuBalance (uint amount) external onlyAuth {
        mevuBalance += amount;
    }

    function addEventToIterator () external onlyAuth {
        lastIteratedIndex++;
    }

    function addLotteryBalance (uint amount) external onlyAuth {
        lotteryBalance += amount;
    } 

    function addToPlayerFunds (uint amount) external onlyAuth {
        playerFunds += amount;
    }

    function subFromPlayerFunds (uint amount) external onlyAuth {
        playerFunds -= amount;
    }

    function transferEth (address recipient, uint amount) external onlyAuth {
        recipient.transfer(amount);
    }       

    function getContractPaused() external view returns (bool) {
        return contractPaused;
    }     

    function getOracleFee () external view returns (uint256) {
        return oracleServiceFee;
    }

    function transferTokensToMevu (address oracle, uint mvuStake) internal {
        mvuToken.transferFrom(oracle, this, mvuStake);       
    }

    function transferTokensFromMevu (address oracle, uint mvuStake) external onlyAuth {
        mvuToken.transfer(oracle, mvuStake);       
    }
  
    function addMonth () internal {
        newMonth += monthSeconds;
    }  
   
    function getNewMonth () internal view returns (uint256) {
        return newMonth;
    }

    function makeOraclizeQuery (string engine, string query) internal {
        bytes32 queryId =  oraclize_query (engine, query, admin.getCallbackGasLimit());
        validIds[queryId] = true;          
       
    }

    function uintToBytes(uint v) internal view returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function bytes32ToString (bytes32 data) internal view returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    } 
    
} 