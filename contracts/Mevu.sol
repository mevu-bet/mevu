pragma solidity ^0.4.18; 

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../ethereum-api/usingOraclize.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./Rewards.sol";
import "./Oracles.sol";

import "./MvuToken.sol";


contract Mevu is Ownable, usingOraclize {

    address mevuWallet;
    Events events;
    Admin admin;
    Wagers wagers;
    Oracles oracles;
    Rewards rewards;
   
    MvuToken mvuToken;
    bool  contractPaused = false;
    bool  randomNumRequired = false;
    bool settlementPeriod = false;
    uint lastIteratedIndex = 0;  
    uint  mevuBalance = 0;
    uint  lotteryBalance = 0;    
    uint oraclizeGasLimit = 500000;
    uint oracleServiceFee = 3; //Percent
    //  TODO: Set equal to launch date + one month in unix epoch seocnds
    uint  newMonth = 1515866437;
    uint  monthSeconds = 2592000;
    uint public playerFunds;  
       
    mapping (bytes32 => bool) validIds;
    mapping (address => bool) abandoned;
    mapping (address => bool) private isAuthorized;
    //bytes32[] oracleQueue;  
    


    event newOraclizeQuery (string description);  

    modifier notPaused() {
        require (!contractPaused);
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }   

    modifier onlyPaused() {
        require (contractPaused);
        _;
    }

     modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
                _;
    }

   

      
    
    // modifier onlyOracle (bytes32 oracleId) {
    //     bool oracle = false;
    //     for (uint i = 0; i < oracles.getOracleLength(msg.sender); i++) {
    //         if (oracles.getOracleAt(msg.sender, i) == oracleId) {
    //             oracle = true;
    //         }
    //     }
    //     if (oracle) {
    //         _;
    //     }
    // }
    
    
    modifier eventUnlocked(bytes32 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier wagerUnlocked (bytes32 wagerId) {
        require (!wagers.getLocked(wagerId));
        _;
    }
      
    
    modifier mustBeVoteReady(bytes32 eventId) {
        require (events.getVoteReady(eventId));
        _;           
    }  
  

    modifier mustBeTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) != address(0));
        _;
    }

    modifier notSettled(bytes32 wagerId) {
        require (!wagers.getSettled(wagerId));
        _;           
    }

    function () payable {
        if (msg.sender != address(wagers)) {
            mevuBalance += msg.value;
        }
    }

    // Constructor 
    function Mevu () payable { 
        //OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);               
        mevuWallet = msg.sender;        
        //bytes32 queryId = oraclize_query(100, "URL", "", oraclizeGasLimit);
        //validIds[queryId] = true;          
  
    }

    function grantAuthority (address nowAuthorized) onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) onlyOwner {
        isAuthorized[unauthorized] = false;
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

   

  
    function __callback (bytes32 myid, string result) notPaused {        
         require(validIds[myid]);
         require(msg.sender == oraclize_cbAddress());      
       
        if (randomNumRequired) {        
             uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
             uint randomNumber = uint(keccak256(result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
             randomNumRequired = false;   
             address potentialWinner = oracles.getOracleListAt(randomNumber);
             payoutLottery(potentialWinner);
        } else {            

            events.determineEventStage(events.getActiveEventId(lastIteratedIndex), lastIteratedIndex);
            lastIteratedIndex ++;       
            bytes32 queryId;   
            
            if (lastIteratedIndex == events.getActiveEventsLength()) {               
                lastIteratedIndex = 0;
                checkLottery();
                newOraclizeQuery("Last active event processed, callback being set for admin interval.");
                queryId =  oraclize_query(admin.getCallbackInterval(), "URL", "");
                validIds[queryId] = true; 
            } else {
                queryId = oraclize_query("URL", "");
                validIds[queryId] = true;        
            }
            
        }       

    }    

    function setMevuWallet (address newAddress) onlyOwner {
        mevuWallet = newAddress;       
    }    

    // /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
    //   * @param name The name of the event to be diplayed.
    //   * @param startTime The date and time the event begins in unix epoch.
    //   * @param duration The length of the event in seconds.
    //   * @param eventType The sport or event category, eg. Hockey, MMA, Politics etc...
    //   * @param teamOne The name of one of the participants, eg. Toronto Maple Leafs, Georges St-Pierre, Justin Trudeau.
    //   * @param teamTwo The name of teamOne's opposition.     
    //   */
    // function makeStandardEvent(
    //     bytes32 name,
    //     uint256 startTime,
    //     uint256 duration,
    //     bytes32 eventType,
    //     bytes32 teamOne,
    //     bytes32 teamTwo
    // )
    //     onlyOwner            
    //     returns (bytes32) 
    // {
    //     bytes32 id = keccak256(name); 
    //     events.makeStandardEvent(   id,                                        
    //                                 name,
    //                                 startTime,
    //                                 duration,
    //                                 eventType,
    //                                 teamOne,
    //                                 teamTwo);
    //     return id;                      
    // }

    // function updateStandardEvent(
    //     bytes32 eventId,
    //     uint256 newStartTime,
    //     uint256 newDuration,
    //     bytes32 newTeamOne,
    //     bytes32 newTeamTwo
    // ) 
    //     external 
    //     onlyOwner 
    // {
    //     events.updateStandardEvent(eventId, newStartTime, newDuration, newTeamOne, newTeamTwo);             
    // }
   

    // function cancelStandardEvent (bytes32 eventId) onlyOwner {
    //     events.cancelStandardEvent(eventId);       
    // }

   
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
    
    //  function updateWager (
    //     bytes32 wagerId,
    //     uint eventId, 
    //     uint odds, 
    //     uint256 value,
    //     uint makerChoice) 
    //     onlyMaker(wagerId) 
    //     notPaused
    //     notTaken(wagerId)
    //     wagerUnlocked(wagerId)
    //     eventUnlocked(eventId)
    //     checkBalance(value)
    //     payable {
    //         bool newEvent = false;
           
    //         StandardWager thisWager = standardWagers[wagerId];
    //         if (thisWager.eventId != eventId) {
    //             newEvent = true;
    //         }
    //         Rewards(rewardsContract).addUnlockedEth(msg.sender, thisWager.value);
    //         Rewards(rewardsContract).subUnlockedEth(msg.sender, value);
    //         Rewards(rewardsContract).addEth(msg.sender, msg.value); 
    //         thisWager.eventId = eventId;
    //         thisWager.odds = odds;
    //         thisWager.value = value;
    //         thisWager.makerChoice = makerChoice;
    //         standardWagers[wagerId] = thisWager;
    //         if  (newEvent) {
    //             standardEvents[eventId].wagers.push(wagerId);
    //         }
    // }
    

    function withdraw(
        uint eth,
        uint mvu
    )
        notPaused   
        external         
    { 
        require (rewards.getUnlockedEthBalance(msg.sender) >= eth);
        rewards.subUnlockedEth(msg.sender, eth);
        rewards.subEth(msg.sender, eth);
        playerFunds -= eth;
        msg.sender.transfer(eth);        
        require (rewards.getUnlockedMvuBalance(msg.sender) >= mvu);
        rewards.subUnlockedMvu(msg.sender, mvu);
        rewards.subMvu(msg.sender, mvu);
        mvuToken.transfer (msg.sender, mvu);
         
    }     

    
    /** @dev Enters the makers vote for who actually won after the event is over.               
      * @param wagerId bytes32 id for the wager.
      * @param winnerVote number representing who the creator thinks won the match         
      */
    function submitVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyBettor(wagerId) 
        mustBeVoteReady(wagers.getEventId(wagerId))
        notPaused 
    {
        bytes32 eventId = wagers.getEventId(wagerId);
        if (msg.sender == wagers.getMaker(wagerId)){        
            wagers.setMakerWinVote (wagerId, winnerVote);
        } else {
            wagers.setTakerWinVote (wagerId, winnerVote);
        }
        uint eventWinner = events.getWinner(eventId);        
        if (eventWinner != 0 && eventWinner != 3) {
            lateSettle(wagerId, eventWinner);
            lateSettledPayout(wagerId);    
        } else {
            if (events.getCancelled(eventId) || events.getWinner(eventId) == 3) {
                abortWager(wagerId);                
            } else {
                if (wagers.getTakerWinVote(wagerId) != 0 && wagers.getMakerWinVote(wagerId) != 0) {
                    settle(wagerId);
                  
                }
            }       
        }       
    }

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
     *  been cancelled, refunds all eth.               
     *  @param wagerId bytes32 wagerId of the wager to abort.  
     */ 
    function abortWager(bytes32 wagerId) internal {        
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }             
    }

    /** @dev Settles the wager if both the maker and taker have voted, pays out if they agree, otherwise they need to wait for oracle settlement.               
      * @param wagerId bytes32 id for the wager.         
      */
    function settle(bytes32 wagerId) internal {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getMaker(wagerId);
        uint origValue = wagers.getOrigValue(wagerId);
        if (wagers.getMakerWinVote(wagerId) == wagers.getTakerWinVote(wagerId)) {
            if (wagers.getMakerWinVote(wagerId) == wagers.getMakerChoice(wagerId)) {
                wagers.setWinner(wagerId, maker);
                rewards.addEth(maker, wagers.getWinningValue(wagerId) - origValue);
                rewards.subEth(taker, wagers.getWinningValue(wagerId) - origValue);
            } else {
                if (wagers.getMakerWinVote(wagerId) == 3) {
                    wagers.setWinner(wagerId, address(0));                    
                } else {
                    wagers.setWinner(wagerId, taker);
                    rewards.addEth(maker, origValue);
                    rewards.subEth(taker, origValue);
                }
            }
            payout(wagerId, maker, taker);
        }
        // } else {
        //     addToOracleQueue(wagerId);
        // }      
    }

    /** @dev Pays out the wager if both the maker and taker have agreed, otherwise they need to wait for oracle settlement.               
       * @param wagerId bytes32 id for the wager.         
       */
     function payout(bytes32 wagerId, address maker, address taker) internal {  
         if (!wagers.getSettled(wagerId)) {
            wagers.setSettled(wagerId);           
            uint origVal =  wagers.getOrigValue(wagerId);
            uint winVal = wagers.getWinningValue(wagerId);
             if (wagers.getWinner(wagerId) == address(0)) { //Tie
                maker.transfer(origVal);
                taker.transfer(winVal-origVal);               
               // transferEthFromMevu(maker, wagers.getOrigValue(wagerId));
                //transferEthFromMevu(taker, wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId));     
             } else {
                uint payoutValue = wagers.getWinningValue(wagerId); 
                uint fee = (payoutValue/100) * 2; // Sevice fee is 2 percent
                //addMevuBalance(3*(fee/4));
                mevuBalance += (3*(fee/4));
                rewards.subEth(wagers.getWinner(wagerId), payoutValue);
                payoutValue -= fee;
                //addLotteryBalance(fee/8);
                lotteryBalance += (fee/8);
                //uint oracleFee = fee/8;                         
                transferEthFromMevu(wagers.getWinner(wagerId), payoutValue);  
                events.addResolvedWager(wagers.getEventId(wagerId), winVal);              
            }                             
            rewards.addPlayerRep(maker, 25);
            rewards.addPlayerRep(taker, 25);
            wagers.setLocked(wagerId);
        }       
    }

    function lateSettle (bytes32 wagerId, uint eventWinner) internal {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        if (wagers.getMakerChoice(wagerId) == eventWinner) {
            wagers.setWinner(wagerId, maker);
            wagers.setLoser(wagerId, taker);               
        } else {     
            wagers.setWinner(wagerId, taker);
            wagers.setLoser(wagerId, maker);       
        }             
    }
    
  /** @dev Pays out the wager after oracle settlement.               
    * @param wagerId bytes32 id for the wager.         
    */
    function lateSettledPayout(bytes32 wagerId) internal {
        
        if (!wagers.getSettled(wagerId)) {
            wagers.setSettled(wagerId);
            wagers.setLocked(wagerId);   
            uint origValue = wagers.getOrigValue(wagerId);
            uint winningValue = wagers.getWinningValue(wagerId);           
            uint payoutValue = winningValue;
            uint fee = (payoutValue/100) * oracleServiceFee;
            addMevuBalance(fee/2);            
            addLotteryBalance(fee/12);
            payoutValue -= fee;           
            uint oracleFee = (fee/12) + (fee/3);
            addLotteryBalance(oracleFee); // Too late to reward oracles directly for this wager, fee added to oracle lottery
            address maker = wagers.getMaker(wagerId);
            address taker = wagers.getTaker(wagerId);                    
            if (wagers.getWinner(wagerId) == maker) { // Maker won
                rewards.addUnlockedEth(maker, payoutValue);
                rewards.addEth(maker, (winningValue - origValue));
                rewards.addPlayerRep(maker, 25);
                rewards.subPlayerRep(taker, 50);
            } else { //Taker won
                rewards.addUnlockedEth(taker, payoutValue);
                rewards.addEth(taker, origValue);
                rewards.addPlayerRep(taker, 25);
                rewards.subPlayerRep(maker, 50);
            }           
        }
    }

 

    // PLayers should call this when an event has been cancelled after thay have made a wager
    function playerRefund (bytes32 wagerId) external onlyBettor(wagerId) {
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


    /** @dev Calls the oraclize contract for a random number generated through the Wolfram Alpha engine
      * @param max uint which corresponds to entries in oracleList array.
      */ 
    function randomNum(uint max) private {
        randomNumRequired = true;
        string memory qString = strConcat("random number between 0 and ", bytes32ToString(uintToBytes(max)));        
        bytes32 queryId = oraclize_query('Wolfram Alpha', qString);
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
    function payoutLottery(address potentialWinner) private { 
        // TODO: add functionality to test for oracle service being provided within one mointh of block.timestamp   
        if (mvuToken.balanceOf(potentialWinner) > 0) {            
            uint thisWin = lotteryBalance;
            lotteryBalance = 0;
            potentialWinner.transfer(thisWin);
        } else {
            require(oracles.getOracleListLength() >= admin.getMinOracleNum());
            callRandomNum(oracles.getOracleListLength()-1);
            
        }
        assert(this.balance - mevuBalance > playerFunds);
        mevuWallet.transfer(mevuBalance);
        mevuBalance = 0;
    }   
    
    function pauseContract() 
        public
        onlyOwner {
        contractPaused = true;    
    }

    function restartContract(uint secondsFromNow) 
        external 
        onlyOwner
        payable
    {            
        contractPaused = false;
        bytes32 queryId = oraclize_query(secondsFromNow, "URL", "");
        validIds[queryId] = true;  
          
    }     

   

    // function addToOracleQueue (bytes32 wager) {
    //     oracleQueue.push(wager);
    // }  

    // function getOracleQueueAt(uint index) view returns (bytes32) {
    //     return oracleQueue[index];
    // }
    
    // function getOracleQueueLength() view returns (uint) {
    //     return oracleQueue.length;
    // }    

    // function deleteOracleQueue() {
    //     delete oracleQueue;
    // }    

    function addMevuBalance (uint amount) onlyAuth {
        mevuBalance += amount;
    }

    function addLotteryBalance (uint amount) onlyAuth {
        lotteryBalance += amount;
    } 

    function addToPlayerFunds (uint amount) onlyAuth {
        playerFunds += amount;
    }

    function subFromPlayerFunds (uint amount) onlyAuth {
        playerFunds -= amount;
    }   

    function getContractPaused() constant returns (bool) {
        return contractPaused;
    }     

    function getOracleFee () constant returns (uint256) {
        return oracleServiceFee;
    }

    function transferTokensToMevu (address oracle, uint mvuStake) internal {
        mvuToken.transferFrom(oracle, this, mvuStake);       
    }

    function transferTokensFromMevu (address oracle, uint mvuStake) internal {
        mvuToken.transfer(oracle, mvuStake);       
    }

    function transferEthFromMevu (address recipient, uint amount) internal {
        recipient.transfer(amount);
    }   
  
    function addMonth () internal {
        newMonth += monthSeconds;
    }  
   
    function getNewMonth () constant returns (uint256) {
        return newMonth;
    }

    function makeOraclizeQuery (string engine, string query) internal {
        bytes32 queryId =  oraclize_query (engine, query, admin.getCallbackGasLimit());
        validIds[queryId] = true;          
       
    }

    function uintToBytes(uint v) view returns (bytes32 ret) {
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

    function bytes32ToString (bytes32 data) view returns (string) {
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







